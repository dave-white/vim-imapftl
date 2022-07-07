" s:get_token: {{{
function s:get_token(class)
  " Set current pos, parameters.
  let l:line = getline(".")
  let l:start_idx = col(".") - 2
  let l:max_token_len = 14 " currently comes from "subsubsection"

  " Search backward for a leader character.
  let l:idx = l:start_idx
  let l:stop_idx = max([l:start_idx - l:max_token_len, -1])
  while l:idx > l:stop_idx
    let l:char_at_idx = l:line[l:idx]
    if l:char_at_idx =~ g:imapftl#{a:class}#macro_token_excl_pat
      return [0, v:null]
    elseif l:char_at_idx =~ g:imapftl#{a:class}#leader_pat
      return [ char2nr(l:char_at_idx),
	  \ slice(l:line, l:idx + 1, l:start_idx + 1) ]
    endif
    let l:idx -= 1
  endwhile
  " No leader char found.
  return [0, v:null]
endfunction
" }}}

func imapftl#print_ph_jump(str) " {{{
  let l:printout = "x\<C-\>\<C-N>m'\"_s".a:str
  if match(a:str, "<++>") >= 0
    let l:printout .= "<++>\<c-\>\<c-n>`' | :call imapftl#jump2ph(\"vitex\")\<cr>"
  endif
  return l:printout
endfunc
" }}}

" imapftl#get_macro: {{{
" Description: to be written {{{
" args:
" 	trigger = char code of the keystroke imapped to trigger this lookup 
" 	below.
" }}}
func imapftl#get_macro(trigger, class = &ft)
  let l:leader_token = s:get_token(a:class)
  if l:leader_token[0]
    let l:leader = l:leader_token[0]
    let l:token = l:leader_token[1]
  else
    return nr2char(a:trigger)
  endif
  " Abort if token is empty.
  if empty(l:token)
    return nr2char(a:trigger)
  endif

  " Look up expansion text corresponding to the user-typed token, or to a 
  " macro name matching it, in selected dictionary above.
  let l:macro = imapftl#{a:class}#get_macro(l:token, a:trigger, l:leader)
  " Don't paste in a blank; just return the trigger.
  if empty(l:macro)
    return nr2char(a:trigger)
  endif

  " Overwrite leader + token
  " exe "normal! \<bs>v ".repeat("\<bs>", strcharlen(l:token))."d"
  return "\<c-g>u"
      \.repeat("\<bs>", strcharlen(l:token) + 1)
      \.imapftl#print_ph_jump(l:macro)
endfunc
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
  let l:search_char = a:dir > 0 ? '/' : '?'
  exe "normal!".l:search_char.g:imapftl#{a:class}#ph."\<cr>vgn\<c-g>"
  return
  " call search(g:imapftl#{a:class}#ph, l:flags)
  " exe "normal! v gn \<c-g>"
endfunction

" vim:ft=vim:fdm=marker
