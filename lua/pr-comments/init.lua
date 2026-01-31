-- pr-comments/init.lua
-- GitHub PR Review Comments Plugin
-- Fetches PR comments, displays in quickfix, shows visual indicators, and previews in floating windows

local M = {}

-- Module imports
local fetch = require('pr-comments.fetch')
local quickfix = require('pr-comments.quickfix')
local signs = require('pr-comments.signs')
local preview = require('pr-comments.preview')

-- Cache for fetched comments
M._comments_cache = nil
M._pr_number_cache = nil

--- Default configuration
M.config = {
  keymap = '<leader>pc', -- Keymap to show comment at cursor
}

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

    -- Cache the comments
    M._comments_cache = comments
    M._pr_number_cache = pr_number

    -- Populate quickfix list
    quickfix.populate(comments, pr_number)

    -- Place signs on commented lines
    signs.place_signs(comments)

    vim.notify(string.format('Loaded %d review comments for PR #%d', #comments, pr_number), vim.log.levels.INFO)
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

  -- Set up keymap
  if M.config.keymap then
    vim.keymap.set('n', M.config.keymap, M.show_comment, {
      desc = 'Show PR comment at cursor',
      silent = true,
    })
  end
end

return M
