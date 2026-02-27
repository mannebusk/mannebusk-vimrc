-- Configuration management commands

-- Command to open init.lua in a new tab with mini.files
vim.api.nvim_create_user_command('ConfigEdit', function()
  local config_path = vim.fn.stdpath('config') .. '/init.lua'

  vim.cmd('e' .. config_path)
end, { desc = 'Open init.lua in a new tab with mini.files' })

-- Command to reload configuration
vim.api.nvim_create_user_command('ConfigReload', function()
  local config_path = vim.fn.stdpath('config') .. '/init.lua'
  vim.cmd('source ' .. config_path)
  print('Configuration reloaded!')
end, { desc = 'Reload configuration by sourcing init.lua' })
