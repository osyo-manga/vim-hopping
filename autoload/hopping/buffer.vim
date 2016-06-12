scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:List = hopping#vital().import("Data.List")
let s:Position = hopping#vital().import("Coaster.Position")


let s:text = {}

function! s:text.filter(pat)
	if has_key(self, "__prev_pat") && stridx(a:pat, self.__prev_pat) == 0
		let src = self.__prev_text
	else
		let src = self.__text
	endif
	let self.__prev_pat = a:pat
	let pat = a:pat
	try
		let self.__prev_text = filter(copy(src), "v:val.line =~ pat")
	catch /^Vim\%((\a\+)\)\=:E866/
	endtry
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
	let pos[0] = s:List.binary_search(text, pos[0], self.comp_lnum, self) + 1
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
	let result.__text = map(a:text, '{ "line" : v:val, "lnum" : v:key+1 }')
	return result
endfunction


let s:buffer = {}

function! s:buffer.__init(first, last)
	let self.packer = s:make_text(getline(a:first, a:last))
	let self.draw_text = self.packer.__text
	let self.buffer_lnum = line("$")
	let self.lnum_offset = a:first - 1
	let self.col_offset = 0
	let self.show_number = &l:number
	if self.show_number
		let self.col_offset = max([strlen(self.buffer_lnum), &l:numberwidth])
	endif
	call self.setpos(getpos("."))
	let self.view = winsaveview()
endfunction


function! s:buffer.start(...)
	let firstline = get(a:, 1, 1)
	let lastline  = get(a:, 2, '$')
	call self.__init(firstline, lastline)
	if self.show_number
		call self.draw(1)
		call self.setpos([line("."), col(".") + self.col_offset])
	endif
	let self.start_view = winsaveview()
endfunction


function! s:buffer.filtering(pat)
	let pos = s:Position.as(getpos("."))
	let [pos, text] = self.packer.pack(a:pat, pos)
	if empty(text) || a:pat == ""
		return 0
	endif
	call self.setpos(pos)
	let self.draw_text = text
	return len(text)
endfunction


function! s:buffer.restore()
	let self.draw_text = self.packer.__text
	call self.draw()
	call winrestview(self.start_view)
endfunction


function! s:buffer.get_unpack_pos()
	let [pos, text] = self.packer.unpack(self.pos)
	return [pos[0] + self.lnum_offset, pos[1] - self.col_offset]
endfunction


function! s:buffer.setpos(pos)
	let pos = s:Position.as(a:pos)
	call cursor(pos[0], pos[1])
	let self.pos = pos
endfunction


function! s:buffer.text()
	return self.draw_text
endfunction


function! s:buffer.set_buffer_text(text)
	let pos = getpos(".")
	silent % delete _
	if self.show_number
		let format = "%". (self.col_offset - 1). "d %s"
		call setline(1, map(copy(a:text), "printf(format, v:val.lnum + self.lnum_offset, v:val.line == '' ? ' ' : v:val.line)"))
	else
		call setline(1, map(copy(a:text), "v:val.line"))
	endif
	call cursor(pos[1], pos[2])

	let &modified = 0
endfunction


function! s:buffer.draw(...)
	let force = get(a:, 1, 0)

	let text = self.text()
	if line("$") == self.buffer_lnum && self.buffer_lnum == len(text)
\	&& force == 0
		return
	endif
	call self.set_buffer_text(text)
	call self.setpos(self.pos)
endfunction


function! s:buffer.draw_with_filtering(pat)
	let text_size = self.filtering(a:pat)

	" 連続して絞り込む場合はバッファを更新しない
	if (has_key(self, "__prev_pat") && stridx(a:pat, self.__prev_pat) == -1)
\	|| line("$") != text_size
		if text_size
			call self.draw()
		endif
	endif
	let self.__prev_pat = a:pat
	return text_size
endfunction


function! s:buffer.convert_search_pattern(pat)
	let pat = a:pat
	let search_pat = pat
	if self.show_number && pat != ""
		if pat[0] ==# "^"
			let search_pat = '^\s*\d\+ \zs' . pat[1:]
		else
			let search_pat = '\%>' . self.col_offset . 'v' . pat
		endif
	endif
	return search_pat
endfunction


function! hopping#buffer#make()
	let buffer = deepcopy(s:buffer)
" 	call buffer.__init()
	return buffer
endfunction


function! hopping#buffer#test()
	let g:buffer = hopping#buffer#make()
	call g:buffer.start()
	call g:buffer.filtering("ma")
	call g:buffer.filtering("mado")
	call g:buffer.filtering("homu")
	call g:buffer.draw()
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
