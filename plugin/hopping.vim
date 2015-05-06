scriptencoding utf-8
if exists('g:loaded_hopping')
  finish
endif
let g:loaded_hopping = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -range=%
\	HoppingStart
\	call hopping#start({ "input" : <q-args>, "firstline" : <line1>, "lastline" : <line2>})

map <silent> <Plug>(hopping-start) :HoppingStart<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
