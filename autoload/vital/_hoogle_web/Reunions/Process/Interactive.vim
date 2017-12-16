" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not mofidify the code nor insert new lines before '" ___vital___'
if v:version > 703 || v:version == 703 && has('patch1170')
  function! vital#_hoogle_web#Reunions#Process#Interactive#import() abort
    return map({'_vital_depends': '', 'make': '', '_vital_loaded': ''},  'function("s:" . v:key)')
  endfunction
else
  function! s:_SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
  endfunction
  execute join(['function! vital#_hoogle_web#Reunions#Process#Interactive#import() abort', printf("return map({'_vital_depends': '', 'make': '', '_vital_loaded': ''}, \"function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
  delfunction s:_SID
endif
" ___vital___
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
	let s:V = a:V
	let s:Base  = s:V.import("Reunions.Process.Base")
	let s:Dummy = s:Base.make("")
endfunction


function! s:_vital_depends()
	return [
\		"Reunions.Process.Base",
\	]
endfunction


let s:base = {
\	"__reunions_process_interactive" : {}
\}


" function! s:base.start(input)
" 	if !self.is_exit()
" 		return -1
" 	endif
" 	let vimproc = self.__reunions_process_base.vimproc
" 	call vimproc.stdin.write(a:input)
" 	let self.__reunions_process_base.result = ""
" 	let self.__reunions_process_base.status = "processing"
" endfunction


function! s:base.input(text, ...)
	if !self.is_exit()
		return -1
	endif
	call self.wait()
	let vimproc = self.__reunions_process_base.vimproc
	call vimproc.stdin.write(a:text . "\n")
	let self.__reunions_process_interactive.log .= self.__reunions_process_base.result . a:text . "\n"
	let self.__reunions_process_base.result = ""
	let self.__reunions_process_base.status = "processing"
	let self.__reunions_process_interactive.endpat
\		= get(a:, 1, self.__reunions_process_interactive.endpat)
endfunction


function! s:base.is_exit()
	return call(s:Dummy.is_exit, [], self)
\	|| self.__reunions_process_base.result =~ self.__reunions_process_interactive.endpat
endfunction


function! s:base.status()
	return self.__reunions_process_base.result =~ self.__reunions_process_interactive.endpat && !call(s:Dummy.is_exit, [], self)
\		? "waiting"
\		: call(s:Dummy.status, a:000, self)
endfunction


function! s:base.kill(...)
	if self.__reunions_process_base.result =~ self.__reunions_process_interactive.endpat && !get(a:, 1, 0)
" 		call self._then()
		if has_key(self, "_then")
			call self._then(self.__reunions_process_base.result, self.as_result())
		elseif has_key(self, "then")
			call self.then(self.__reunions_process_base.result, self.as_result())
		endif
		return
	endif
	return call(s:Dummy.kill, a:000, self)
endfunction


function! s:base.log()
	return self.__reunions_process_interactive.log . self.__reunions_process_base.result
endfunction


function! s:make(command, endpat)
	let process = s:Base.make(a:command)
" 	call process.start()
	call extend(process, deepcopy(s:base))
	let process.__reunions_process_interactive.log = ""
	let process.__reunions_process_interactive.endpat = a:endpat
	return process
endfunction
