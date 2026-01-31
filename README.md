mannebusk-vimrc
===============

My vim setup

## Installation
Just clone it into `~/.config/nvim`

## LSP (Language Server Protocol) Setup

This configuration uses Neovim's native LSP client (available in Neovim 0.11+) with pre-configured server settings for 373+ language servers.

### Adding Support for a New Language

1. **Find the LSP server name**
   - Browse the `lsp/` directory to see all available pre-configured servers
   - Or check the official list: https://microsoft.github.io/language-server-protocol/implementers/servers/
   - Or open the cheatsheet in Neovim: `<leader>gh`

2. **Check installation instructions**
   - Each LSP config file in `lsp/` includes installation instructions in its comments
   - Example: For TypeScript, check `lsp/ts_ls.lua` for install commands

3. **Install the language server**
   - Follow the installation instructions from the config file
   - List of servers with install instructions can be found at: https://microsoft.github.io/language-server-protocol/implementers/servers/

4. **Enable in Neovim config**
   - Open `init.lua`
   - Add a line in the LSP section (around line 198):
     ```lua
     vim.lsp.enable('server_name')
     ```

5. **Verify setup**
   - Restart Neovim or `:source init.lua`
   - Open a file of the target language
   - Run `:LspInfo` to check if the server is attached

### Useful Resources
- **Cheatsheet**: Press `<leader>gh` in Neovim to view LSP keymaps and links
- **LSP Config Files**: Browse `lsp/` directory (373 pre-configured servers)
