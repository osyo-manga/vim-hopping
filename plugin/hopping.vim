scriptencoding utf-8
if exists('g:loaded_hopping')
  finish
endif
let g:loaded_hopping = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=*
\	HoppingStart call hopping#start(<q-args>)

map <silent> <Plug>(hopping-start) :<C-u>HoppingStart<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
