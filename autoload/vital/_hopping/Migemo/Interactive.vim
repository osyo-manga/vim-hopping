scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
	let s:Process = a:V.import("Reunions.Process")
	let s:Migemo = a:V.import("Migemo")
endfunction


function! s:_vital_depends()
	return [
\		"Reunions.Process",
\		"Migemo",
\	]
endfunction


function! s:make_process()
	let process = s:Process.make_interactive(s:Migemo.migemo_command(), 'QUERY:')
	let dict = s:Migemo.migemo_dict()
	call process.start('-v -d "' . dict . '"', "\n")
	return process
endfunction


function! s:_init()
	if !executable(s:Migemo.migemo_command())
		throw "vital-migemo: cmigemo is not installed."
	endif
	if exists("s:cmigemo")
		call s:cmigemo.kill(1)
	endif
	let s:cmigemo = s:make_process()
	call s:cmigemo.wait()
endfunction


function! s:log()
	if !exists("s:cmigemo")
		return
	endif
	return s:cmigemo.log()
endfunction


function! s:generate_regexp(word)
	if !exists("s:cmigemo")
		call s:_init()
	endif
	if a:word ==# ""
		return ""
	endif
	if has("migemo")
		return s:Migemo.generate_regexp(a:word)
	endif
	call s:cmigemo.input(a:word)
	return matchstr(s:cmigemo.get(), 'PATTERN: \zs.*\ze[\r\n]$')
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
