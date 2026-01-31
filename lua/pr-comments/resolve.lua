-- pr-comments/resolve.lua
-- Resolve PR comment threads using GraphQL API

local M = {}

--- GraphQL mutation to resolve a review thread
local RESOLVE_MUTATION = [[
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread {
      id
      isResolved
    }
  }
}
]]

--- Resolve a review thread
---@param thread_id string The GraphQL node ID of the thread
---@param callback fun(success: boolean, err: string|nil)
function M.resolve_thread(thread_id, callback)
  vim.system(
    { 'gh', 'api', 'graphql', '-f', 'query=' .. RESOLVE_MUTATION, '-F', 'threadId=' .. thread_id },
    { text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          callback(false, 'Failed to resolve thread: ' .. (result.stderr or 'unknown error'))
          return
        end

        local ok, response = pcall(vim.json.decode, result.stdout)
        if not ok or type(response) ~= 'table' then
          callback(false, 'Failed to parse response')
          return
        end

        -- Check for GraphQL errors
        if response.errors then
          local err_msg = response.errors[1] and response.errors[1].message or 'GraphQL error'
          callback(false, 'GraphQL error: ' .. err_msg)
          return
        end

        -- Check if resolution was successful
        local data = response.data
        if data and data.resolveReviewThread and data.resolveReviewThread.thread then
          local thread = data.resolveReviewThread.thread
          if thread.isResolved then
            callback(true, nil)
          else
            callback(false, 'Thread was not resolved')
          end
        else
          callback(false, 'Unexpected response structure')
        end
      end)
    end
  )
end

--- Resolve a thread with confirmation dialog
---@param thread_id string The GraphQL node ID of the thread
---@param is_resolved boolean|nil Whether the thread is already resolved
function M.resolve_thread_interactive(thread_id, is_resolved)
  if not thread_id then
    vim.notify('Cannot resolve: thread ID not available', vim.log.levels.ERROR)
    return
  end

  if is_resolved then
    vim.notify('This thread is already resolved', vim.log.levels.INFO)
    return
  end

  vim.ui.select({ 'Yes', 'No' }, {
    prompt = 'Resolve this comment thread?',
  }, function(choice)
    if choice ~= 'Yes' then
      return
    end

    vim.notify('Resolving thread...', vim.log.levels.INFO)

    M.resolve_thread(thread_id, function(success, err)
      if success then
        vim.notify('Thread resolved successfully!', vim.log.levels.INFO)
        local init = require('pr-comments')
        if init._pr_number_cache then
          init.fetch_and_display(init._pr_number_cache)
        end
      else
        vim.notify(err or 'Failed to resolve thread', vim.log.levels.ERROR)
      end
    end)
  end)
end

--- Resolve thread from preview window (deprecated, use resolve_thread_interactive)
---@param comments table[] Comments from the preview window
function M.resolve_from_preview(comments)
  if not comments or #comments == 0 then
    vim.notify('No comments to resolve', vim.log.levels.WARN)
    return
  end

  -- Get thread_id from first comment (all comments in thread share it)
  local thread_id = comments[1].thread_id
  if not thread_id then
    vim.notify('Cannot resolve: thread ID not available', vim.log.levels.ERROR)
    return
  end

  -- Check if already resolved
  if comments[1].is_resolved then
    vim.notify('This thread is already resolved', vim.log.levels.INFO)
    return
  end

  -- Confirmation dialog
  vim.ui.select({ 'Yes', 'No' }, {
    prompt = 'Resolve this comment thread?',
  }, function(choice)
    if choice ~= 'Yes' then
      return
    end

    vim.notify('Resolving thread...', vim.log.levels.INFO)

    M.resolve_thread(thread_id, function(success, err)
      if success then
        vim.notify('Thread resolved successfully!', vim.log.levels.INFO)
        -- Refetch comments to update the display
        local init = require('pr-comments')
        if init._pr_number_cache then
          init.fetch_and_display(init._pr_number_cache)
        end
      else
        vim.notify(err or 'Failed to resolve thread', vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
