-- pr-comments/signs.lua
-- Visual indicators for commented lines

local M = {}

-- Namespace for extmarks
local NAMESPACE = vim.api.nvim_create_namespace('pr-comments')

-- Store comments indexed by filepath:line for quick lookup
M._comments_by_file_line = {}
-- Store lines by file for sign placement (with resolved status)
M._lines_by_file = {}
-- Store resolved status by file:line
M._resolved_by_file_line = {}

--- Get the git repository root directory
---@return string|nil root_dir
local function get_git_root()
  local result = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if result.code ~= 0 or not result.stdout then
    return nil
  end
  return vim.trim(result.stdout)
end

--- Clear all placed signs
function M.clear_signs()
  -- Clear extmarks in all loaded buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)
    end
  end
  M._comments_by_file_line = {}
  M._lines_by_file = {}
  M._resolved_by_file_line = {}
  -- Clear the autocmd group
  vim.api.nvim_create_augroup('PRCommentSigns', { clear = true })
end

--- Normalize a file path to canonical form
---@param path string
---@return string
local function normalize_path(path)
  if not path or path == '' then
    return ''
  end
  -- Resolve symlinks and get absolute path
  local resolved = vim.fn.resolve(vim.fn.fnamemodify(path, ':p'))
  return resolved
end

--- Place signs in a specific buffer if it has comments
---@param bufnr number Buffer number
local function place_signs_in_buffer(bufnr)
  -- Clear existing extmarks in this buffer first (prevents duplicates)
  vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local normalized_bufname = normalize_path(bufname)
  local lines = M._lines_by_file[normalized_bufname]
  if lines then
    for line, _ in pairs(lines) do
      local key = normalized_bufname .. ':' .. line
      local is_resolved = M._resolved_by_file_line[key]

      -- Use different sign for resolved vs unresolved comments
      local sign_text = is_resolved and '✓' or '💬'
      local sign_hl = is_resolved and 'DiagnosticOk' or 'DiagnosticInfo'

      vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, line - 1, 0, {
        sign_text = sign_text,
        sign_hl_group = sign_hl,
        priority = 10,
      })
    end
  end
end

--- Place signs on commented lines
---@param comments table[] Normalized comments
function M.place_signs(comments)
  M.clear_signs()

  local git_root = get_git_root()
  if not git_root then
    vim.notify('Failed to get git root directory', vim.log.levels.ERROR)
    return
  end

  -- Group comments by file:line for lookup and sign placement
  for _, comment in ipairs(comments) do
    local filepath = normalize_path(git_root .. '/' .. comment.path)
    local key = filepath .. ':' .. comment.line

    -- Store for lookup
    if not M._comments_by_file_line[key] then
      M._comments_by_file_line[key] = {}
    end
    table.insert(M._comments_by_file_line[key], comment)

    -- Group by file for sign placement
    if not M._lines_by_file[filepath] then
      M._lines_by_file[filepath] = {}
    end
    M._lines_by_file[filepath][comment.line] = true

    -- Track resolved status (use first comment's status as thread indicator)
    if M._resolved_by_file_line[key] == nil then
      M._resolved_by_file_line[key] = comment.is_resolved
    end
  end

  -- Place signs for files that are currently loaded in buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      place_signs_in_buffer(bufnr)
    end
  end

  -- Set up autocmd to place signs when buffers are entered
  vim.api.nvim_create_autocmd('BufEnter', {
    group = vim.api.nvim_create_augroup('PRCommentSigns', { clear = true }),
    callback = function(ev)
      -- Only place if we haven't already (check for existing extmarks)
      local existing = vim.api.nvim_buf_get_extmarks(ev.buf, NAMESPACE, 0, -1, {})
      if #existing == 0 then
        place_signs_in_buffer(ev.buf)
      end
    end,
  })
end

--- Get comments at the current cursor position
---@return table[]|nil comments Comments at cursor line, or nil if none
function M.get_comments_at_cursor()
  local bufname = normalize_path(vim.api.nvim_buf_get_name(0))
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local key = bufname .. ':' .. line

  local comments = M._comments_by_file_line[key]
  if comments and #comments > 0 then
    return comments
  end
  return nil
end

--- Debug function to show stored paths vs current buffer
function M.debug()
  local bufname = vim.api.nvim_buf_get_name(0)
  local normalized = normalize_path(bufname)
  print('Current buffer: ' .. bufname)
  print('Normalized: ' .. normalized)
  print('Files with comments:')
  for filepath, lines in pairs(M._lines_by_file) do
    local line_list = {}
    for line, _ in pairs(lines) do
      table.insert(line_list, line)
    end
    print('  ' .. filepath .. ' (lines: ' .. table.concat(line_list, ', ') .. ')')
  end
end

return M
