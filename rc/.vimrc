
set ignorecase
syntax on

set number

set softtabstop=4 
set tabstop=4 
set shiftwidth=4 
set expandtab 
set autochdir

set cpoptions+=>

syntax match Tab /\t/
hi Tab gui=underline guifg=blue ctermbg=blue 

" colorscheme github
" colorscheme solarized8 " https://github.com/lifepillar/vim-solarized8
colorscheme slate

set background=dark " light

set hlsearch
set incsearch
set showmatch

let g:netrw_liststyle= 4

" press enter (aka <CR>) to stop highlighting (aka :noh) after searching
nnoremap <CR> :noh<CR><CR>
" attribution: http://stackoverflow.com/a/1037182/472876
" nnoremap <esc> :noh<return><esc>

" good colorscheme for markdown files: delek
"
"

"""""""
" highlighting changes..
" change Search and IncSearch guibg from #cdcdfd , to below.
hi Search guibg=#f6c427
hi IncSearch guibg=#f6c427

filetype plugin indent on

set ruler
""""""""""""""""""""""""""""""
" Pathogen
""""""""""""""""""""""""""""""
execute pathogen#infect()

" CTRLP
" https://github.com/kien/ctrlp.vim
set wildignore+=*/tmp/*,*.so,*.dylib,*.swp,*.zip,*.gz,*.tar,*.class,*.pyc,*swo,*orig
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_regexp = 0



" Populate the @t register 
let @t = "import ipdb; ipdb.set_trace()"

" Make quick silver from github used by ctrlp 
if executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
  let g:ctrlp_use_caching = 0
endif


" syntax highlighting in code fences, https://www.reddit.com/r/vim/comments/fk48jw/markdown_code_syntax_highlighting/
let g:markdown_fenced_languages = ['python']

