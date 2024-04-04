require('plugins')
require('nvimtree')
require('treesitter')

-- Colors
vim.o.background = "dark"
vim.cmd([[colorscheme gruvbox]])

-- General settings
vim.opt.clipboard = 'unnamed'
vim.o.listchars = 'tab:>-,trail:٠'

vim.opt.list = true
vim.opt.autoindent = true
-- Make dashes part of word
vim.opt.lisp = true
-- Tab settings
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
-- Offset scroll from cursor
vim.opt.scrolloff = 10
-- UI Stuff
vim.opt.cursorline = true
vim.opt.ruler = true
vim.opt.title = true
vim.opt.wildmenu = true
vim.o.wildmode = 'list:longest'
vim.opt.relativenumber = true
-- History & Undo
vim.opt.history = 1000         -- remember more commands and search history
vim.opt.undolevels = 1000      -- use many muchos levels of undo
-- Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true       -- case-insensitive on lowecase only, case-sensitive when any uppercase
vim.opt.incsearch = true       -- show search matches as you type
vim.opt.showmatch = true
vim.opt.hlsearch = true
-- Linewrap settings
vim.opt.wrap = true
vim.opt.textwidth = 79
vim.opt.formatoptions = 'qrn'
-- Swap file
vim.opt.swapfile = false
-- If backupcopy is set to yes, Vim will always create the backup file by copying 
-- the original file. In this case inotifywait is able to monitor the file.
vim.opt.backupcopy = 'yes'

print("Hello World")
