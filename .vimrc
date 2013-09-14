" Pathogen, to have all plugins neatly in one folder
execute pathogen#infect()
syntax on
filetype plugin indent on

colorscheme monokai
"set guifont=Emilbus\ Mono

let mapleader="'"

" Disable arrow keys
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Auto brackets
inoremap {}H {}<Esc>i
inoremap ()H ()<Esc>i
inoremap {{}}H {{}}<Esc>hhi

" New line in normal mode
nnoremap <leader>o <i>o<ESC>

" Alternative way to get back to normal mode
inoremap jj <ESC>

" Get rid of all the crap that Vim does to be vi compatible
set nocompatible

" Use omni completion
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" Toggle nerdtree
map <C-n> :NERDTreeToggle<CR>

" Auto close Grep result
autocmd BufLeave * ccl

" GUI OPTIONS
:set guioptions+=mTrlbL  " fix to be able to remove in one line
:set guioptions-=mTrlbL  " remove gui stuff

" Tab settings
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

" Navigate buffers
nnoremap <C-H> :bp<cr>
nnoremap <C-L> :bn<cr>

" Encoding
set enc=utf-8
set nobomb
set fileencoding=utf-8
set fileencodings=ucs-bom,utf8,prc

set scrolloff=10
set autoindent
set showmode
set showcmd
set number
set hidden
set wildmenu
set wildmode=list:longest
set visualbell
set cursorline
set ttyfast
set ruler
set backspace=indent,eol,start
set laststatus=2
" set undofile
set clipboard=unnamedplus   " Use system clipboard registry

set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo

" Searching
set ignorecase
set smartcase       " case-insensitive on lowecase only, case-sensitive when any uppercase
set incsearch       " show search matches as you type
set showmatch
set hlsearch

set noswapfile " Don't create swapfiles (not fun using git)

set wrap
set textwidth=79
set formatoptions=qrn

" Grep settings
let Grep_Default_Options = '-rs'
