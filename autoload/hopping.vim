scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let g:hopping#debug_vital = get(g:, "hopping#debug_vital", 0)
let g:hopping#enable_migemo = get(g:, "hopping#enable_migemo", 0)


" http://d.hatena.ne.jp/thinca/20131104/1383498883
" {range}s/{pattern}/{string}/{flags}
function! s:parse_substitute(word)
	let very_magic   = '\v'
	let range        = '(.{-})'
	let command      = 's%[ubstitute]'
	let first_slash  = '([\x00-\xff]&[^\\"|[:alnum:][:blank:]])'
	let pattern      = '(%(\\.|.){-})'
	let second_slash = '\2'
	let string       = '(%(\\.|.){-})'
	let flags        = '%(\2([&cegiInp#lr]*))?'
	let parse_pattern
\		= very_magic
\		. '^:*'
\		. range
\		. command
\		. first_slash
\		. pattern
\		. '%('
\		. second_slash
\		. string
\		. flags
\		. ')?$'
	let result = matchlist(a:word, parse_pattern)[1:5]
	if type(result) == type(0) || empty(result)
		return []
	endif
	unlet result[1]
	return result
endfunction

function! s:silent_undo()
	let pos = getpos(".")
	redir => _
	silent undo
	redir END
	call setpos(".", pos)
endfunction


function! s:silent_substitute(range, pattern, string, flags)
	try
		let flags = substitute(a:flags, 'c', '', "g")
		let old_pos = getpos(".")
		let old_search = @/
		let check = b:changedtick
		silent execute printf('%ss/%s/%s/%s', a:range, a:pattern, a:string, flags)
		call histdel("search", -1)
" 		let &l:modified = s:old_modified
	catch /\v^Vim%(\(\a+\))=:(E121)|(E117)|(E110)|(E112)|(E113)|(E731)|(E475)|(E15)/
		if check != b:changedtick
			call s:silent_undo()
		endif
		return 1
	catch
	finally
		call setpos(".", old_pos)
		let @/ = old_search
	endtry
	return check != b:changedtick
endfunction


function! hopping#load_vital()
	if exists("s:V")
		return s:V
	endif
	if g:hopping#debug_vital
		let s:V = vital#of("vital")
	else
		let s:V = vital#of("hopping")
	endif
	call s:V.unload()

	let s:Rocker = s:V.import("Unlocker.Rocker")
	let s:Holder = s:V.import("Unlocker.Holder")
	let s:Highlight = s:V.import("Coaster.Highlight")
	let s:Position = s:V.import("Coaster.Position")
	let s:Commandline  = s:V.import("Over.Commandline")
	let s:Modules  = s:V.import("Over.Commandline.Modules")
	let s:Migemo  = s:V.import("Migemo.Interactive")

	return s:V
endfunction


function! hopping#vital()
	return s:V
endfunction



function! hopping#reload_vital()
	unlet! s:V
	let s:V = hopping#load_vital()
endfunction
call hopping#load_vital()


function! s:on_search_pattern(pat, ...)
	let @/ = a:pat
	set hlsearch

	let pos = get(a:, 1, getpos("."))
	if a:pat == ""
		call s:Highlight.clear("search")
	else
		call s:Highlight.highlight("search", "Search", a:pat)
	endif
	call s:Highlight.highlight("cursor", "Cursor", s:Position.as_pattern(pos))
endfunction


let s:filter = {
\	"name" : "IncFilter",
\	"buffer" : hopping#buffer#make()
\}


function! s:filter.update_filter(pat)
	let filtering_pat = a:pat
	let search_pat = self.buffer.convert_search_pattern(a:pat)

	if filtering_pat != ""
		try
			call searchpos(search_pat, "c")
		catch /^Vim\%((\a\+)\)\=:E54/
			return
		endtry
	endif

	if  self.buffer.draw_with_filtering(filtering_pat) == 0
		call self.buffer.restore()
	endif

	call s:on_search_pattern(search_pat, getpos("."))
endfunction


let s:hl_mark_begin = ''

let s:hl_mark_center = ''
let s:hl_mark_end   = ''


function! s:filter.substitute_preview(range, pattern, string, flags)
	let pattern = self.buffer.convert_search_pattern(a:pattern)
	let string = a:string
	if string =~ '^\\=.\+'
		" \="`os`" . submatch(0) . "`om`" . (submatch(0)) . "`oe`"
		let hl_submatch = printf('\\="%s" . submatch(0) . "%s" . (', s:hl_mark_begin, s:hl_mark_center)
		let string = substitute(string, '^\\=\ze.\+', hl_submatch, "") . ') . "' . s:hl_mark_end . '"'
	else
		let string = s:hl_mark_begin . '\0' . s:hl_mark_center . string . s:hl_mark_end
	endif
	return s:silent_substitute(a:range, pattern, string, a:flags)
endfunction


