"""
" Plug Settings
"""
call plug#begin('~/.local/share/nvim/plugged')
Plug 'mattn/emmet-vim'
Plug 'yegappan/grep'
Plug 'scrooloose/nerdtree'
Plug 'tomtom/tcomment_vim'
Plug 'scrooloose/syntastic'
Plug 'dbakker/vim-projectroot'
Plug 'editorconfig/editorconfig-vim'
Plug 'fweep/vim-tabber'
Plug 'ervandew/supertab'
Plug 'itchyny/lightline.vim'
Plug 'morhetz/gruvbox'
Plug 'arcticicestudio/nord-vim'
Plug 'sheerun/vim-polyglot'
Plug 'garbas/vim-snipmate'
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
" Elixir
Plug 'elixir-lang/vim-elixir'
" Elm
" Plug 'elmcast/elm-vim'
Plug 'andys8/vim-elm-syntax'
" Webassembly
Plug 'rhysd/vim-wasm'
" Lisp
Plug 'guns/vim-sexp'
Plug 'guns/vim-clojure-static'
Plug 'guns/vim-clojure-highlight'
Plug 'tpope/vim-sexp-mappings-for-regular-people'
Plug 'tpope/vim-fireplace'
Plug 'tpope/vim-salve'
Plug 'kien/rainbow_parentheses.vim'
call plug#end()

" Leader Key
let mapleader="'"

"""
" Colors & Fonts
""
set termguicolors
set background=dark    " Setting dark mode
let g:gruvboc_italic = 1
let g:gruvbox_italicize_comments = 1
let g:gruvbox_italicize_strings = 1
colorscheme nord

if has("unix")
    let s:uname = substitute(system("uname -s"), '\n', '', '')
    if s:uname == 'Darwin'
        " OS X fonts
        set guifont=Andale\ Mono:h12
    else
        " Linux fonts
        set guifont=Fira\ Mono\ 9
    endif
endif

"""
" Terminal Settings
""
tnoremap <Esc> <C-\><C-n>

"""
" ProjectRootCD - Automatically cd to current project
""
augroup projectrootcd
    autocmd!
    autocmd BufEnter * ProjectRootCD
augroup END
nnoremap <leader>n :ProjectRootExe NERDTree<CR> " Open at buffers

"""
" NerdTree
""
nnoremap <C-n> :NERDTreeToggle<CR>      " Toggle NerdTree
nnoremap <leader>nf :NERDTreeFind<CR>
nnoremap <leader>no :NERDTree ~/
let NERDTreeQuitOnOpen=1        " Automatically close nerdtree on file open

"""
" Emmet
""
imap <leader>e <C-y>,

"""
" Grep
""
let Grep_Default_Options = '-rs'
augroup grep
    autocmd!
        autocmd BufLeave * ccl " Auto close Grep result
augroup END
nnoremap <Leader>g Grep<space>

"""
" SnipMate
""
let g:snipMate = {}
let g:snipMate.snippet_version = 1
let g:snipMate.description_in_completion = 1

" ELm
let g:polyglot_disabled = ['elm']

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
      \ 'colorscheme': 'nord',
      \ }


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
