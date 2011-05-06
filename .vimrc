syntax on
set mouse=a
set hidden
set foldmethod=marker
set ruler
set nobackup
set autoindent
set smartindent
set tabstop=4
set softtabstop=4
set shiftwidth=4
set pastetoggle=<F2>
set expandtab
set number
set wildmenu
set confirm
set laststatus=2
colorscheme peachpuff

set hlsearch
set incsearch
nnoremap <silent> <C-l> :nohl<CR><C-l>

set ignorecase
set smartcase

set cursorline
hi CursorLine   cterm=NONE ctermbg=black

let mapleader = ","
nnoremap ; :
nnoremap j gj
nnoremap k gk

call pathogen#helptags()
call pathogen#runtime_append_all_bundles()
map <Leader>d :NERDTreeToggle<CR>
map <Leader>t :TlistToggle<CR>
map <Leader>r :!ctags * --exclude=Makefile<CR>
autocmd BufWritePost *.c :TlistUpdate

function! s:insert_gates()
  let gatename = substitute(toupper(expand("%:t")), "\\.", "_", "g")
  execute "normal! i#ifndef " . gatename
  execute "normal! o#define " . gatename . " "
  execute "normal! Go#endif /* " . gatename . " */"
  normal! kk
endfunction
autocmd BufNewFile *.{h,hpp} call <SID>insert_gates()

