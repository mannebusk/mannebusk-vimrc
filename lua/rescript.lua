local M = {}

M.config = {
  open_qf_on_watch = false,
}

local watch_task = nil

local function notify(msg, level, opts)
  return vim.notify(msg, level, vim.tbl_extend('force', { title = 'ReScript' }, opts or {}))
end

--- Find the ReScript project root by looking for rescript.json
---@return string|nil
local function find_project_root()
  local buf_path = vim.api.nvim_buf_get_name(0)
  local start_dir = buf_path ~= '' and vim.fn.fnamemodify(buf_path, ':h') or vim.fn.getcwd()
  local found = vim.fs.find('rescript.json', { upward = true, path = start_dir })
  if #found > 0 then
    return vim.fn.fnamemodify(found[1], ':h')
  end
  return nil
end

--- Parse a location line like "  /path/file.res:36:77-79"
---@param line string
---@return string|nil path, number|nil lnum, number|nil col
local function parse_location(line)
  local path, lnum, col = line:match('%s*(.-%.resi?)%s*:*(%d+):(%d+)')
  if path then
    return path, tonumber(lnum), tonumber(col)
  end
  return nil, nil, nil
end

--- Parse log entries between #Start/#Done markers
---@param lines string[]
---@return string[][] entries List of entries (each is a list of lines)
local function parse_log_entries(lines)
  local entries = {}
  local mode = 'start'
  local content = {}

  for _, line in ipairs(lines) do
    if mode == 'start' then
      if line:find('#Start') then
        mode = 'collect'
        content = {}
      end
    elseif mode == 'collect' then
      if line:find('#Done') then
        mode = 'start'
        if #content > 0 then
          table.insert(entries, content)
        end
      else
        table.insert(content, line)
      end
    end
  end

  return entries
end

--- Check if a trimmed line is a header and return the header type
---@param trimmed string
---@return 'error'|'syntax'|'warning'|nil type
---@return number|nil warning_number
local function detect_header(trimmed)
  if trimmed == "We've found a bug for you!" then
    return 'error', nil
  elseif trimmed == 'Syntax error!' then
    return 'syntax', nil
  else
    local wnum = trimmed:match('^Warning number (%d+)')
    if wnum then
      return 'warning', tonumber(wnum)
    end
  end
  return nil, nil
end

--- Parse compiler output lines into quickfix items
---@param lines string[]
---@return table[] qf_items
local function parse_compiler_output(lines)
  local items = {}
  local mode = 'header'
  local blank_count = 0

  local item = { warning_number = -1, text = '', path = nil, lnum = 0, col = 0 }

  local last = #lines
  local i = 1

  while i <= last do
    local line = lines[i]

    if mode == 'header' then
      local trimmed = vim.trim(line)
      local htype, wnum = detect_header(trimmed)

      if htype == 'error' then
        mode = 'filedata'
        item = { warning_number = -1, text = '', path = nil, lnum = 0, col = 0 }
      elseif htype == 'syntax' then
        mode = 'filedata'
        item = { warning_number = -1, text = '(Syntax)', path = nil, lnum = 0, col = 0 }
      elseif htype == 'warning' then
        mode = 'filedata'
        item = { warning_number = wnum, text = '', path = nil, lnum = 0, col = 0 }
      end

    elseif mode == 'filedata' then
      local path, lnum, col = parse_location(line)
      if path then
        item.path = path
        item.lnum = lnum
        item.col = col
        mode = 'file_preview'
        blank_count = 0
      end

    elseif mode == 'file_preview' then
      if vim.trim(line) == '' then
        blank_count = blank_count + 1
      end
      if blank_count == 2 then
        mode = 'error_msg'
        blank_count = 0
      end

    elseif mode == 'error_msg' then
      -- Check if next line is a new header or we're at the last line
      local next_trimmed = i < last and vim.trim(lines[i + 1]) or ''
      local is_last = (i == last)
      local next_is_header = detect_header(next_trimmed) ~= nil

      if is_last or next_is_header then
        -- Append current line's text before finalizing
        local str = vim.trim(line)
        if str ~= '' then
          item.text = item.text == '' and str or (item.text .. ' ' .. str)
        end

        if item.path then
          local qf_type = item.warning_number > -1 and 'W' or 'E'
          local text = item.warning_number > -1
              and ('(Warning ' .. item.warning_number .. ') ' .. item.text)
              or item.text
          table.insert(items, {
            filename = item.path,
            lnum = item.lnum,
            col = item.col,
            type = qf_type,
            text = text,
          })
        end
        mode = 'header'
      else
        local str = vim.trim(line)
        if str ~= '' then
          item.text = item.text == '' and str or (item.text .. ' ' .. str)
        end
      end
    end

    i = i + 1
  end

  return items
