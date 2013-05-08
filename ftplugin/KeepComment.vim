let s:CommentStringMap = { 
			\'python'    : {'left': '#'},
			\'make'      : {'left': '#'},
			\'snippet'   : {'left': '#'},
			\'cpp'       : {'left': '//'},
			\'javascript': {'left': '//'},
			\'vim'       : {'left': '"'},
			\'matlab'    : {'left': '%'},
			\'tex' 	     : {'left': '%'},
			\'txt'       : {'left': '>>'},
			\'anonymous' : {'left': '!'},
			\'c'         : {'left': '/*', 'right': '*/'},
			\'html'      : {'left': '<!--', 'right': '-->'} }

fun InsertAlterMulti(arg) range

	let save_pos = getpos('.')

	if a:arg == -1
		" visual mode operation
		let listw = []

		let line_num = [line("'<"),line("'>")]
		let listw += line_num
		let l = min(listw)
		let r = max(listw)
		let vline = r - l + 1
		" echo 'start ' . vline . ' ' . a:arg . ' ' . l . ' ' . r . ' ' . line("'<") . ' ' . line("'>")

		normal "ayy
		for i in range(1,vline-1)
			normal j"Ayy
		endfor
		normal "ap

		call Commentify(vline)

	elseif a:arg == 0
		normal yyp
		call Commentify(1)

	elseif a:arg > 0
		" bufnum mode operation
		normal "ayy
		for i in range(1,a:arg-1)
			normal j"Ayy
		endfor
		normal "ap

		call Commentify(a:arg)
	else
		echo "Not work???"
	endif

	call setpos('.',save_pos)
	if $buf.count > 0
		normal 3w
	endif

endf

fun SelectComment(arg)
	let ft = a:arg
	for key in keys(s:CommentStringMap)
		if ft == key
			return [s:CommentStringMap[ft],ft]
		endif
	endfor
	let key = 'anonymous'
	return [s:CommentStringMap[key], key]
endfun

fun! CoreExample()
	nmap x <Plug>ToggleAutoCloseMappings
	normal x
	exe 'nunmap x'
endf

let g:switched = 0
fun! WorkAroundAutoClose(arg)
	let status = a:arg
	if &ft == 'vim'
		if exists('g:autoclose_loaded')
			if g:autoclose_on && status == 'open'
				call CoreExample()
				let g:switched = !g:switched
			elseif g:switched && status == 'close'
				call CoreExample()
				let g:switched = !g:switched
			endif
		endif
	endif
endf

function Commentify(arg) range
	call WorkAroundAutoClose('open')
	let save_cursor = getpos('.')
	let visual_line = line("'>") - line("'<") + 1
	if a:arg == -1
		let cnt = visual_line
	elseif a:arg == 0
		let cnt = 1
	else
		let cnt = a:arg
	endif
	let comment = SelectComment(&ft)[0]
	let key     = SelectComment(&ft)[1]
	if len(items(s:CommentStringMap[key])) == 1
		for i in range(1,cnt)
			exe "norm I" . comment['left'] . " "
			norm j
		endfor
	else
		for i in range(1,cnt)
			exe "norm I" . comment['left'] . " "
			exe "norm A" . " " . comment['right']
			norm j
		endfor
	endif

	if a:arg <= 1
		" echo cnt .' line(s) commented!'
		let msg = cnt .' line(s) commented!' 
	else
		" echo a:arg .' line(s) commented!'
		let msg = a:arg .' line(s) commented!' 
	endif
	call setpos('.',save_cursor)
	if a:arg == 0 || a:arg == 1
		" pass
	else
		normal www
	endif
	call WorkAroundAutoClose('close')
	redraw
	echo msg
endfun

let g:uncomment_cnt = 0
let g:unable_line = 0
let g:message = 'Ready.'
function Uncommentify()

	if g:uncomment_cnt == 0
		let g:save_cursor = getpos('.')
		let g:visual_line = line("'>") - line("'<") + 1
	endif
	let line_num = 0
	let comment = SelectComment(&ft)[0]
	let key     = SelectComment(&ft)[1]
	if len(items(s:CommentStringMap[key])) == 1
		if getline('.') =~ comment['left'] . ' '
			norm ^
			for i in range(len(comment['left'])+1)
				norm x
			endfor
			let g:uncomment_cnt += 1
		endif
	elseif len(items(s:CommentStringMap[key])) == 2
		if getline('.') =~ comment['left'] . ' ' && getline('.') =~ ' ' . comment['right']
			norm ^
			for i in range(len(comment['left'])+1)
				norm x
			endfor
			norm $
			for i in range(len(comment['right'])+1)
				norm xh
			endfor
			let g:uncomment_cnt += 1
		endif
	else
		let line_num = line('.')
	endif

	if line_num != 0
		let g:unable_line += 1
	endif

	if g:uncomment_cnt == $buf.count || g:visual_line == g:uncomment_cnt
		let g:message = (g:uncomment_cnt) . ' lines uncommented!'
	elseif line_num != 0
		let g:message = (g:uncomment_cnt ) . ' lines uncommented!' . '( over! '.g:unable_line . ' line(s) )'
	else
		let g:message = '1 line uncommented!'
	endif
endf

fun SaveOrigin()
	let g:save_cursor = getpos('.')
endfun

fun RecoverOrigin()
	call setpos('.', g:save_cursor)
	echo g:message

	let g:comment_cnt = 0
	let g:uncomment_cnt = 0
	let g:unable_line = 0
	let g:visual_line = 0
	let g:message = 'Ready...'
endfun
" nmap <A-q> :call RecoverOrigin()<CR>
" nmap <A-w> :call SaveOrigin()<CR>
nmap <silent><A-i> :call InsertAlterMulti($buf.count)<CR>
vmap <silent><A-i> :call InsertAlterMulti(-1)<CR>3w

vmap <silent><A-u> :call Commentify(-1)<CR>
vmap <silent><A-o> :call Uncommentify()<CR>:call RecoverOrigin()<CR>==

nmap <silent><A-u> :call Commentify($buf.count)<CR>
nmap <silent><A-o> :call Uncommentify()<CR>:call RecoverOrigin()<CR>==
