-- pr-comments/fetch.lua
-- Fetches PR review comments using gh CLI with GraphQL API

local M = {}

--- Get repository info (owner/repo) using gh CLI
---@return string|nil owner, string|nil repo
function M.get_repo_info()
  local result = vim.system({ 'gh', 'repo', 'view', '--json', 'owner,name' }, { text = true }):wait()
  if result.code ~= 0 or not result.stdout then
    return nil, nil
  end
  local ok, data = pcall(vim.json.decode, result.stdout)
  if not ok or type(data) ~= 'table' then
    return nil, nil
  end
  local owner = data.owner and data.owner.login
  local repo = data.name
  if not owner or not repo then
    return nil, nil
  end
  return owner, repo
end

--- Get PR number for current branch
---@return number|nil pr_number
function M.get_pr_number()
  local result = vim.system({ 'gh', 'pr', 'view', '--json', 'number', '-q', '.number' }, { text = true }):wait()
  if result.code ~= 0 or not result.stdout then
    return nil
  end
  local num = tonumber(vim.trim(result.stdout))
  return num
end

--- GraphQL query to fetch PR review threads with resolution status
local GRAPHQL_QUERY = [[
query($owner: String!, $repo: String!, $pr: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100, after: $cursor) {
        nodes {
          id
          isResolved
          path
          line
          comments(first: 50) {
            nodes {
              databaseId
              body
              author { login }
              createdAt
              url
              diffHunk
              replyTo { databaseId }
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
}
]]

--- Normalize GraphQL response into a consistent format
---@param threads table[] Raw threads from GraphQL API
---@return table[] normalized_comments
function M.normalize_comments(threads)
  local normalized = {}
  for _, thread in ipairs(threads) do
    local line = thread.line
    local path = thread.path
    local thread_id = thread.id
    local is_resolved = thread.isResolved

    if line and path and thread.comments and thread.comments.nodes then
      for _, c in ipairs(thread.comments.nodes) do
        table.insert(normalized, {
          id = c.databaseId,
          in_reply_to_id = type(c.replyTo) == 'table' and c.replyTo.databaseId or nil,
          path = path,
          line = line,
          body = c.body or '',
          author = c.author and c.author.login or 'unknown',
          diff_hunk = c.diffHunk or '',
          html_url = c.url or '',
          created_at = c.createdAt or '',
          thread_id = thread_id,
          is_resolved = is_resolved,
        })
      end
    end
  end
  return normalized
end

--- Fetch PR review comments asynchronously using GraphQL
---@param pr_number number PR number
---@param callback fun(comments: table[]|nil, err: string|nil)
function M.fetch_pr_comments(pr_number, callback)
  local owner, repo = M.get_repo_info()
  if not owner or not repo then
    callback(nil, 'Failed to get repository info')
    return
  end

  local all_threads = {}

  -- Recursive function to handle pagination
  local function fetch_page(cursor)
    local cmd = {
      'gh', 'api', 'graphql',
      '-f', 'query=' .. GRAPHQL_QUERY,
      '-F', 'owner=' .. owner,
      '-F', 'repo=' .. repo,
      '-F', 'pr=' .. pr_number,
    }
    if cursor then
      table.insert(cmd, '-F')
      table.insert(cmd, 'cursor=' .. cursor)
    end

    vim.system(cmd,
      { text = true },
      function(result)
        vim.schedule(function()
          if result.code ~= 0 then
            callback(nil, 'Failed to fetch PR comments: ' .. (result.stderr or 'unknown error'))
            return
          end

          local ok, response = pcall(vim.json.decode, result.stdout)
          if not ok or type(response) ~= 'table' then
            callback(nil, 'Failed to parse PR comments response')
            return
          end

          -- Check for GraphQL errors
          if response.errors then
            local err_msg = response.errors[1] and response.errors[1].message or 'GraphQL error'
            callback(nil, 'GraphQL error: ' .. err_msg)
            return
          end

          local data = response.data
          if not data or not data.repository or not data.repository.pullRequest then
            callback(nil, 'No pull request data found')
            return
          end

          local review_threads = data.repository.pullRequest.reviewThreads
          if review_threads and review_threads.nodes then
            for _, thread in ipairs(review_threads.nodes) do
              table.insert(all_threads, thread)
            end

            -- Handle pagination
            local page_info = review_threads.pageInfo
            if page_info and page_info.hasNextPage and page_info.endCursor then
              fetch_page(page_info.endCursor)
              return
            end
          end

          -- All pages fetched, normalize and return
          local normalized = M.normalize_comments(all_threads)
          callback(normalized, nil)
        end)
      end
    )
  end

  -- Start fetching from the first page
  fetch_page(nil)
end

return M
