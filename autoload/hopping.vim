scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let g:hopping#debug_vital = get(g:, "hopping#debug_vital", 0)


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

	let s:U = s:V.import("Unlocker.Rocker")
	let s:H = s:V.import("Unlocker.Holder")
	let s:Highlight = s:V.import("Coaster.Highlight")
	let s:Position = s:V.import("Coaster.Position")
	let s:Commandline  = s:V.import("Over.Commandline")
	let s:L = s:V.import("Data.List")

	return s:V
endfunction


function! hopping#reload_vital()
	unlet! s:V
	let s:V = hopping#load_vital()
endfunction
call hopping#load_vital()



let s:text = {}

function! s:text.filter(pat)
	if has_key(self, "__prev_pat") && stridx(a:pat, self.__prev_pat) == 0
		let src = self.__prev_text
	else
		let src = self.__text
	endif
	let self.__prev_pat = a:pat
	let self.__prev_text = filter(copy(src), "v:val.line =~ a:pat")
	return self.__prev_text
endfunction


function! s:text.base_lnum(lnum)
	if has_key(self, "__prev_text")
		return get(self.__prev_text, a:lnum-1, { "lnum" : a:lnum }).lnum
	endif
	return a:lnum
endfunction


function! s:text.comp_lnum(a, b)
	return a:a - a:b.lnum
endfunction


function! s:text.pack(pat, cursor)
	let pos = a:cursor
	let pos[0] = self.base_lnum(pos[0])
	let text = self.filter(a:pat)
	let pos[0] = s:L.binary_search(text, pos[0], self.comp_lnum, self) + 1
	return [pos, text]
endfunction


function! s:text.unpack(cursor)
	if !exists("self.__prev_text")
		return [a:cursor, self.__text]
	endif
	let pos = a:cursor
	let pos[0] = self.base_lnum(pos[0])
	unlet self.__prev_text
	return [pos, self.__text]
endfunction


function! s:make_text(text)
	let result = deepcopy(s:text)
	let result.__text = a:text
	let result.__text = map(a:text, '{ "line" : v:val, "lnum" : v:key+1 }')
" 	let result.__text = {}
" 	for i in range(len(a:text))
" 		let result.__text[ printf("%06d", i) ] = a:text[i]
" 	endfor
	return result
endfunction



let s:filter = {
\	"name" : "IncFilter"
\}


function! s:filter.set_buffer_text(text)

	silent % delete _
	if self.number
		let format = "%". (max([len(self.buffer_lnum), &l:numberwidth])-1). "d %s"
		call setline(1, map(copy(a:text), "printf(format, v:val.lnum, v:val.line)"))
	else
		call setline(1, map(copy(a:text), "v:val.line"))
	endif
" 	call self.buffer.set(a:text)

	let &modified = 0
endfunction


function! s:filter.highlight(pat, pos)
	if a:pat == ""
		call s:Highlight.clear("search")
	else
		call s:Highlight.highlight("search", "Search", a:pat)
	endif
	call s:Highlight.highlight("cursor", "Cursor", s:Position.as_pattern(a:pos))
endfunction


function! s:filter.update(pat)
	call s:Highlight.clear("search")
	nohlsearch
	
	if a:pat != ""
		try
			call searchpos(a:pat, "c")
		catch /^Vim\%((\a\+)\)\=:E54/
			return
		endtry
		let @/ = a:pat
	endif

	let pos = s:Position.as(getpos("."))
	let [pos, text] = self.buffer_packer.pack(a:pat, pos)

	if empty(text)
		let text = self.buffer_packer.__text
	endif

	" 連続して絞り込む場合はバッファを更新しない
	if (has_key(self, "__prev_pat") && stridx(a:pat, self.__prev_pat) == 0)
\	&& line(".") == len(text)
	else
		call self.set_buffer_text(text)
	endif
	let self.__prev_pat = a:pat

	if a:pat == ""
		call self.view.relock()
	else
		call cursor(pos[0], pos[1])
	endif

	call self.highlight(a:pat, pos)

" 	call self.highlight(a:pat, getpos("."))
endfunction


function! s:filter.on_char_pre(cmdline)
	if a:cmdline.is_input("\<A-n>")
		silent! normal! n
		call a:cmdline.setchar("")
		let self.is_stay = 1
	endif
	if a:cmdline.is_input("\<A-p>")
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


function! s:filter.on_char(cmdline)
	let input = a:cmdline.getline()
	if !a:cmdline._is_exit()
" 	if a:cmdline.char() != ""
		call self.update(input)
	endif
endfunction


function! s:filter.on_execute_pre(cmdline)
	let self.is_execute = 1
	if self.is_stay
		call a:cmdline.setline("")
		let pos = s:Position.as(getpos("."))
		let [pos, text] = self.buffer_packer.unpack(pos)
		call self.set_buffer_text(text)
		call cursor(pos[0], pos[1])
	endif
endfunction


function! s:filter.on_enter(cmdline)
	let self.buffer = s:H.make("Buffer.Text", "%")

	let self.buffer_lnum = line("$")

	let self.view = s:U.lock(s:H.make("Winview"))
	let self.buffer_packer = s:make_text(self.buffer.get())
	let self.is_stay = 0
	let self.locker = s:U.lock(
\		self.buffer,
\		"&l:modified",
\		"&l:modifiable",
\		"&l:cursorline",
\		"&l:number",
\		"&listchars",
\		"@/",
\		s:H.make("Buffer.Undofile"),
\	)
	let &l:modifiable = 1
	let &l:cursorline = 1

	let self.number = &l:number
	if self.number
		call s:Highlight.highlight('linnr', "LineNR", '^\s\+\d\+ ')
		let &l:number = 0
		let &listchars = substitute(&listchars, 'trail:.,\?', "", "g")
		call self.set_buffer_text(self.buffer_packer.__text)
	endif

	call self.update(a:cmdline.getline())
endfunction


function! s:filter.on_leave(cmdline)
	call s:Highlight.clear_all()
	let [pos, text] = self.buffer_packer.unpack(getpos("."))
	call self.locker.unlock()
	if self.is_stay == 0
		call self.view.unlock()
	endif
endfunction


let s:cmdline = s:Commandline.make_standard_search("Input:> ")
call s:cmdline.connect(s:filter)


let g:hopping#prompt = get(g:, "hopping#prompt", "Input:> ")

function! s:start(config)
	call s:cmdline.set_prompt(a:config.prompt)
	let exit_code = s:cmdline.start(a:config.input)
	return exit_code
endfunction


function! hopping#start(...)
	return s:start({
\		"prompt" : g:hopping#prompt,
\		"input"  : get(a:, 1, "")
\	})
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
