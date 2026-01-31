-- Configuration management commands

-- Command to open init.lua in a new tab with NvimTree at config root
vim.api.nvim_create_user_command('ConfigEdit', function()
  local config_path = vim.fn.stdpath('config') .. '/init.lua'
  local config_dir = vim.fn.stdpath('config')

  -- Create new tab with init.lua
  vim.cmd('tabnew ' .. config_path)

  -- Open NvimTree at config directory root in this tab only
  local api = require("nvim-tree.api")
  api.tree.open({
    path = config_dir,           -- Open at config root
    current_window = false,      -- Open in new split (not in current window)
    find_file = true,            -- Highlight init.lua in the tree
    update_root = false,         -- Don't affect other tabs
  })
end, { desc = 'Open init.lua in a new tab with NvimTree' })

-- Command to reload configuration
vim.api.nvim_create_user_command('ConfigReload', function()
  local config_path = vim.fn.stdpath('config') .. '/init.lua'
  vim.cmd('source ' .. config_path)
  print('Configuration reloaded!')
end, { desc = 'Reload configuration by sourcing init.lua' })
