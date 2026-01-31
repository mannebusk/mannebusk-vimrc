-- pr-comments/reply.lua
-- Reply to PR comments using a scratch buffer in a split

local M = {}

--- Get the parent (top-level) comment ID for a comment
--- GitHub only allows replies to top-level comments, not replies-to-replies
---@param comment table The comment to find the parent for
---@param all_comments table[] All comments in the thread
---@return number parent_id The top-level comment ID
local function get_parent_id(comment, all_comments)
  -- If this comment has no in_reply_to_id, it is a parent
  if not comment.in_reply_to_id then
    return comment.id
  end

  -- Build a map of comment id -> comment for quick lookup
  local by_id = {}
  for _, c in ipairs(all_comments) do
    by_id[c.id] = c
  end

  -- Traverse up the chain to find the root
  local current = comment
  while current.in_reply_to_id do
    local parent = by_id[current.in_reply_to_id]
    if not parent then
      -- Parent not found in our list, use in_reply_to_id as the parent
      return current.in_reply_to_id
    end
    current = parent
  end

  return current.id
end

--- Get only the top-level (parent) comments from a list
---@param comments table[] All comments
---@return table[] parents Only comments that are not replies
local function get_parent_comments(comments)
  local parents = {}
  for _, c in ipairs(comments) do
    if not c.in_reply_to_id then
      table.insert(parents, c)
    end
  end
  return parents
end

--- Submit a reply to GitHub
---@param parent_id number The parent comment ID to reply to
---@param body string The reply text
---@param callback fun(success: boolean, err: string|nil)
local function submit_reply(parent_id, body, callback)
  local fetch = require('pr-comments.fetch')

  local repo = fetch.get_repo_info()
  if not repo then
    callback(false, 'Failed to get repository info')
    return
  end

  local pr_number = fetch.get_pr_number()
  if not pr_number then
    callback(false, 'Failed to get PR number for current branch')
    return
  end

  -- GitHub API: POST /repos/{owner}/{repo}/pulls/{pull_number}/comments/{comment_id}/replies
  local api_path = string.format('repos/%s/pulls/%d/comments/%d/replies', repo, pr_number, parent_id)

  vim.system(
    { 'gh', 'api', '-X', 'POST', api_path, '-f', 'body=' .. body },
    { text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          callback(false, 'Failed to submit reply: ' .. (result.stderr or 'unknown error'))
          return
        end
        callback(true, nil)
      end)
    end
  )
end

--- Create the reply buffer content with context
---@param comment table The comment being replied to
---@param pr_number number|nil The PR number
---@return string[] lines The buffer content lines
local function create_buffer_content(comment, pr_number)
  local lines = {}

  -- Header with context
  local pr_str = pr_number and string.format(' on PR #%d', pr_number) or ''
  table.insert(lines, string.format('# Reply to @%s%s', comment.author, pr_str))

  -- Date if available
  if comment.created_at and comment.created_at ~= '' then
    local datetime = comment.created_at:sub(1, 16):gsub('T', ' ')
    table.insert(lines, string.format('# (%s)', datetime))
  end

  table.insert(lines, '#')

  -- Quote original comment body
  local body_lines = vim.split(comment.body, '\n', { plain = true })
  for _, line in ipairs(body_lines) do
    table.insert(lines, '# > ' .. line)
  end

  table.insert(lines, '#')
  table.insert(lines, '# :w to submit | :q! to cancel')
  table.insert(lines, '# ---')
  table.insert(lines, '')

  return lines
end

