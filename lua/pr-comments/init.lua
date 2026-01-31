-- pr-comments/init.lua
-- GitHub PR Review Comments Plugin
-- Fetches PR comments, displays in quickfix, shows visual indicators, and previews in floating windows

local M = {}

-- Module imports
local fetch = require('pr-comments.fetch')
local quickfix = require('pr-comments.quickfix')
local signs = require('pr-comments.signs')
local preview = require('pr-comments.preview')
local reply = require('pr-comments.reply')

-- Cache for fetched comments
M._comments_cache = nil
M._pr_number_cache = nil

-- Session state for resolved filter (nil = use config default)
M._show_resolved = nil

--- Default configuration
M.config = {
  keymap = '<leader>pc', -- Keymap to show comment at cursor
  show_resolved = false, -- Hide resolved comments by default
}

--- Get the effective show_resolved value
---@return boolean
function M.get_show_resolved()
  if M._show_resolved ~= nil then
    return M._show_resolved
  end
  return M.config.show_resolved
end

--- Filter comments based on resolved status
---@param comments table[] All comments
---@return table[] filtered_comments
function M.filter_comments(comments)
  if M.get_show_resolved() then
    return comments
  end

  local filtered = {}
  for _, c in ipairs(comments) do
    if not c.is_resolved then
      table.insert(filtered, c)
    end
  end
  return filtered
end

--- Refresh the display with current filter settings
function M.refresh_display()
  if not M._comments_cache or not M._pr_number_cache then
    vim.notify('No comments loaded. Run :PRComments first.', vim.log.levels.WARN)
    return
  end

  local filtered = M.filter_comments(M._comments_cache)

  if #filtered == 0 then
    vim.notify('No comments to display with current filter', vim.log.levels.INFO)
    vim.fn.setqflist({}, 'r', {
      title = string.format('PR #%d Review Comments (0)', M._pr_number_cache),
      items = {},
    })
    signs.clear_signs()
    return
  end

  quickfix.populate(filtered, M._pr_number_cache, M.get_show_resolved())
  signs.place_signs(filtered)
end

--- Toggle showing resolved comments
function M.toggle_show_resolved()
  M._show_resolved = not M.get_show_resolved()
  local status = M._show_resolved and 'shown' or 'hidden'
  vim.notify('Resolved comments: ' .. status, vim.log.levels.INFO)
  M.refresh_display()
end

--- Force show resolved comments
function M.show_resolved()
  M._show_resolved = true
  vim.notify('Resolved comments: shown', vim.log.levels.INFO)
  M.refresh_display()
end

--- Force hide resolved comments
function M.hide_resolved()
  M._show_resolved = false
  vim.notify('Resolved comments: hidden', vim.log.levels.INFO)
  M.refresh_display()
end

--- Fetch and display PR comments
---@param pr_number number|nil PR number (auto-detect if nil)
function M.fetch_and_display(pr_number)
  -- Get PR number if not provided
  if not pr_number then
    pr_number = fetch.get_pr_number()
    if not pr_number then
      vim.ui.input({ prompt = 'Enter PR number: ' }, function(input)
        if input then
          local num = tonumber(input)
          if num then
            M.fetch_and_display(num)
          else
            vim.notify('Invalid PR number', vim.log.levels.ERROR)
          end
        end
      end)
      return
    end
  end

  vim.notify(string.format('Fetching comments for PR #%d...', pr_number), vim.log.levels.INFO)

  fetch.fetch_pr_comments(pr_number, function(comments, err)
    if err then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end

    if not comments or #comments == 0 then
      vim.notify(string.format('No review comments found for PR #%d', pr_number), vim.log.levels.INFO)
      return
    end

    -- Cache all comments (unfiltered)
    M._comments_cache = comments
    M._pr_number_cache = pr_number

    -- Count resolved vs unresolved
    local resolved_count = 0
    for _, c in ipairs(comments) do
      if c.is_resolved and not c.in_reply_to_id then
        resolved_count = resolved_count + 1
      end
    end

    -- Filter comments based on show_resolved setting
    local filtered = M.filter_comments(comments)

    -- Populate quickfix list with filtered comments
    quickfix.populate(filtered, pr_number, M.get_show_resolved())

    -- Place signs on commented lines
    signs.place_signs(filtered)

    local msg = string.format('Loaded %d review comments for PR #%d', #comments, pr_number)
    if resolved_count > 0 and not M.get_show_resolved() then
      msg = msg .. string.format(' (%d resolved hidden)', resolved_count)
    end
    vim.notify(msg, vim.log.levels.INFO)
  end)
end

--- Show comment at cursor position
function M.show_comment()
  preview.show_at_cursor()
end

--- Clear all PR comment data
function M.clear()
  preview.close()
  signs.clear_signs()
  M._comments_cache = nil
  M._pr_number_cache = nil
  vim.fn.setqflist({}, 'r')
  vim.notify('PR comments cleared', vim.log.levels.INFO)
end

--- Setup the plugin
---@param opts table|nil Configuration options
function M.setup(opts)
  -- Merge config
  if opts then
    M.config = vim.tbl_deep_extend('force', M.config, opts)
  end

  -- Create commands
  vim.api.nvim_create_user_command('PRComments', function(cmd_opts)
    local pr_number = nil
    if cmd_opts.args and cmd_opts.args ~= '' then
      pr_number = tonumber(cmd_opts.args)
      if not pr_number then
        vim.notify('Invalid PR number: ' .. cmd_opts.args, vim.log.levels.ERROR)
        return
      end
    end
    M.fetch_and_display(pr_number)
  end, {
    nargs = '?',
    desc = 'Fetch and display PR review comments',
  })

  vim.api.nvim_create_user_command('PRCommentShow', function()
    M.show_comment()
  end, {
    desc = 'Show PR comment at cursor in floating window',
  })

  vim.api.nvim_create_user_command('PRCommentReply', function()
    reply.reply_at_cursor()
  end, {
    desc = 'Reply to PR comment at cursor',
  })

  vim.api.nvim_create_user_command('PRCommentsClear', function()
    M.clear()
  end, {
    desc = 'Clear all PR comment data',
  })

  vim.api.nvim_create_user_command('PRCommentsDebug', function()
    signs.debug()
  end, {
    desc = 'Debug PR comments - show stored paths vs current buffer',
  })

  vim.api.nvim_create_user_command('PRCommentsToggleResolved', function()
    M.toggle_show_resolved()
  end, {
    desc = 'Toggle showing resolved PR comments',
  })

  vim.api.nvim_create_user_command('PRCommentsShowResolved', function()
    M.show_resolved()
  end, {
    desc = 'Show resolved PR comments',
  })

  vim.api.nvim_create_user_command('PRCommentsHideResolved', function()
    M.hide_resolved()
  end, {
    desc = 'Hide resolved PR comments',
  })

  -- Set up keymap
  if M.config.keymap then
    vim.keymap.set('n', M.config.keymap, M.show_comment, {
      desc = 'Show PR comment at cursor',
      silent = true,
    })
  end
end

return M