end

function M.run(opts)
  opts = opts or {}

  -- Wrapper that passes replace on first call only (smooth spinner transition)
  local replace = opts.replace_notification
  local function run_notify(msg, level)
    local n = notify(msg, level, replace and { replace = replace } or nil)
    replace = nil
    return n
  end

  local root = find_project_root()
  if not root then
    run_notify('No rescript.json found', vim.log.levels.ERROR)
    return
  end

  local log_path = root .. '/lib/bs/.compiler.log'
  if vim.fn.filereadable(log_path) ~= 1 then
    run_notify('Compiler log not found: ' .. log_path, vim.log.levels.ERROR)
    return
  end

  local lines = vim.fn.readfile(log_path)
  if #lines == 0 then
    run_notify('Compiler log is empty', vim.log.levels.WARN)
    return
  end

  local entries = parse_log_entries(lines)
  if #entries == 0 then
    run_notify('No issues found', vim.log.levels.INFO)
    return
  end

  local latest = entries[#entries]
  local qf_items = parse_compiler_output(latest)

  if #qf_items == 0 then
    run_notify('No issues found', vim.log.levels.INFO)
    return
  end

  local errors = 0
  local warnings = 0
  for _, item in ipairs(qf_items) do
    if item.type == 'E' then
      errors = errors + 1
    else
      warnings = warnings + 1
    end
  end

  vim.fn.setqflist({}, 'r', {
    title = 'ReScript Compiler',
    items = qf_items,
  })
  if opts.open_qf ~= false then
    vim.cmd('copen')
  end

  local summary = string.format('%d error%s, %d warning%s',
    errors, errors == 1 and '' or 's',
    warnings, warnings == 1 and '' or 's')
  local level = errors > 0 and vim.log.levels.ERROR or vim.log.levels.WARN
  run_notify(summary, level)
end

function M.watch_start()
  local root = find_project_root()
  if not root then
    notify('No rescript.json found', vim.log.levels.ERROR)
    return
  end

  if watch_task then
    notify('Watch mode already running', vim.log.levels.WARN)
    return
  end

  local overseer = require('overseer')
  watch_task = overseer.new_task({
    name = 'ReScript Watch',
    cmd = { 'npx', 'rescript', 'build', '-w' },
    cwd = root,
    components = {
      'rescript_watch',
      'on_exit_set_status',
    },
  })
  watch_task:start()
  notify('Watch mode started', vim.log.levels.INFO)
end

function M.watch_stop()
  if not watch_task then
    notify('Watch mode is not running', vim.log.levels.WARN)
    return
  end

  watch_task:stop()
  watch_task:dispose()
  watch_task = nil
  notify('Watch mode stopped', vim.log.levels.INFO)
end

function M.watch_toggle()
  if watch_task then
    M.watch_stop()
  else
    M.watch_start()
  end
end

-- Register overseer template (pcall-guarded in case overseer isn't loaded)
pcall(function()
  require('overseer').register_template({
    name = 'ReScript Watch',
    builder = function()
      return {
        cmd = { 'npx', 'rescript', 'build', '-w' },
        cwd = find_project_root(),
        components = {
          'rescript_watch',
          'on_exit_set_status',
        },
      }
    end,
    condition = {
      callback = function()
        return find_project_root() ~= nil
      end,
    },
  })
end)

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  vim.api.nvim_create_user_command('RES', function() M.run() end, {
    desc = 'Parse ReScript compiler log and show issues in quickfix',
  })

  vim.api.nvim_create_user_command('RESWatch', function(cmd)
    if cmd.bang then
      -- Force restart
      if watch_task then
        M.watch_stop()
      end
      M.watch_start()
    else
      M.watch_toggle()
    end
  end, {
    bang = true,
    desc = 'Toggle ReScript watch mode (! to force restart)',
  })
end

return M
