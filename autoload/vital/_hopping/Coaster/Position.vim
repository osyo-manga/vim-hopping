scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:x = 1
let s:y = 0
let s:lnum = 0
let s:lnum = 1

function! s:_is_dict(src)
	return type(a:src) == type({})
endfunction

function! s:_is_list(src)
	return type(a:src) == type([])
endfunction

function! s:_is_number(src)
	return type(a:src) == type(0)
endfunction


function! s:is_position(src)
	return s:_is_list(a:src) && len(a:src) == 2 && s:_is_number(a:src[0]) && s:_is_number(a:src[0])
endfunction


function! s:none()
	return []
endfunction


function! s:is_none(pos)
	return !s:is_position(a:pos) || s:none() == a:pos
endfunction


function! s:new(lnum, col)
	return [a:lnum, a:col]
endfunction


function! s:new_from_list(list)
	return len(a:list) == 2 && s:is_position(a:list)      ? a:list
\		 : len(a:list) == 4 && s:is_position(a:list[1:2]) ? a:list[1:2]
\		 : s:none()
endfunction


function! s:new_from_dict(dict)
	return s:_is_number(get(a:dict, "lnum", "")) && s:_is_number(get(a:dict, "col", "")) ? s:new(a:dict.lnum, a:dict.col)
\		 : s:none()
endfunction


function! s:new_from_cursorpos(cursor)
	return a:cursor
endfunction


function! s:new_from_searchpos(searchpos)
	return a:cursor[1:2]
endfunction


function! s:as(src)
	return s:_is_list(a:src) ? s:new_from_list(a:src)
\		 : s:_is_dict(a:src) ? s:new_from_dict(a:src)
\		 : s:none()
endfunction


function! s:as_pattern(pos)
	let pos = s:as(a:pos)
	return printf('\%%%dl\%%%dc', pos[0], pos[1])
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
