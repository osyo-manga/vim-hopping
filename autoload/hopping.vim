scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let g:hopping#debug_vital = get(g:, "hopping#debug_vital", 0)
let g:hopping#enable_migemo = get(g:, "hopping#enable_migemo", 0)


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
	let search_pat = a:pat

	if self.buffer.show_number && a:pat != ""
		if a:pat[0] ==# "^"
			let search_pat = '^\s\+\d\+ \zs' . a:pat[1:]
		else
			let search_pat = '\%>' . self.buffer.col_offset . 'v' . a:pat
		endif
	endif

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


function! s:filter.update(input)
	call s:Highlight.clear("search")
	if g:hopping#enable_migemo
		call self.update_filter(s:Migemo.generate_regexp(a:input))
	else
		call self.update_filter(a:input)
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
		let self.is_stay = 1
	endif
endfunction


function! s:filter.on_enter(cmdline)
	let self.view = s:Rocker.lock(s:Holder.make("Winview"))
	let self.is_stay = 0
	let self.locker = s:Rocker.lock(
\		"&l:modifiable",
\		"&l:cursorline",
\		"&l:number",
\		"&listchars",
\		"&hlsearch",
\		"@/",
\	)
	nohlsearch
	let &l:modifiable = 1
	let &l:cursorline = 1

	call self.buffer.start()
	if self.buffer.show_number
		call s:Highlight.highlight('linenr', "LineNR", '^\s\+\d\+ ')
		let &l:number = 0
		let &listchars = substitute(&listchars, 'trail:.,\?', "", "g")
		let &listchars = substitute(&listchars, 'eol.,\?', "", "g")
	endif

	call self.update(a:cmdline.getline())
endfunction


function! s:filter.on_leave(cmdline)
	call s:Highlight.clear_all()
	call self.locker.unlock()

	if self.is_stay == 0 || a:cmdline.exit_code()
		call self.view.unlock()
	endif
endfunction


function! s:make_incfilter(config)
	let module = deepcopy(s:filter)
	let module.config = a:config
	return module
endfunction


let s:cmdline = s:Commandline.make_standard("Input:> ")

let s:execute = s:cmdline.get_module("Execute")
function! s:execute.execute(cmdline)
	if a:cmdline.get_module("IncFilter").is_stay == 0
		call a:cmdline.execute(":normal! /" . a:cmdline.getline() . "\<CR>")
	else
		call a:cmdline.execute("")
	endif
endfunction

call s:cmdline.connect("LockBuffer")
call s:cmdline.connect("Scroll")


let g:hopping#keymapping = get(g:, "hopping#keymapping", {})
function! s:cmdline.keymapping(...)
	return g:hopping#keymapping
endfunction


let g:hopping#prompt = get(g:, "hopping#prompt", "Input:> ")

function! s:start(config)
	call s:cmdline.set_prompt(a:config.prompt)
	call s:cmdline.connect(s:make_incfilter(a:config))
	let exit_code = s:cmdline.start(a:config.input)
	return exit_code
endfunction


function! hopping#start(...)
	return s:start({
\		"prompt" : g:hopping#prompt,
\		"input"  : get(a:, 1, ""),
\	})
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
