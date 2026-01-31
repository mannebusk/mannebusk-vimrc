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

--- Sort comments so replies follow their parent
---@param comments table[] Normalized comments
---@return table[] sorted_comments
local function sort_comments_with_replies(comments)
  -- Build lookup table by ID
  local by_id = {}
  for _, c in ipairs(comments) do
    by_id[c.id] = c
  end

  -- Separate parents and replies
  local parents = {}
  local replies_by_parent = {}

  for _, c in ipairs(comments) do
    if c.in_reply_to_id then
      -- It's a reply
      local parent_id = c.in_reply_to_id
      if not replies_by_parent[parent_id] then
        replies_by_parent[parent_id] = {}
      end
      table.insert(replies_by_parent[parent_id], c)
    else
      -- It's a parent comment
      table.insert(parents, c)
    end
  end

  -- Sort parents by created_at
  table.sort(parents, function(a, b)
    return a.created_at < b.created_at
  end)

  -- Sort replies within each parent by created_at
  for _, reply_list in pairs(replies_by_parent) do
    table.sort(reply_list, function(a, b)
      return a.created_at < b.created_at
    end)
  end

  -- Build final sorted list with parents followed by their replies
  local sorted = {}
  for _, parent in ipairs(parents) do
    table.insert(sorted, parent)
    if replies_by_parent[parent.id] then
      for _, reply in ipairs(replies_by_parent[parent.id]) do
        table.insert(sorted, reply)
      end
    end
  end

  return sorted
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

  -- Sort comments so replies follow their parent
  local sorted_comments = sort_comments_with_replies(comments)

  local qf_items = {}
  for _, comment in ipairs(sorted_comments) do
    -- Build full file path
    local filepath = git_root .. '/' .. comment.path

    -- Truncate body for quickfix display (first line only, max 80 chars)
    local body_preview = comment.body:gsub('\r?\n.*', ''):sub(1, 80)
    if #comment.body > 80 or comment.body:find('\n') then
      body_preview = body_preview .. '...'
    end

    -- Add prefix for replies to show hierarchy
    local is_reply = comment.in_reply_to_id ~= nil
    local prefix = is_reply and '  └── ' or ''
    local text = prefix .. string.format('@%s: %s', comment.author, body_preview)

    table.insert(qf_items, {
      filename = filepath,
      lnum = comment.line,
      col = 1,
      text = text,
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
