scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:action = {
\	'description' : 'ref-lynx',
\	'is_selectable' : 0,
\}

function! s:action.func(candidate)
	execute "Ref lynx" a:candidate.action__path
endfunction


call unite#custom#action('source/hoogle/web/uri', 'ref-lynx', s:action)
unlet s:action


let s:source = {
\	"name" : "hoogle/web",
\	"description" : "search by hoogle web",
\	"action_table" : {
\		"open" : {
\			"is_selectable" : 0,
\			"description" : "Open website on Vim"
\		},
\		"preview" : {
\			"is_selectable" : 0,
\			"is_quit" : 0,
\			"description" : "Preview docs"
\		},
\	},
\	"hooks" : {},
\	"count" : 0,
\}


function! s:source.action_table.open.func(candidate)
	call hoogle#web#open(a:candidate.action__path)
endfunction


function! s:source.action_table.preview.func(candidate)
	if !has_key(a:candidate, "action__text")
		return
	endif

	call unite#view#_preview_file("unite-hoogle/web-preview")
	let winnr = winnr()
	wincmd P
	silent % delete _
	setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
	
	try
		call setline(1, split(a:candidate.action__text, "\n"))
	finally
		execute winnr.'wincmd w'
	endtry
endfunction


let s:cache = {}
function! s:source.hooks.on_init(args, context)
	let keyword = get(a:args, 0)
	if keyword == ""
		let a:context.__candidates = [{ "word" : "Please input keyword." }]
		return
	endif

	if has_key(s:cache, keyword)
		let a:context.__candidates = s:cache[keyword]
		return
	endif

	let a:context.__candidates = []
	let promise = hoogle#web#search(keyword)
	function! promise._then(result) closure
		let a:context.__candidates = map(a:result.results, { -> {
\			"word" : v:val.self,
\			"kind" : "uri",
\			"action__path" : v:val.location,
\			"action__text" : v:val.location . "\n" . v:val.docs,
\			"is_multiline" : 1,
\		} })
		let s:cache[keyword] = a:context.__candidates
	endfunction
endfunction


function! s:source.async_gather_candidates(args, context)
	let keyword = get(a:args, 0, "map")
	let a:context.source.unite__cached_candidates = []

	if empty(a:context.__candidates)
		let self.count += 1
		let icon = ["-", "\\", "|", "/"]
		return [{ "word" : icon[self.count % len(icon)] . " Searching '" . keyword . "'" . repeat(".", self.count % 5) }]
	endif

	let a:context.is_async = 0
	return a:context.__candidates
endfunction


function! unite#sources#hoogle_web#define(...)
	return s:source
endfunction


if expand("%:p") == expand("<sfile>:p")
	call unite#define_source(s:source)
endif


let &cpo = s:save_cpo
unlet s:save_cpo
