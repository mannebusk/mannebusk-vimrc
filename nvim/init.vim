let g:polyglot_disabled = ['elm']
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

"""
" Plug Settings
"""
call plug#begin('~/.local/share/nvim/plugged')
Plug 'mattn/emmet-vim'
Plug 'tomtom/tcomment_vim'
Plug 'editorconfig/editorconfig-vim'
Plug 'itchyny/lightline.vim'
Plug 'morhetz/gruvbox'
Plug 'sheerun/vim-polyglot'
" Elixir
Plug 'elixir-lang/vim-elixir'
" Elm
Plug 'andys8/vim-elm-syntax'
" Webassembly
Plug 'rhysd/vim-wasm'
" Purescript
Plug 'purescript-contrib/purescript-vim'
" Rescript
Plug 'rescript-lang/vim-rescript'
" Roc
Plug 'ChrisWellsWood/roc.vim'
" Gleam
Plug 'gleam-lang/gleam.vim'
" Go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
" Coc
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" FZF
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
" NvimTree
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'
" Co-pilot
Plug 'github/copilot.vim'
call plug#end()

"""
" Leader Key
""
let mapleader="'"
let maplocalleader = ","




"""
" Colors & Fonts
""
set termguicolors
set background=dark    " Setting dark mode
let g:gruvboc_italic = 1
let g:gruvbox_italicize_comments = 1
let g:gruvbox_italicize_strings = 1
colorscheme gruvbox




"""
" Terminal Settings
""
tnoremap <Esc> <C-\><C-n>




"""
" NvimTree
""
lua << EOF
-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

-- empty setup using defaults
require("nvim-tree").setup()

-- OR setup with some options
require("nvim-tree").setup({
  sort_by = "case_sensitive",
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
})
EOF

nnoremap <silent> <C-n> :NvimTreeToggle<CR>
nnoremap <silent> <C-b> :NvimTreeFindFile<CR>




"""
" FZF
""

nnoremap <leader>f :Files<CR>
nnoremap <leader>l :Lines<CR>
nnoremap <leader>g :GGrep<CR>
command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number -- '.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)




"""
" Emmet
""
imap <leader>e <C-y>,


"""
" Vim Go
""
let g:go_def_mapping_enabled = 0


"""
" Coc
""

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" autocmd FileType rescript nnoremap <silent> <buffer> <localleader>f :RescriptFormat<CR>
autocmd FileType rescript nnoremap <silent> <buffer> <localleader>t :RescriptTypeHint<CR>
autocmd FileType rescript nnoremap <silent> <buffer> <localleader>b :RescriptBuild<CR>
" autocmd FileType rescript nnoremap <silent> <buffer> <localleader>j :RescriptJumpToDefinition<CR>
" autocmd FileType rescript nnoremap <silent> <buffer> <localleader>. :call CocActionAsync('doHover')<cr>

nnoremap <silent> <buffer> <localleader>f :call CocAction('format')<CR>
nnoremap <silent> <buffer> <localleader>j :call CocActionAsync('jumpDefinition')<CR>
nnoremap <silent> <buffer> <localleader>jt :call CocActionAsync('jumpTypeDefinition')<CR>
nnoremap <silent> <buffer> <localleader>ju :call CocActionAsync('jumpUsed')<CR>
nnoremap <silent> <buffer> <localleader>. :call CocActionAsync('doHover')<cr>
nnoremap <silent> <buffer> <localleader>r :call CocActionAsync('rename')<CR>
nnoremap <silent> <buffer> <localleader>rf :call CocActionAsync('refactor')<CR>
nnoremap <silent> <buffer> <localleader>a :call CocActionAsync('codeAction')<CR>
nnoremap <silent> <buffer> <localleader>i :call CocActionAsync('references')<CR>

inoremap <silent><expr> <Down>
      \ coc#pum#visible() ? coc#pum#next(1): "\<Down>"
inoremap <silent><expr> <Up>
      \ coc#pum#visible() ? coc#pum#prev(1): "\<Up>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')



"""
" TComment
""
autocmd FileType rescript call tcomment#type#Define('rescript', '// %s')



"""
" NAVIGATION SETTINGS
""
" Disable arrow keys
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>




"""
" Clipboard registry settings
""
if has("unix")
    let s:uname = substitute(system("uname -s"), '\n', '', '')
    if s:uname == 'Darwin'
        set clipboard=unnamed    " Use system clipboard registry (OS X)
    else
        set clipboard=unnamedplus   " Use system clipboard registry (Ubuntu)
    endif
endif




"""
" Syntastic
""
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1




"""
" Lightline
""
let g:lightline = {
      \ 'colorscheme': 'gruvbox',
      \ }


" Tab settings for Rescript files
autocmd FileType rescript setlocal ts=2 sw=2 expandtab

" Tab settings for Js/typescript files
autocmd FileType javascript setlocal ts=2 sw=2 expandtab
autocmd FileType typescript setlocal ts=2 sw=2 expandtab




"""
" General Settings
""
" Show whitespaces
set listchars=tab:>-,trail:٠
set list
" Indentation
set autoindent
" Make dashes part of word
set lisp
" Tab settings
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
" Offset scroll from cursor
set scrolloff=10
" UI Stuff
set cursorline
set ruler
set title
set wildmenu
set wildmode=list:longest
set relativenumber
" History & Undo
set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
" Searching
set ignorecase
set smartcase       " case-insensitive on lowecase only, case-sensitive when any uppercase
set incsearch       " show search matches as you type
set showmatch
set hlsearch
" Linewrap settings
set wrap
set textwidth=79
set formatoptions=qrn
" Swap file
set noswapfile
" If backupcopy is set to yes, Vim will always create the backup file by copying 
" the original file. In this case inotifywait is able to monitor the file.
set backupcopy=yes
