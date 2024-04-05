require('options')
require('plugins')
require('plugins.lualine')
require('plugins.nvimtree')
require('plugins.treesitter')
require('plugins.comment')
require('plugins.cmp')
require('plugins.lsp-zero')
require('plugins.telescope')

-- Colors
vim.opt.termguicolors = true
require('onenord').setup()


print("Hello myself!")
