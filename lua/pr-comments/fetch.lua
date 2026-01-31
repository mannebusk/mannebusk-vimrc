-- pr-comments/fetch.lua
-- Fetches PR review comments using gh CLI

local M = {}

--- Get repository info (owner/repo) using gh CLI
---@return string|nil owner_repo Format: "owner/repo"
function M.get_repo_info()
  local result = vim.system({ 'gh', 'repo', 'view', '--json', 'nameWithOwner', '-q', '.nameWithOwner' }, { text = true })
      :wait()
  if result.code ~= 0 or not result.stdout then
    return nil
  end
  return vim.trim(result.stdout)
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

--- Normalize raw API comments into a consistent format
---@param comments table[] Raw comments from GitHub API
---@return table[] normalized_comments
function M.normalize_comments(comments)
  local normalized = {}
  for _, c in ipairs(comments) do
    -- GitHub API returns 'line' for single-line comments, or 'original_line' for multi-line
    -- We prefer 'line' when available, fallback to 'original_line'
    local line = c.line or c.original_line
    if line and c.path then
      table.insert(normalized, {
        id = c.id,
        path = c.path,
        line = line,
        body = c.body or '',
        author = c.user and c.user.login or 'unknown',
        diff_hunk = c.diff_hunk or '',
        html_url = c.html_url or '',
        created_at = c.created_at or '',
      })
    end
  end
  return normalized
end

--- Fetch PR review comments asynchronously
---@param pr_number number PR number
---@param callback fun(comments: table[]|nil, err: string|nil)
function M.fetch_pr_comments(pr_number, callback)
  local repo = M.get_repo_info()
  if not repo then
    callback(nil, 'Failed to get repository info')
    return
  end

  local api_path = string.format('repos/%s/pulls/%d/comments', repo, pr_number)

  vim.system(
    { 'gh', 'api', api_path, '--paginate' },
    { text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          callback(nil, 'Failed to fetch PR comments: ' .. (result.stderr or 'unknown error'))
          return
        end

        local ok, comments = pcall(vim.json.decode, result.stdout)
        if not ok or type(comments) ~= 'table' then
          callback(nil, 'Failed to parse PR comments response')
          return
        end

        local normalized = M.normalize_comments(comments)
        callback(normalized, nil)
      end)
    end
  )
end

return M
