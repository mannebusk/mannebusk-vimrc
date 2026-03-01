local M = {}

local function notify(msg, level)
  vim.notify(msg, level, { title = 'ReScript' })
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

function M.run()
  local root = find_project_root()
  if not root then
    notify('No rescript.json found', vim.log.levels.ERROR)
    return
  end

  local log_path = root .. '/lib/bs/.compiler.log'
  if vim.fn.filereadable(log_path) ~= 1 then
    notify('Compiler log not found: ' .. log_path, vim.log.levels.ERROR)
    return
  end

  local lines = vim.fn.readfile(log_path)
  if #lines == 0 then
    notify('Compiler log is empty', vim.log.levels.WARN)
    return
  end

  local entries = parse_log_entries(lines)
  if #entries == 0 then
    notify('No issues found', vim.log.levels.INFO)
    return
  end

  local latest = entries[#entries]
  local qf_items = parse_compiler_output(latest)

  if #qf_items == 0 then
    notify('No issues found', vim.log.levels.INFO)
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
  vim.cmd('copen')

  local summary = string.format('%d error%s, %d warning%s',
    errors, errors == 1 and '' or 's',
    warnings, warnings == 1 and '' or 's')
  local level = errors > 0 and vim.log.levels.ERROR or vim.log.levels.WARN
  notify(summary, level)
end

vim.api.nvim_create_user_command('RES', function() M.run() end, {
  desc = 'Parse ReScript compiler log and show issues in quickfix',
})

return M
