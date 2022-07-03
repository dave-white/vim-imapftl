" s:get_token: {{{
function s:get_token(class)
  " Set current pos, parameters.
  let l:line = getline(".")
  let l:start_idx = col(".") - 1
  let l:max_token_len = 14 " currently comes from "subsubsection"

  " Search backward for a leader character.
  let l:leader_idx = l:start_idx
  let l:stop_idx = max([l:start_idx - l:max_token_len, -1])
  while l:leader_idx > l:stop_idx
    if index(g:imapftl#{a:class}#macro_token_excl, l:line[l:leader_idx]) >= 0
      return [0, v:null]
    elseif index(g:imapftl#{a:class}#leaders,
	\ char2nr(l:line[l:leader_idx])) >= 0
      return [ char2nr(l:line[l:leader_idx]),
	  \ slice(l:line, l:leader_idx + 1, l:start_idx) ]
    endif
    let l:leader_idx -= 1
  endwhile
  " No leader char found.
  return [0, v:null]
endfunction
" }}}
" imapftl#get_macro: {{{
" Description: to be written {{{
" args:
" 	trigger = char code of the keystroke imapped to trigger this lookup 
" 	below.
" }}}
function imapftl#get_macro(trigger, class = &ft)
  let l:leader_token = s:get_token(a:class)
  if l:leader_token[0]
    let l:leader = l:leader_token[0]
    let l:token = l:leader_token[1]
  else
    exe "normal! a".nr2char(a:trigger) | return
    return nr2char(a:trigger)
  endif
  " Abort if token is empty.
  if empty(l:token)
    exe "normal! a".nr2char(a:trigger) | return
    return nr2char(a:trigger)
  endif

  " Look up expansion text corresponding to the user-typed token, or to a 
  " macro name matching it, in selected dictionary above.
  let l:macro = imapftl#{a:class}#get_macro(l:token, a:trigger, l:leader)
  " Don't paste in a blank; just return the trigger.
  if empty(l:macro)
    exe "normal! a".nr2char(a:trigger) | return
    return nr2char(a:trigger)
  endif

  " Overwrite leader + token
  " exe "normal! \<bs>v ".repeat("\<bs>", strcharlen(l:token))."d"
  exe "normal! i".repeat("\<bs>", strcharlen(l:token) + 1)
  normal! m'
  call confirm(l:macro, 'x')
  exe "normal! i".l:macro
  if match(l:macro, "<++>") >= 0
    normal `'
  endif
  normal a
  return
  " return repeat("\<bs>", strcharlen(l:token) + 1).l:macro
endfunction
" }}}
" imapftl#get_generic_macro: {{{
function imapftl#get_generic_macro(trigger, class = &ft)
  let l:leader_token = s:get_token(a:class)
  let l:leader = char2nr(l:leader_token[0])
  let l:token = l:leader_token[1]
  let l:macro = substitute(
      \ g:imapftl#{a:class}#generic_mapping_{l:leader}_{a:trigger},
      \ "%N", l:token, "g" )
  " Overwrite l:leader + l:token
  exe "normal v ".repeat("h", strcharlen(l:token) + 2)." s ".l:macro
  if match(l:macro, g:imapftl#{a:class}#ph) >= 0
    call imapftl#jump2ph(a:class)
  endif
endfunction
" }}}

function imapftl#jump2ph(class = &ft, dir = 1)
  let l:search_char = a:dir == 1 ? "/" : "?"
  exe "normal ".l:search_char.g:imapftl#{a:class}#ph.l:search_char."\<CR>"
      \." \| normal v gn \<c-g>"
endfunction

" vim:ft=vim:fdm=marker
