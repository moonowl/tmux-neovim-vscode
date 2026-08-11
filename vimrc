" vimrc — mouse support + OSC 52 yank, for plain vim on a remote box.
set nocompatible
syntax on
filetype plugin indent on

" --- mouse ---
set mouse=a              " click to position, scroll, drag-select
set ttymouse=sgr         " SGR mouse protocol: required for wide terminals / tmux / cmux
                         " (tip: hold Option in cmux/Ghostty or Fn/Shift in Blink to do
                         "  native terminal selection instead of vim's mouse select)

" --- sane editor defaults ---
set number
set hidden
set incsearch hlsearch
set ignorecase smartcase
set expandtab shiftwidth=2 softtabstop=2 autoindent
set scrolloff=3
set laststatus=2
set backspace=indent,eol,start
set clipboard=unnamed    " harmless on -clipboard builds; real remote copy is OSC52 below

" --- OSC52: yanks go to your LOCAL system clipboard, through tmux + cmux/Blink ---
function! s:Osc52Yank() abort
  let l:text = join(v:event.regcontents, "\n")
  if empty(l:text) | return | endif
  let l:b64 = substitute(system('base64 | tr -d "\n"', l:text), '\n', '', 'g')
  let l:seq = "\e]52;c;" . l:b64 . "\x07"
  silent! call writefile([l:seq], '/dev/tty', 'b')
endfunction
augroup Osc52Clipboard
  autocmd!
  autocmd TextYankPost * if v:event.operator ==# 'y' | call s:Osc52Yank() | endif
augroup END
