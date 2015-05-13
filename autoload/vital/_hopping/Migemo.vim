scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

" Base code by haya14busa/vim-migemo
" https://github.com/haya14busa/vim-migemo


function! s:_vital_loaded(V)
	let s:Process = a:V.import("Process")
endfunction


function! s:_vital_depends()
	return [
\		"Process",
\	]
endfunction


function! s:_search_dict(name)
  let path = $VIM . ',' . &runtimepath
  let dict = globpath(path, "dict/".a:name)
  if dict == ''
    let dict = globpath(path, a:name)
  endif
  if dict == ''
    for path in [
          \ '/usr/local/share/migemo/',
          \ '/usr/local/share/cmigemo/',
          \ '/usr/local/share/',
          \ '/usr/share/cmigemo/',
          \ '/usr/share/',
          \ '/opt/boxen/homebrew/opt/cmigemo/share/cmigemo/',
          \ '/opt/boxen/homebrew/opt/cmigemo/share/',
          \ ]
      let path = path . a:name
      if filereadable(path)
        let dict = path
        break
      endif
    endfor
  endif
  let dict = matchstr(dict, "^[^\<NL>]*")
  return dict
endfunction


function! s:search_dict(...)
  for path in [
        \ 'migemo/'.&encoding.'.d/migemo-dict',
        \ &encoding.'.d/migemo-dict',
        \ 'migemo/'.&encoding.'/migemo-dict',
        \ &encoding.'/migemo-dict',
        \ 'cmigemo/'.&encoding.'/migemo-dict',
        \ 'migemo-dict',
        \ ]
    let dict = s:_search_dict(path)
    if dict != ''
      return dict
    endif
  endfor
  return get(a:, 1, "")
"   echoerr 'a dictionary for migemo is not found'
"   echoerr 'your encoding is '.&encoding
endfunction


let s:migemo_dict_ = ""
function! s:reset_migemo_dict(...)
	if a:0 > 0 && filereadable(a:1)
		let s:migemo_dict_ = a:1
	else
		let s:migemo_dict_ = s:search_dict()
	endif
endfunction
call s:reset_migemo_dict()


function! s:migemo_dict()
	return s:migemo_dict_
endfunction


function! s:set_migemo_command(cmd)
	let s:migemo_command_ = a:cmd
endfunction
call s:set_migemo_command("cmigemo")


function! s:migemo_command()
	return s:migemo_command_
endfunction


function! s:generate_migemo_command(word)
	let dict = s:migemo_dict()
	let cmd = s:migemo_command()
	return cmd . ' -v -w "' . a:word . '" -d "' . dict . '"'
endfunction


function! s:cmigemo_command(word)
	return s:generate_migemo_command(a:word)
endfunction


function! s:_cmigemo(word)
	if !executable(s:migemo_command())
		throw "vital-migemo: cmigemo is not installed."
	endif
	return s:Process.system(s:generate_migemo_command(a:word))
endfunction


function! s:_buildin_migemo(word)
	if !has("migemo")
		throw "vital-migemo: migemo is not buildin."
	endif
	let save_migemo_dict = &migemodict
	let &migemodict = s:migemo_dict()
	try
		return migemo(a:word)
	finally
		let &migemodict = save_migemo_dict
	endtry
endfunction


function! s:generate_regexp(word)
	if a:word == ""
		return ""
	endif
	if has("migemo")
		return s:_buildin_migemo(a:word)
	endif
	return s:_cmigemo(a:word)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
