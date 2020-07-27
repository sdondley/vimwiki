" vim:tabstop=2:shiftwidth=2:expandtab:textwidth=99
" Vimwiki autoload plugin file
" Description: Utility functions
" Home: https://github.com/vimwiki/vimwiki/


" Get visual selection text content, optionaly replace its content
" :param: Text to replace selection
function! vimwiki#u#get_selection(...) abort
  " Copyed from DarkWiiPlayer at stackoverflow
  " https://stackoverflow.com/a/47051271/2544873
  " Get selection extremity position,
  " Discriminate selection mode
  if mode() ==? 'v'
    let [line_start, column_start] = getpos('v')[1:2]
    let [line_end, column_end] = getpos('.')[1:2]
  else
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
  end

  " Guard
  if (line2byte(line_start)+column_start) > (line2byte(line_end)+column_end)
    let [line_start, column_start, line_end, column_end] =
    \   [line_end, column_end, line_start, column_start]
  end
  let lines = getline(line_start, line_end)
  if len(lines) == 0
    return ''
  endif

  " If want to modify selection
  if a:0 > 0
    " Grab new content
    let line_link = a:1

    " Grab the content of line around the link: pre and post
    let start_link = max([column_start - 2, 0])
    let line_pre = ''
    if start_link > 0
      let line_pre .= lines[0][ : start_link]
    endif
    let line_post = lines[0][column_end - (&selection ==# 'inclusive' ? 0 : 1) : ]

    " Set the only single selected line
    call setline(line_start, line_pre . line_link . line_post)
  endif

  " Get selection extremity position, take into account selection option
  let lines[-1] = lines[-1][: column_end - (&selection ==# 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][column_start - 1:]
  return join(lines, "\n")
endfunction


" Execute: string v:count times
function! vimwiki#u#count_exe(cmd) abort
    for i in range( max([1, v:count]) )
        exe a:cmd
    endfor
endfunction


" Trim spaces: leading and trailing
function! vimwiki#u#sort_len(list) abort
  function! s:len_compare(s1, s2) abort
    let i1 = len(a:s1)
    let i2 = len(a:s2)
     return i1 == i2 ? 0 : i1 > i2 ? 1 : -1
  endfunction
  return sort(a:list, 's:len_compare')
endfunction


function! vimwiki#u#trim(string, ...) abort
  let chars = ''
  if a:0 > 0
    let chars = a:1
  endif
  let res = substitute(a:string, '^[[:space:]'.chars.']\+', '', '')
  let res = substitute(res, '[[:space:]'.chars.']\+$', '', '')
  return res
endfunction


" Builtin cursor doesn't work right with unicode characters.
function! vimwiki#u#cursor(lnum, cnum) abort
  exe a:lnum
  exe 'normal! 0'.a:cnum.'|'
endfunction


" Returns: OS name, human readable
function! vimwiki#u#os_name() abort
  if vimwiki#u#is_windows()
    return 'Windows'
  elseif vimwiki#u#is_macos()
    return 'Mac'
  else
    return 'Linux'
  endif
endfunction


" Check if OS is windows
function! vimwiki#u#is_windows() abort
  return has('win32') || has('win64') || has('win95') || has('win16')
endfunction


" Check if OS is mac
function! vimwiki#u#is_macos() abort
  if has('mac') || has('macunix') || has('gui_mac')
    return 1
  endif
  " that still doesn't mean we are not on Mac OS
  let os = substitute(system('uname'), '\n', '', '')
  return os ==? 'Darwin' || os ==? 'Mac'
endfunction


function! vimwiki#u#count_first_sym(line) abort
  let first_sym = matchstr(a:line, '\S')
  return len(matchstr(a:line, first_sym.'\+'))
endfunction


function! vimwiki#u#escape(string) abort
  return escape(a:string, '~.*[]\^$')
endfunction


" Load concrete Wiki syntax: sets regexes and templates for headers and links
function! vimwiki#u#reload_regexes() abort
  execute 'runtime! syntax/vimwiki_'.vimwiki#vars#get_wikilocal('syntax').'.vim'
endfunction


" Load syntax-specific functionality
function! vimwiki#u#reload_regexes_custom() abort
  execute 'runtime! syntax/vimwiki_'.vimwiki#vars#get_wikilocal('syntax').'_custom.vim'
endfunction


" Backward compatible version of the built-in function shiftwidth()
function! vimwiki#u#sw() abort
  if exists('*shiftwidth')
    return shiftwidth()
  else
    return &shiftwidth
  endif
endfunc

" a:mode single character indicating the mode as defined by :h maparg
" a:key the key sequence to map
" a:plug the plug command the key sequence should be mapped to
" a:1 optional argument with the following functionality:
"   if a:1==1 then the hasmapto(<Plug>) check is skipped.
"     this can be used to map different keys to the same <Plug> definition
"   if a:1==2 then the mapping is not <buffer> specific i.e. it is global
function! vimwiki#u#map_key(mode, key, plug, ...) abort
  if a:0 && a:1 == 2
    " global mappings
    if !hasmapto(a:plug) && maparg(a:key, a:mode) ==# ''
      exe a:mode . 'map ' . a:key . ' ' . a:plug
    endif
  elseif a:0 && a:1 == 1
      " vimwiki buffer mappings, repeat mapping to the same <Plug> definition
      exe a:mode . 'map <buffer> ' . a:key . ' ' . a:plug
  else
    " vimwiki buffer mappings
    if !hasmapto(a:plug)
      exe a:mode . 'map <buffer> ' . a:key . ' ' . a:plug
    endif
  endif
endfunction


" Returns: 1 if line is a code block or math block
"
" The last two conditions are needed for this to correctly
" detect nested syntaxes within code blocks
function! vimwiki#u#is_codeblock(lnum) abort
  let syn_g = synIDattr(synID(a:lnum,1,1),'name')
  if  syn_g =~# 'Vimwiki\(Pre.*\|IndentedCodeBlock\|Math.*\)'
        \ || (syn_g !~# 'Vimwiki.*' && syn_g !=? '')
    return 1
  else
    return 0
  endif
endfunction

" Sets the filetype to vimwiki
" If g:vimwiki_filetypes variable is set
" the filetype will be vimwiki.<ft1>.<ft2> etc.
function! vimwiki#u#ft_set() abort
  let ftypelist = vimwiki#vars#get_global('filetypes')
  let ftype = 'vimwiki'
  for ftypeadd in ftypelist
    let ftype = ftype . '.' . ftypeadd
  endfor
  let &filetype = ftype
endfunction

" Returns: 1 if filetype is vimwiki, 0 else
" If multiple fileytpes are in use 1 is returned only if the
" first ft is vimwiki which should always be the case unless
" the user manually changes it to something else
function! vimwiki#u#ft_is_vw() abort
  " Clause: is filetype defined
  if &filetype ==# '' | return 0 | endif
  if split(&filetype, '\.')[0] ==? 'vimwiki'
    return 1
  else
    return 0
  endif
endfunction
