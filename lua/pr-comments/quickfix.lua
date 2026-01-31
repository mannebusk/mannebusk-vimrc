-- pr-comments/quickfix.lua
-- Populates quickfix list with PR review comments

local M = {}

--- Get the git repository root directory
---@return string|nil root_dir
local function get_git_root()
  local result = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if result.code ~= 0 or not result.stdout then
    return nil
  end
  return vim.trim(result.stdout)
end

--- Populate quickfix list with PR comments
---@param comments table[] Normalized comments
---@param pr_number number PR number for title
function M.populate(comments, pr_number)
  local git_root = get_git_root()
  if not git_root then
    vim.notify('Failed to get git root directory', vim.log.levels.ERROR)
    return
  end

  local qf_items = {}
  for _, comment in ipairs(comments) do
    -- Build full file path
    local filepath = git_root .. '/' .. comment.path

    -- Truncate body for quickfix display (first line only, max 80 chars)
    local body_preview = comment.body:gsub('\r?\n.*', ''):sub(1, 80)
    if #comment.body > 80 or comment.body:find('\n') then
      body_preview = body_preview .. '...'
    end

    table.insert(qf_items, {
      filename = filepath,
      lnum = comment.line,
      col = 1,
      text = string.format('@%s: %s', comment.author, body_preview),
      type = 'I', -- Info type
    })
  end

  -- Set quickfix list
  vim.fn.setqflist({}, 'r', {
    title = string.format('PR #%d Review Comments (%d)', pr_number, #comments),
    items = qf_items,
  })

  -- Open quickfix window
  vim.cmd('copen')
end

return M
