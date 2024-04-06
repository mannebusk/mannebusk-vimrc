-- set termguicolors to enable highlight groups
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
