local M = {}

--
-- Copy type from LSP hover to clipboard
--
function M.copy_type()
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
