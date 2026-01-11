vim.api.nvim_create_user_command('LspKeys', function()
  local lines = {
    "=== LSP Keymaps ===",
    "",
    "Navigation:",
    "  gd          - Go to definition",
    "  <C-]>       - Jump to definition (tagfunc)",
    "  <C-t>       - Jump back",
    "",
    "LSP Actions:",
    "  grr         - Show references",
    "  gra         - Code actions",
    "  grn         - Rename symbol",
    "  gri         - Implementation",
    "  gf          - Format file",
    "  gO          - Document symbols",
    "  K           - Hover documentation",
    "  <C-s>       - Signature help (insert mode)",
    "",
    "Diagnostics:",
    "  ]d          - Next diagnostic",
    "  [d          - Previous diagnostic",
    "  ]D          - Last diagnostic",
    "  [D          - First diagnostic",
    "  <C-w>d      - Show diagnostic float",
    "",
    "Resources:",
    "  https://microsoft.github.io/language-server-protocol/implementors/servers/",
    "  (Press gx to open link)",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  local width = 50
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = 'minimal',
    border = 'rounded',
    title = ' LSP Keymaps ',
    title_pos = 'center',
  })

  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf })
  vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', { buffer = buf })
end, {})

-- Bind it to a key
vim.keymap.set('n', '<leader>gh', '<cmd>LspKeys<cr>', { desc = 'Show LSP keymaps' })
