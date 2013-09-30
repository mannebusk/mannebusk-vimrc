" Pathogen, to have all plugins neatly in one folder
execute pathogen#infect()
syntax on
filetype plugin indent on

" GUI OPTIONS
colorscheme monokaimanne
set guifont=Ubuntu\ Mono\ 12
set guioptions= " Remove gui elements
:set guioptions+=mTrlbL  " fix to be able to remove in one line
:set guioptions-=mTrlbL  " remove gui stuff

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
nnoremap <S-Enter> o<Esc>
nnoremap <S-BackSpace> O<Esc>

" Alternative way to get back to normal mode
inoremap jj <ESC>

" Get rid of all the crap that Vim does to be vi compatible
set nocompatible

" Use omni completion
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" Automatically cd to current project
autocmd BufEnter * ProjectRootCD

" NerdTree settings
nnoremap <C-n> :NERDTreeToggle<CR>   " Toggle NerdTree
nnoremap <leader>n :ProjectRootExe NERDTree<CR> " Open at buffers project root
nnoremap <leader>np :NERDTree /var/www/
let NERDTreeQuitOnOpen=1        " Automatically close nerdtree on file open
"autocmd BufLeave * <C-n>

" Grep settings
let Grep_Default_Options = '-rs'
autocmd BufLeave * ccl " Auto close Grep result
nnoremap <Leader>g :ProjectRootExe Grep<space>

" Grunt & Compass
nnoremap <leader>gb :ProjectRootExe !grunt --no-color build<CR>
nnoremap <leader>cb :ProjectRootExe !compass compile<CR>

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

