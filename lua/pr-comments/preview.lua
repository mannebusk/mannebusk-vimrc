-- pr-comments/preview.lua
-- Floating window for displaying PR comment details with diff context

local M = {}

-- Store current preview window/buffer for cleanup
local preview_win = nil
local preview_buf = nil

--- Close the preview window if open
local function close_preview()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_close(preview_win, true)
  end
  preview_win = nil
  preview_buf = nil
end

--- Decode common HTML entities
---@param str string
---@return string
local function decode_html_entities(str)
  local entities = {
    ['&nbsp;'] = ' ',
    ['&lt;'] = '<',
    ['&gt;'] = '>',
    ['&amp;'] = '&',
    ['&quot;'] = '"',
    ['&apos;'] = "'",
    ['&#39;'] = "'",
  }
  local result = str
  for entity, char in pairs(entities) do
    result = result:gsub(entity, char)
  end
  -- Decode numeric entities (&#60; -> <)
  result = result:gsub('&#(%d+);', function(n)
    return string.char(tonumber(n))
  end)
  return result
end

--- Sanitize comment body for display
---@param body string Raw comment body
---@return string Sanitized body
local function sanitize_body(body)
  local result = body

  -- Remove HTML comments (including multiline)
  result = result:gsub('<!%-%-.-%-%->', '')

  -- Remove HTML anchor tags with their content (used for "Fix in Cursor" buttons etc.)
  result = result:gsub('<a[^>]*>.-</a>', '')

  -- Remove any remaining HTML tags (picture, source, img, etc.)
  result = result:gsub('<[^>]+>', '')

  -- Clean up excessive blank lines (3+ newlines -> 2 newlines)
  result = result:gsub('\n\n\n+', '\n\n')

  -- Trim leading/trailing whitespace
  result = result:match('^%s*(.-)%s*$') or result

  -- Decode HTML entities
  result = decode_html_entities(result)

  return result
end

--- Format comments into markdown content for display
---@param comments table[] Comments to format
---@return string[] lines Formatted lines
local function format_comments(comments)
  local lines = {}

  -- Show [RESOLVED] banner if thread is resolved
  local first_comment = comments[1]
  if first_comment and first_comment.is_resolved then
    table.insert(lines, '**[RESOLVED]**')
    table.insert(lines, '')
  end

  -- Show diff once at the top (from first comment)
  if first_comment and first_comment.diff_hunk and first_comment.diff_hunk ~= '' then
    local hunk_lines = {}
    for line in first_comment.diff_hunk:gmatch('[^\r\n]+') do
      table.insert(hunk_lines, line)
    end
    local start_idx = math.max(1, #hunk_lines - 7)
    table.insert(lines, '```diff')
    if start_idx > 1 then
      table.insert(lines, '...')
    end
    for j = start_idx, #hunk_lines do
      table.insert(lines, hunk_lines[j])
    end
    table.insert(lines, '```')
    table.insert(lines, '')
    table.insert(lines, '---')
    table.insert(lines, '')
  end

  -- Then list all comments without the diff
  for i, comment in ipairs(comments) do
    if i > 1 then
      table.insert(lines, '')
      table.insert(lines, '---')
      table.insert(lines, '')
    end

    -- Author and date/time header
    local date_str = ''
    if comment.created_at and comment.created_at ~= '' then
      -- Format: "2024-01-15T14:30:00Z" -> "2024-01-15 14:30"
      local datetime = comment.created_at:sub(1, 16):gsub('T', ' ')
      date_str = ' (' .. datetime .. ')'
    end
    table.insert(lines, string.format('**@%s**%s', comment.author, date_str))
    table.insert(lines, '')

    -- Comment body (sanitized) - NO diff here
    local clean_body = sanitize_body(comment.body)
    for line in clean_body:gmatch('[^\r\n]+') do
      table.insert(lines, line)
    end

    comment._index = i
  end

  return lines
end

--- Calculate window dimensions based on content
---@param lines string[] Content lines
---@return number width, number height
local function calculate_dimensions(lines)
  local max_width = 40
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
  end

  -- Cap dimensions
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines
  local width = math.min(max_width + 2, math.floor(editor_width * 0.8))
  local height = math.min(#lines, math.floor(editor_height * 0.6))

  return width, height
end

--- Show floating window with comments
---@param comments table[] Comments to display
function M.show_expanded(comments)
  close_preview()

  local lines = format_comments(comments)
  local width, height = calculate_dimensions(lines)

  -- Create buffer
  preview_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
  vim.bo[preview_buf].modifiable = false
  vim.bo[preview_buf].bufhidden = 'wipe'
  vim.bo[preview_buf].filetype = 'markdown'

  -- Calculate position (centered)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Determine window title based on resolved status
  local is_resolved = comments[1] and comments[1].is_resolved
  local title = is_resolved and ' PR Comment [RESOLVED] ' or ' PR Comment '

  -- Create window
  preview_win = vim.api.nvim_open_win(preview_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
  })

  -- Set window options
  vim.wo[preview_win].wrap = true
  vim.wo[preview_win].conceallevel = 2
  vim.wo[preview_win].concealcursor = 'niv'

  -- Store comments for gx access
  vim.b[preview_buf].pr_comments = comments
  vim.b[preview_buf].pr_thread_id = comments[1] and comments[1].thread_id
  vim.b[preview_buf].pr_is_resolved = comments[1] and comments[1].is_resolved

  -- Set up keymaps
  local opts = { buffer = preview_buf, noremap = true, silent = true }

  -- Close with q or Escape
  vim.keymap.set('n', 'q', close_preview, opts)
  vim.keymap.set('n', '<Esc>', close_preview, opts)

  -- Open in browser with gx
  vim.keymap.set('n', 'gx', function()
    local buf_comments = vim.b[preview_buf].pr_comments
    if buf_comments and #buf_comments > 0 then
      -- Open the first comment's URL (or we could prompt for which one)
      local url = buf_comments[1].html_url
      if url and url ~= '' then
        vim.ui.open(url)
      else
        vim.notify('No URL available for this comment', vim.log.levels.WARN)
      end
    end
  end, opts)

  -- Reply with r
  vim.keymap.set('n', 'r', function()
    local buf_comments = vim.b[preview_buf].pr_comments
    close_preview()
    if buf_comments and #buf_comments > 0 then
      local reply_mod = require('pr-comments.reply')
      reply_mod.reply_from_preview(buf_comments)
    end
  end, opts)

  -- Resolve thread with x
  vim.keymap.set('n', 'x', function()
    local thread_id = vim.b[preview_buf].pr_thread_id
    local is_resolved = vim.b[preview_buf].pr_is_resolved
    close_preview()
    if thread_id then
      local resolve = require('pr-comments.resolve')
      resolve.resolve_thread_interactive(thread_id, is_resolved)
    else
      vim.notify('Cannot resolve: thread ID not available', vim.log.levels.ERROR)
    end
  end, opts)

  -- Close on leaving the window
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = preview_buf,
    once = true,
    callback = close_preview,
  })
end

--- Show comment preview for the current cursor position
function M.show_at_cursor()
  local signs = require('pr-comments.signs')
  local comments = signs.get_comments_at_cursor()

  if not comments then
    vim.notify('No PR comment on this line', vim.log.levels.INFO)
    return
  end

  M.show_expanded(comments)
end

--- Close the preview window (exported for external use)
function M.close()
  close_preview()
end

return M
