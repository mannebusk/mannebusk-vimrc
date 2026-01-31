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
---@param show_resolved boolean|nil Whether resolved comments are being shown
function M.populate(comments, pr_number, show_resolved)
  local git_root = get_git_root()
  if not git_root then
    vim.notify('Failed to get git root directory', vim.log.levels.ERROR)
    return
  end

  -- Count replies for each parent comment
  local reply_count = {}
  for _, comment in ipairs(comments) do
    if comment.in_reply_to_id then
      reply_count[comment.in_reply_to_id] = (reply_count[comment.in_reply_to_id] or 0) + 1
    end
  end

  local qf_items = {}
  for _, comment in ipairs(comments) do
    -- Skip replies - they'll be counted with their parent
    if comment.in_reply_to_id then
      goto continue
    end

    -- Build full file path
    local filepath = git_root .. '/' .. comment.path

    local num_replies = reply_count[comment.id] or 0
    local text
    -- Add [RESOLVED] prefix when showing resolved comments
    local prefix = (show_resolved and comment.is_resolved) and '[RESOLVED] ' or ''

    if num_replies > 0 then
      -- Has replies: show comment count (parent + replies)
      local total = num_replies + 1
      text = string.format('%s@%s: %d %s',
        prefix,
        comment.author or 'unknown',
        total,
        total == 1 and 'comment' or 'comments')
    else
      -- No replies: show message preview as before
      local body_preview = (comment.body or ''):gsub('\r?\n', ' ')
      if #body_preview > 80 then
        body_preview = body_preview:sub(1, 77) .. '...'
      end
      text = string.format('%s@%s: %s', prefix, comment.author or 'unknown', body_preview)
    end

    table.insert(qf_items, {
      filename = filepath,
      lnum = comment.line,
      col = 1,
      text = text,
      type = 'I', -- Info type
    })

    ::continue::
  end

  -- Count resolved comments for title
  local resolved_count = 0
  if show_resolved then
    for _, comment in ipairs(comments) do
      if comment.is_resolved and not comment.in_reply_to_id then
        resolved_count = resolved_count + 1
      end
    end
  end

  -- Set quickfix list
  local title
  if show_resolved and resolved_count > 0 then
    title = string.format('PR #%d Review Comments (%d, %d resolved)', pr_number, #qf_items, resolved_count)
  else
    title = string.format('PR #%d Review Comments (%d)', pr_number, #qf_items)
  end

  vim.fn.setqflist({}, 'r', {
    title = title,
    items = qf_items,
  })

  -- Open quickfix window
  vim.cmd('copen')
end

return M
