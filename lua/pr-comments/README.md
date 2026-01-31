# pr-comments

GitHub PR review comments integration for Neovim.

## Requirements

- [GitHub CLI](https://cli.github.com/) (`gh`) - authenticated
- Neovim with Lua support

## Setup

```lua
require('pr-comments').setup({
  keymap = '<leader>pc',    -- Preview comment at cursor (default)
  show_resolved = false,    -- Hide resolved comments (default)
})
```

## Usage

1. Run `:PRComments` to fetch comments (auto-detects PR or prompts)
2. Navigate quickfix list with `:cnext`/`:cprev`
3. Press `<leader>pc` on a commented line to preview
4. In preview window: `r` to reply, `x` to resolve, `gx` to open in browser
5. `q` or `<Esc>` to close preview

## Commands

| Command | Description |
|---------|-------------|
| `:PRComments [pr]` | Fetch and display PR comments |
| `:PRCommentShow` | Show comment at cursor in floating window |
| `:PRCommentReply` | Reply to comment at cursor |
| `:PRCommentsClear` | Clear all PR comment data |
| `:PRCommentsToggleResolved` | Toggle resolved comments visibility |
| `:PRCommentsShowResolved` | Show resolved comments |
| `:PRCommentsHideResolved` | Hide resolved comments |

## Preview Window Keymaps

| Key | Action |
|-----|--------|
| `q` / `<Esc>` | Close preview |
| `r` | Reply to thread |
| `x` | Resolve/unresolve thread |
| `gx` | Open in browser |
