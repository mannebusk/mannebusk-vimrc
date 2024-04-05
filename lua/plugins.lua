return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    -- Nvim tree
    use 'nvim-tree/nvim-tree.lua'
    use 'nvim-tree/nvim-web-devicons'

    -- Syntax highlighting
    use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

    -- UI / Colors / Theming
    use { "ellisonleao/gruvbox.nvim" }

    -- Fuzzy finder
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.6',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    -- LSP Setup
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        requires = {
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },
            { 'neovim/nvim-lspconfig' },
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'L3MON4D3/LuaSnip' },
        }
    }
    -- Other
    use 'terrortylor/nvim-comment'

    -- Language support
    use 'rescript-lang/vim-rescript'
end)
