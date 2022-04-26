" set nocompatible

syntax on
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'Yggdroot/indentLine'
Plugin 'morhetz/gruvbox'
Plugin 'zivyangll/git-blame.vim'
Plugin 'tpope/vim-surround'
Plugin 'majutsushi/tagbar'
Plugin 'preservim/nerdtree'
Plugin 'airblade/vim-gitgutter'
Plugin 'andrewradev/linediff.vim'
Plugin 'tpope/vim-fugitive'
" Plugin 'roman/golden-ratio'
Plugin 'pangloss/vim-javascript'
Plugin 'leafgarland/typescript-vim'
Plugin 'maxmellon/vim-jsx-pretty'
call vundle#end()

set wildmenu

set path+=**
set wildmenu
set encoding=utf-8
syntax on
set number
set autoindent
set tabstop=4
set shiftwidth=4
set expandtab
set ignorecase
set nowrap
set hlsearch
set mouse=a
set bs=2 " For backspace to work.
"set splitbelow
"set splitright
"set showmatch
"set matchtime=3
set backupcopy=yes

colorscheme gruvbox
set cursorline

" NERDTree
nmap <F10> :NERDTreeToggle<CR>

" https://stackoverflow.com/questions/2066590/automatically-quit-vim-if-nerdtree-is-last-and-only-buffer
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" 256 color fix:
set t_Co=256

set background=dark
set ft=nasm
