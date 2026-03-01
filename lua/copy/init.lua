local M = {}

M.config = {
  path_style = 'relative', -- 'relative' (to cwd), 'absolute', or 'git_root'
}

local function get_git_root()
  local result = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if result.code ~= 0 or not result.stdout then return nil end
  return vim.trim(result.stdout)
end

local function get_file_path()
  local abs_path = vim.fn.expand('%:p')
  local style = M.config.path_style

  if style == 'absolute' then
    return abs_path
  elseif style == 'git_root' then
    local git_root = get_git_root()
    if git_root then
      return abs_path:sub(#git_root + 2)
    end
    return vim.fn.fnamemodify(abs_path, ':.')
  else
    return vim.fn.fnamemodify(abs_path, ':.')
  end
end

--
-- Copy file location to clipboard
--
function M.location(is_visual)
  local path = get_file_path()
  local location

  if is_visual then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local start_line, start_col = start_pos[2], start_pos[3]
    local end_line, end_col = end_pos[2], end_pos[3]

    -- In visual line mode, end_col is maxcol (v:maxcol); clamp to actual line length
    if end_col >= 2147483647 then
      end_col = #vim.fn.getline(end_line)
    end

    location = string.format('%s:%d:%d-%d:%d', path, start_line, start_col, end_line, end_col)
  else
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1]
    local col = cursor[2] + 1 -- convert 0-based to 1-based
    location = string.format('%s:%d:%d', path, line, col)
  end

  vim.fn.setreg('+', location)
  vim.notify('Copied: ' .. location, vim.log.levels.INFO)
end

--
-- Copy type from LSP hover to clipboard
--
function M.lsp_type()
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result)
    if err or not result or not result.contents then
      vim.notify('No type information available', vim.log.levels.WARN)
      return
    end

    -- Extract content from hover result
    local contents = result.contents
    local text
    if type(contents) == 'table' and contents.value then
      text = contents.value
    elseif type(contents) == 'string' then
      text = contents
    elseif type(contents) == 'table' and contents[1] then
      -- Take first item from array
      local item = contents[1]
      text = type(item) == 'string' and item or item.value
    end

    if not text then
      vim.notify('No type information available', vim.log.levels.WARN)
      return
    end

    -- Extract type from markdown code fence if present
    -- Pattern: ```language\ncode\n```
    local type_sig = text:match('```%w*\n(.-)```')
    if type_sig then
      text = vim.trim(type_sig)
    else
      text = vim.trim(text)
    end

    -- Copy to system clipboard
    vim.fn.setreg('+', text)
    vim.notify('Copied: ' .. text:sub(1, 50) .. (text:len() > 50 and '...' or ''), vim.log.levels.INFO)
  end)
end

return M
