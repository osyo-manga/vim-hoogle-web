scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


" let s:V = vital#of("vital")
let s:V = vital#hoogle_web#of()
let s:Buffer = s:V.import("Coaster.Buffer")
let s:HTTP = s:V.import("Web.HTTP")
let s:Job = s:V.import("Branc.Job")
let s:Web = s:V.import("Reunions.Web")
let s:lynx_buffer = s:Buffer.new_temp()


let g:hoogle#web#open_cmd = get(g:, "hoogle#web#open_cmd", "split")


function! s:error(msg)
	echohl ErrorMsg
	echo a:msg
	echohl NONE
endfunction


function! s:promise(callback)
	let promise = {
\		"_then"   : { result -> result },
\		"_catch"  : { result -> result },
\	}

	function! promise.then(callback)
		let self._then = a:callback
		return self
	endfunction

	function! promise.catch(callback)
		let self._catch = a:callback
		return self
	endfunction

	function! promise.resolve(result)
		return self._then(a:result)
	endfunction

	function! promise.reject(result)
		return self._catch(a:result)
	endfunction

	call a:callback(promise.resolve, promise.reject)
	return promise
endfunction


function! s:promise_job(cmd)
	function! s:callback(resolve, reject) closure
		let out_msg = ""
		let err_msg = ""
		let job = s:Job.new()

		function! job._out_cb(ch, msg) closure
			" NOTE: 処理が重すぎるので
			" lynx の出力結果から末尾の url を削除
			if a:msg !~ '^http'
				let out_msg .= a:msg . "\n"
			endif
		endfunction

		function! job._err_cb(ch, msg) closure
			if a:msg !~ '^http'
				let err_msg .= a:msg . "\n"
			endif
		endfunction

		function! job._close_cb(ch) closure
			if err_msg != ""
				call a:reject(err_msg)
			else
				call a:resolve(out_msg)
			endif
		endfunction
		call job.start(a:cmd)
	endfunction

	return s:promise(funcref("s:callback"))
endfunction


function! s:promise_http_get(url)
	function! s:promise_http_get_callback(resolv, reject) closure
		let cmd = s:Web.build_get_command(a:url)
		let job = s:promise_job(cmd)
		call job.then( { result -> a:resolv(s:Web.parse_result(result)) })
		call job.catch({ result -> a:reject(result) })
	endfunction
	return s:promise(funcref("s:promise_http_get_callback"))
endfunction


function! hoogle#web#search(keyword)
	let url = "http://www.haskell.org/hoogle/?mode=json&hoogle=" . s:HTTP.encodeURI(a:keyword) . "&start=1&count=1000"
	return s:promise({ resolve, reject ->
\		s:promise_http_get(url).then({
\			result -> resolve(json_decode(result.content))
\		}).catch({
\			result -> reject(callback)
\		})
\	})
endfunction


let s:anime = { "count" : 0 }
function! s:anime.next(...)
	let self.count += 1
	let icon = ["-", "\\", "|", "/"]
	let anime =  icon[self.count % len(icon)] . " Loading" . repeat(".", self.count % 5)
	return anime
endfunction


" call hoogle#web#open("http://hackage.haskell.org/packages/archive/base/latest/doc/html/Prelude.html#v:map")
function! hoogle#web#open(url)
	if !executable("lynx")
		return s:error("Please install lynx.")
	endif

	let buffer = s:lynx_buffer

	if !buffer.is_opened_in_current_tabpage()
		call buffer.open(g:hoogle#web#open_cmd)
	endif
	call buffer.clear()
	
	if buffer.tap()
		syntax clear
		unlet! b:current_syntax
" 		syntax include @hoogleLynx /usr/local/share/vim/vim80/syntax/haskell.vim
		syntax include @hoogleLynx syntax/haskell.vim
		echo b:current_syntax
		let b:current_syntax = "hoogle-web-haskell"
		call buffer.untap()
	endif

	let loading = timer_start(100, { timer -> setbufline(buffer.number(), 1, s:anime.next()) }, { "repeat" : -1 })

	function! s:open_cb(resolve, reject) closure
		let cmd = printf("lynx -dump -nonumbers %s", a:url)
		let keyword = get(matchlist(a:url, '#v:\(.*\)$'), 1, "")
		if keyword == ""
			return s:error("Failed url.")
		endif

		let job = s:promise_job(cmd)
		function! job._catch(result)
			return s:error(a:result)
		endfunction

		function! job._then(result) closure
			Debug then
			call timer_stop(loading)
			call buffer.clear()
			call setbufline(buffer.number(), 1, split(a:result, "\n"))
" 			call buffer.setline(1, split(a:result, "\n"))
			call search(printf('\C^\s*\<%s\>', keyword))
		endfunction
	endfunction
	return s:promise(funcref("s:open_cb"))
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