function! s:filter.update(input)
	call s:Highlight.clear("search")

	let substitute = s:parse_substitute("%s/" . a:input)
	let input = substitute[1]
	
	if get(self, "_redraw", 0)
		call self.buffer.draw(1)
	endif
	let self._redraw = 0

	if self._config.migemo
		call self.update_filter(s:Migemo.generate_regexp(input))
	else
		call self.update_filter(input)
	endif

	if substitute[2] != ""
		let self._redraw = call(self.substitute_preview, substitute, self)
		setlocal conceallevel=2
		setlocal concealcursor=n
	endif
endfunction


function! s:filter.on_char(cmdline)
	let input = a:cmdline.getline()
	if !a:cmdline.is_exit()
		call self.update(input)
	endif
endfunction


function! s:filter.on_char_pre(cmdline)
	if a:cmdline.is_input("<Over>(hopping-next)")
		silent! normal! n
		call a:cmdline.setchar("")
		let self.is_stay = 1
	endif
	if a:cmdline.is_input("<Over>(hopping-prev)")
		silent! normal! N
		call a:cmdline.setchar("")
		let self.is_stay = 1
	endif
	if a:cmdline.is_input("\<A-r>")
		redraw
		execute "normal" input(":normal ")
		call a:cmdline.setchar("")
	endif
endfunction


function! s:filter.on_execute_pre(cmdline)
	let self.is_execute = 1
	call self.locker.unlock()
	if self.is_stay
		let pos = self.buffer.get_unpack_pos()
		call cursor(pos[0], pos[1])
	else
		call self.view.unlock()
	endif
endfunction


function! s:filter.on_enter(cmdline)
	let hl_f = "syntax match %s '%s' conceal containedin=.*"
" 	execute printf(hl_f, "HoppingSubstituteHiddenBegin", s:hl_mark_begin)
	execute printf(hl_f, "HoppingSubstituteHiddenCenter", s:hl_mark_center)
	execute printf(hl_f, "HoppingSubstituteHiddenEnd", s:hl_mark_end)

	let string  = s:hl_mark_center . '\zs\_.\{-}\ze' . s:hl_mark_end
" 	call s:Highlight.highlight("SubString", g:over#command_line#substitute#highlight_string, string, 100)
	call s:Highlight.highlight("SubString", "Error", string, 100)

	let self._config = a:cmdline._config

	let self.view = s:Rocker.lock(s:Holder.make("Winview"))
	let self.is_stay = 0
	let self.locker = s:Rocker.lock(
\		"&l:modifiable",
\		"&l:cursorline",
\		"&l:number",
\		"&listchars",
\		"&hlsearch",
\		"&l:conceallevel",
\		"&l:concealcursor",
\		"@/",
\	)
	nohlsearch
	let &l:modifiable = 1
	let &l:cursorline = 1

	call self.buffer.start(self._config.firstline, self._config.lastline)
	if self.buffer.show_number
		call s:Highlight.highlight('linenr', "LineNR", '^\s*\d\+ ')
		let &l:number = 0
		let &listchars = substitute(&listchars, 'trail:.,\?', "", "g")
		let &listchars = substitute(&listchars, 'eol.,\?', "", "g")
	endif

	call self.update(a:cmdline.getline())
endfunction


function! s:filter.on_leave(cmdline)
	call s:Highlight.clear_all()
	call self.locker.unlock()

	if a:cmdline.exit_code() != 0
		call self.view.unlock()
	endif
endfunction


function! s:make_incfilter(config)
	let module = deepcopy(s:filter)
	let module.config = a:config
	return module
endfunction


let s:cmdline = s:Commandline.make_standard("Input:> ")

function! s:cmdline.__execute__(cmd)
	let substitute = s:parse_substitute("%s/" . a:cmd)
		execute printf("%d,%ds/%s", self._config.firstline, self._config.lastline, a:cmd)
		return
	endif
	if self.get_module("IncFilter").is_stay == 0
		call search(a:cmd, "c")
		call histadd("/", a:cmd)
	endif
endfunction

call s:cmdline.disconnect("HistAdd")
call s:cmdline.connect("LockBuffer")
call s:cmdline.connect("Scroll")
call s:cmdline.connect(s:Modules.make("History", "/"))


let g:hopping#keymapping = get(g:, "hopping#keymapping", {})
function! s:cmdline.keymapping(...)
	return g:hopping#keymapping
endfunction


let g:hopping#prompt = get(g:, "hopping#prompt", "Input:> ")

function! s:default_config(...)
	let base = get(a:, 1, {})
	return extend({
\		"prompt" : g:hopping#prompt,
\		"migemo" : g:hopping#enable_migemo,
\		"input"  : "",
\		"firstline" : 1,
\		"lastline"  : line("$"),
\	}, base)
endfunction


function! s:start(config)
	let s:cmdline._config = a:config
	call s:cmdline.set_prompt(a:config.prompt)
	call s:cmdline.connect(s:make_incfilter(a:config))
	let exit_code = s:cmdline.start(a:config.input)
	return exit_code
endfunction


function! hopping#start(...)
	let config = get(a:, 1, {})
	return s:start(s:default_config(config))
endfunction


let &cpo = s:save_cpo
