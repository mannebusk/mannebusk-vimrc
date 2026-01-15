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
-- Enable opening links in nvim from macOS
--
require("socket")


--
-- Packages/Plugins
--
vim.pack.add({
  { src = 'https://github.com/rmehri01/onenord.nvim' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },

  { src = 'https://github.com/nvim-tree/nvim-tree.lua' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },

  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },

  {
    src = 'https://github.com/Saghen/blink.cmp',
    version = 'v1.7.0',
    opts_extend = { "sources.default" }
  },

  { src = 'https://github.com/terrortylor/nvim-comment' },

  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope.nvim' },

  { src = 'https://github.com/rescript-lang/vim-rescript' },

  { src = 'https://github.com/n1kben/gitcast.nvim' }
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
-- nvim-treesitter
--
require('nvim-treesitter').install { 'javascript', 'typescript', 'html', 'css', 'lua', 'xml', 'json', 'graphql', 'rescript', 'sql' }
vim.g.markdown_fenced_languages = { 'javascript', 'typescript', 'html', 'css', 'lua', 'xml', 'json', 'graphql', 'rescript', 'sql' }


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
  keymap = { preset = 'enter' },

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
-- GitCast
--
require('gitcast').setup()

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

    --
    -- Combined hover function that shows diagnostics and hover info together
    -- 
    local function combined_hover()
      local bufnr = vim.api.nvim_get_current_buf()
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local line = cursor_pos[1] - 1  -- 0-indexed
      local col = cursor_pos[2]

      -- Get diagnostics at the exact cursor position
      local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })
      local filtered_diags = {}
      for _, diag in ipairs(diagnostics) do
        if col >= diag.col and col <= diag.end_col then
          table.insert(filtered_diags, diag)
        end
      end

      -- Format diagnostics
      local diagnostic_lines = {}
      if #filtered_diags > 0 then
        for _, diag in ipairs(filtered_diags) do
          local severity_icon = ({
            [vim.diagnostic.severity.ERROR] = 'E',
            [vim.diagnostic.severity.WARN] = 'W',
            [vim.diagnostic.severity.INFO] = 'I',
            [vim.diagnostic.severity.HINT] = 'H',
          })[diag.severity] or '?'

          table.insert(diagnostic_lines, string.format('[%s] %s', severity_icon, diag.message))
        end
      end

      -- Request hover info
      local params = vim.lsp.util.make_position_params()
      vim.lsp.buf_request(bufnr, 'textDocument/hover', params, function(err, result)
        if err then return end

        local hover_lines = {}
        if result and result.contents then
          if #filtered_diags > 0 then
            table.insert(diagnostic_lines, '')
            table.insert(diagnostic_lines, '---')
            table.insert(diagnostic_lines, '')
          end

          local contents = result.contents
          if type(contents) == 'table' and contents.value then
            -- MarkupContent format
            hover_lines = vim.split(contents.value, '\n')
          elseif type(contents) == 'string' then
            hover_lines = vim.split(contents, '\n')
          elseif type(contents) == 'table' and contents[1] then
            -- Array of MarkedString
            for _, item in ipairs(contents) do
              local text = type(item) == 'string' and item or item.value
              vim.list_extend(hover_lines, vim.split(text, '\n'))
            end
          end
        end

        -- Combine and display
        local combined_lines = vim.list_extend(diagnostic_lines, hover_lines)
        if #combined_lines > 0 then
          vim.lsp.util.open_floating_preview(combined_lines, 'markdown', {
            border = 'rounded',
            focusable = true,
            focus = false,
            close_events = { 'CursorMoved', 'CursorMovedI', 'BufLeave' },
            syntax = "markdown",
          })
        end
      end)
    end

    --
    -- Set keymap for formatting
    --
    vim.keymap.set('n', 'gf', function()
      vim.lsp.buf.format({ async = true })
    end, { buffer = ev.buf, desc = 'Format buffer' })

    --
    -- Override K keybinding for combined hover
    --
    vim.keymap.set('n', 'K', combined_hover, { buffer = ev.buf, desc = 'Show diagnostics and hover' })
  end,
})
