vim = vim or require('vim')


--
-- General options
--
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
vim.opt.winborder = 'rounded'

-- Colors
vim.opt.termguicolors = true
require('onenord').setup()


--
-- Packages/Plugins
--
vim.pack.add({
  { src = 'https://github.com/rmehri01/onenord.nvim' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },

  { src = 'https://github.com/nvim-tree/nvim-tree.lua' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },

  {
    src = 'https://github.com/Saghen/blink.cmp',
    version = 'v1.7.0',
    opts_extend = { "sources.default" }
  },

  { src = 'https://github.com/terrortylor/nvim-comment' },

  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope.nvim' },

  { src = 'https://github.com/rescript-lang/vim-rescript' }
})

--
-- CheatSheet windows to remember things
--
require('cheatsheet')


--
-- Configuration Commands
--
require('config')


--
-- blink.cmp (Autocomplete)
--
require('blink.cmp').setup({
  -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
  -- 'super-tab' for mappings similar to vscode (tab to accept)
  -- 'enter' for enter to accept
  -- 'none' for no mappings
  --
  -- All presets have the following mappings:
  -- C-space: Open menu or open docs if already open
  -- C-n/C-p or Up/Down: Select next/previous item
  -- C-e: Hide menu
  -- C-k: Toggle signature help (if signature.enabled = true)
  --
  -- See :h blink-cmp-config-keymap for defining your own keymap
  keymap = { preset = 'default' },

  signature = { enabled = true },

  appearance = {
    -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
    -- Adjusts spacing to ensure icons are aligned
    nerd_font_variant = 'mono'
  },

  -- (Default) Only show the documentation popup when manually triggered
  completion = { documentation = { auto_show = false } },

  -- Default list of enabled providers defined so that you can extend it
  -- elsewhere in your config, without redefining it, due to `opts_extend`
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },

  -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
  -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
  -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
  --
  -- See the fuzzy documentation for more information
  fuzzy = { implementation = "prefer_rust_with_warning" }
})


--
-- Nvim comment
--
require('nvim_comment').setup()


--
-- Telescope
--
local builtin = require('telescope.builtin')


vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})


--
-- Lualine
--
require('lualine').setup {
  options = {
    -- ... your lualine config
    theme = 'onenord'
    -- ... your lualine config
  }
}


--
-- nvim-tree
--
vim.opt.termguicolors = true

require("nvim-tree").setup({
  sort_by = "case_sensitive",
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
})

vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })
vim.keymap.set('n', '<C-b>', ':NvimTreeFindFile<CR>', { silent = true })


--
-- LSP
--
vim.lsp.enable('lua_ls')
vim.lsp.enable('ts_ls')
vim.lsp.enable('rescriptls')
vim.lsp.enable('graphql')

-- Set up the keymap when LSP attaches to a buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Set keymap for formatting
    vim.keymap.set('n', 'gf', function()
      vim.lsp.buf.format({ async = true })
    end, { buffer = ev.buf, desc = 'Format buffer' })
  end,
})


--
-- Make myself happy with a little greeting
--
print("Hello myself!")