--- Extract the reply text from buffer content (filtering out # lines)
---@param lines string[] Buffer lines
---@return string reply_text
local function extract_reply_text(lines)
  local reply_lines = {}
  for _, line in ipairs(lines) do
    -- Skip lines starting with # (context/instructions)
    if not line:match('^#') then
      table.insert(reply_lines, line)
    end
  end

  -- Join and trim
  local text = table.concat(reply_lines, '\n')
  text = text:match('^%s*(.-)%s*$') or text
  return text
end

--- Open a reply buffer for a specific comment
---@param comment table The comment to reply to
---@param all_comments table[] All comments in the thread (for finding parent)
---@param pr_number number|nil The PR number for display
function M.reply_to_comment(comment, all_comments, pr_number)
  local parent_id = get_parent_id(comment, all_comments)

  -- Create buffer
  local reply_buf = vim.api.nvim_create_buf(false, true)
  local buf_name = string.format('PR Reply to @%s [%d]', comment.author, parent_id)
  vim.api.nvim_buf_set_name(reply_buf, buf_name)

  -- Set buffer content
  local content = create_buffer_content(comment, pr_number)
  vim.api.nvim_buf_set_lines(reply_buf, 0, -1, false, content)

  -- Buffer options
  vim.bo[reply_buf].buftype = 'acwrite' -- Allows :w without a real file
  vim.bo[reply_buf].filetype = 'markdown'
  vim.bo[reply_buf].bufhidden = 'wipe'
  vim.bo[reply_buf].swapfile = false

  -- Open split
  local height = math.min(15, math.floor(vim.o.lines * 0.3))
  vim.cmd('botright ' .. height .. 'split')
  vim.api.nvim_win_set_buf(0, reply_buf)

  -- Move cursor to the empty line at the end and enter insert mode
  local line_count = vim.api.nvim_buf_line_count(reply_buf)
  vim.api.nvim_win_set_cursor(0, { line_count, 0 })
  vim.cmd('startinsert')

  -- BufWriteCmd intercepts :w for custom submission
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = reply_buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(reply_buf, 0, -1, false)
      local reply_text = extract_reply_text(lines)

      if reply_text == '' then
        vim.notify('Reply is empty, not submitting', vim.log.levels.WARN)
        return
      end

      vim.notify('Submitting reply...', vim.log.levels.INFO)

      submit_reply(parent_id, reply_text, function(success, err)
        if success then
          vim.notify('Reply submitted successfully!', vim.log.levels.INFO)
          -- Close the buffer
          if vim.api.nvim_buf_is_valid(reply_buf) then
            vim.api.nvim_buf_delete(reply_buf, { force = true })
          end
        else
          vim.notify(err or 'Failed to submit reply', vim.log.levels.ERROR)
        end
      end)
    end,
  })

  -- q in normal mode cancels
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_buf_delete(reply_buf, { force = true })
  end, { buffer = reply_buf, noremap = true, silent = true, desc = 'Cancel reply' })
end

--- Open reply interface for comments at cursor position
function M.reply_at_cursor()
  local signs = require('pr-comments.signs')
  local comments = signs.get_comments_at_cursor()

  if not comments or #comments == 0 then
    vim.notify('No PR comment on this line', vim.log.levels.INFO)
    return
  end

  local init = require('pr-comments')
  local pr_number = init._pr_number_cache

  -- Get parent comments (threads) only
  local parents = get_parent_comments(comments)

  if #parents == 0 then
    -- All comments are replies, reply to the first one's parent
    M.reply_to_comment(comments[1], comments, pr_number)
  elseif #parents == 1 then
    -- Single thread, reply directly
    M.reply_to_comment(parents[1], comments, pr_number)
  else
    -- Multiple threads, let user pick
    vim.ui.select(parents, {
      prompt = 'Select thread to reply to:',
      format_item = function(c)
        local preview = c.body:sub(1, 50)
        if #c.body > 50 then
          preview = preview .. '...'
        end
        return string.format('@%s: %s', c.author, preview)
      end,
    }, function(selected)
      if selected then
        M.reply_to_comment(selected, comments, pr_number)
      end
    end)
  end
end

--- Reply from preview window (with access to displayed comments)
---@param comments table[] Comments displayed in the preview window
function M.reply_from_preview(comments)
  if not comments or #comments == 0 then
    vim.notify('No comments to reply to', vim.log.levels.WARN)
    return
  end

  local init = require('pr-comments')
  local pr_number = init._pr_number_cache

  -- Get parent comments (threads) only
  local parents = get_parent_comments(comments)

  if #parents == 0 then
    -- All comments are replies, reply to the first one's parent
    M.reply_to_comment(comments[1], comments, pr_number)
  elseif #parents == 1 then
    -- Single thread, reply directly
    M.reply_to_comment(parents[1], comments, pr_number)
  else
    -- Multiple threads, let user pick
    vim.ui.select(parents, {
      prompt = 'Select thread to reply to:',
      format_item = function(c)
        local preview = c.body:sub(1, 50)
        if #c.body > 50 then
          preview = preview .. '...'
        end
        return string.format('@%s: %s', c.author, preview)
      end,
    }, function(selected)
      if selected then
        M.reply_to_comment(selected, comments, pr_number)
      end
    end)
  end
end

return M
