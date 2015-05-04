scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
	let s:V = a:V
	let s:Rocker = s:V.import("Unlocker.Rocker")
	let s:Holder = s:V.import("Unlocker.Holder")
	let s:Undo = s:V.import("Unlocker.Rocker.Undotree")
endfunction


function! s:_vital_depends()
	return [
\		"Unlocker.Rocker",
\		"Unlocker.Rocker.Undotree",
\		"Unlocker.Holder",
\	]
endfunction




let s:module = {
\	"name" : "LockBuffer"
\}


function! s:module.on_enter(...)
	let self.__locker = s:Rocker.lock(
\		s:Holder.make("Buffer.Text", "%"),
\		"&l:modified",
\		s:Undo.make()
\	)
endfunction


function! s:module.on_execute_pre(...)
	call self.__locker.unlock()
endfunction


function! s:module.on_leave(...)
	call self.__locker.unlock()
endfunction


function! s:make()
	return deepcopy(s:module)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
