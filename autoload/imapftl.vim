" s:lookup_macro: {{{
" Description: {{{ Look up expansion text corresponding to the user-typed 
" token, or to a macro name matching it, in selected dictionary above.
" }}}
function s:lookup_macro(class, trigger, leader, token)
  let l:macro = ''
  " Choose dictionary based on leader and trigger
  let l:dict = g:imapftl#{a:class}#dict_{a:leader}_{a:trigger}

  " User-typed token matches a macro name (l:dict key) exactly, so return 
  " corresponding l:macro text immediately.
  if has_key(l:dict, a:token)
    let l:macro = l:dict[a:token]
    return l:macro
  endif

  " User-typed token does not match a macro name exactly, so build a list 
  " of those it pattern-matches.
  let l:matches = []
  for l:key in keys(l:dict)
    if l:key =~ '\C^'.a:token.'\w*$'
      let l:matches = add(l:matches, l:key)
    endif
  endfor

  if len(l:matches) == 1
    " Unique macro key matching token, so just grab that one's 
    " corresponding l:macro text.
    let l:macro = l:dict[l:matches[0]]
  elseif len(l:matches) > 1 " Ask user which macro they want.
    call sort(l:matches)
    let l:sel_prompt_list = ['Select macro:']
    for selection in l:matches
      call add(l:sel_prompt_list,
	    \ index(l:matches, selection) + 1
	    \ . '. ' . selection)
    endfor
    let selMacro = l:matches[
	  \ inputlist(l:sel_prompt_list) - 1 ]
    let l:macro = l:dict[selMacro]
  endif

  return l:macro
endfunction
" }}}
" s:get_token: {{{
function s:get_token(class)
  " Set current pos, parameters.
  let l:line = getline(".")
  let l:start_idx = col(".") - 1
  let l:max_token_len = 14 " currently comes from "subsubsection"

  " Search backward for a leader character.
  let l:leader_idx = l:start_idx - 1
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
    return nr2char(a:trigger)
  endif
  " Abort if token is empty.
  if empty(l:token)
    return nr2char(a:trigger)
  endif

  " Look up expansion text corresponding to the user-typed token, or to a 
  " macro name matching it, in selected dictionary above.
  let l:macro = s:lookup_macro(a:class, a:trigger, l:leader, l:token)
  " Don't paste in a blank; just return the trigger.
  if empty(l:macro)
    return nr2char(a:trigger)
  endif

  " Overwrite leader + token
  exe "normal! \<bs>v ".repeat("\<bs>", strcharlen(l:token))."d"
  return l:macro
  " return a:trigger == 32 ? " " : ""
  " if match(l:macro, g:imapftl#{a:class}#ph) >= 0
  "   call imapftl#jump2ph(a:class)
  " endif
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
