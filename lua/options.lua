local augroup = vim.api.nvim_create_augroup -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd -- Create autocommand

vim.g.mapleader = "'"
vim.g.maplocalleader = ","

-- General settings
vim.opt.clipboard = 'unnamed'
vim.o.listchars = 'tab:>-,trail:٠'
vim.opt.list = true
vim.opt.autoindent = true

-- Tab settings
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.scrolloff = 10 -- Offset scroll from cursor

-- Set indentation to 2 spaces
augroup('setIndent', { clear = true })
autocmd('Filetype', {
  group = 'setIndent',
  pattern = { 'css', 'html', 'javascript', 'javascriptreact',
    'lua', 'markdown', 'md', 'typescript', 'typescriptreact',
    'scss', 'xml', 'xhtml', 'yaml', 'gleam', 'rescript'
  },
  command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2'
})

-- History & Undo
vim.opt.history = 1000    -- remember more commands and search history
vim.opt.undolevels = 1000 -- use many muchos levels of undo

-- Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true -- case-insensitive on lowecase only, case-sensitive when any uppercase
vim.opt.lisp = true      -- Make dashes part of word
vim.opt.incsearch = true -- show search matches as you type
vim.opt.showmatch = true
vim.opt.hlsearch = true

-- Linewrap settings
vim.opt.wrap = true
vim.opt.textwidth = 79
vim.opt.formatoptions = 'qrn'

-- Swap file
vim.opt.swapfile = false
vim.opt.backupcopy =
'yes' -- If backupcopy is set to yes, Vim will always create the backup file by copying the original file. In this case inotifywait is able to monitor the file.

-- UI Stuff
vim.opt.cursorline = true
vim.opt.ruler = true
vim.opt.title = true
vim.opt.wildmenu = true
vim.o.wildmode = 'list:longest'
vim.opt.relativenumber = true

-- Colors
vim.opt.termguicolors = true
require('onenord').setup()
