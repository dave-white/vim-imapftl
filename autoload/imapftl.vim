" s:ExpansionLookup: {{{
" Description: {{{ Look up expansion text corresponding to the user-typed 
" token, or to a macro name matching it, in selected dictionary above.
" }}}
func s:ExpansionLookup(class, trigger, leader, token)
  let expansion = ''
  " Choose dictionary based on leader and trigger
  let dict = g:{a:class}#dict_{a:leader}_{a:trigger}

  " User-typed token matches a macro name (dict key) exactly, so return 
  " corresponding expansion text immediately.
  if has_key(dict, a:token)
    let expansion = dict[a:token]
    return expansion
  endif

  " User-typed token does not match a macro name exactly, so build a list 
  " of those it pattern-matches.
  let macroMatchList = []
  for macro in keys(dict)
    if macro =~ '\C^'.a:token.'\w*$'
      let macroMatchList = add(macroMatchList, macro)
    endif
  endfor

  if len(macroMatchList) == 1
    " Unique macro key matching token, so just grab that one's 
    " corresponding expansion text.
    let expansion = dict[macroMatchList[0]]
  elseif len(macroMatchList) > 1 " Ask user which macro they want.
    call sort(macroMatchList)
    let selMacroList = ['Select macro:']
    for selection in macroMatchList
      call add(selMacroList,
	    \ index(macroMatchList, selection) + 1
	    \ . '. ' . selection)
    endfor
    let selMacro = macroMatchList[
	  \ inputlist(selMacroList) - 1 ]
    let expansion = dict[selMacro]
  endif

  return expansion
endfunc
" }}}
" s:AddMovement: {{{
" Description: Move to and delete first placeholder.
func s:AddMovement(text, startLn)
  let firstPhIdx = stridx(a:text, "<++>")
  if firstPhIdx >= 0
    return  a:text . "\<c-o>:call cursor(".a:startLn.", 1) | "
	  \ . "call search(\"<++>\")\<cr>"
	  \ . repeat("\<Del>", 4)
  else
    return a:text
  endif
endfunc
" }}}
" s:GetToken: {{{
func s:GetToken(class)
  " Set current pos, parameters.
  let line = getline(".")
  let colnum = col(".")
  let maxMacroNameLen = 14 " currently comes from "subsubsection"

  " Search backward for a leader character.
  let leader_idx = colnum - 2
  let stopidx = colnum - 2 - maxMacroNameLen
  while leader_idx >= stopidx
      \ && index(g:{a:class}#leaders, line[leader_idx]) < 0
    for non_macro_char in g:{a:class}#non_macro_char_l
      " Don't try a mapping if we encounter a disallowed character (pattern).
      if line[leader_idx] =~ non_macro_char
	return ["", ""]
      endif
    endfor
    let leader_idx -= 1
  endwhile
  " No leader char found.
  if leader_idx < stopidx
    return ["", ""]
  endif

  " Get user-typed token: text between last leader char and pos of cursor at 
  " which trigger was inserted, inclusive.
  return [line[leader_idx], slice(line, leader_idx + 1, colnum - 1)]
endfunc
" }}}
" Imapftl_GetMapping: {{{
" Description: to be written {{{
" args:
" 	trigger = char code of the keystroke imapped to trigger this lookup 
" 	below.
" }}}
func imapftl#Imapftl_GetMapping(trigger, class)
  let linenum = line(".")
  let leader_token = s:GetToken(a:class)
  let leader = char2nr(leader_token[0])
  let token = leader_token[1]
  " Abort if token is empty.
  if empty(token)
    return nr2char(a:trigger)
  endif

  " Look up expansion text corresponding to the user-typed token, or to a 
  " macro name matching it, in selected dictionary above.
  let expansion = s:ExpansionLookup(a:class, a:trigger, leader, token)

  " Don't paste in a blank; just return the trigger.
  if empty(expansion)
    return nr2char(a:trigger)
  endif

  " Add enough backspaces to overwrite the token and then an undo mark.
  let printText = repeat("\<bs>", strcharlen(token) + 1)
	\ . "\<c-g>u"
	\ . "\<c-v>"
	\ . expansion

  return s:AddMovement(printText, linenum)
endfunc
" }}}
" imapftl#Imapftl_GetGenericMapping: {{{
func imapftl#Imapftl_GetGenericMapping(trigger, class)
  let linenum = line(".")
  let leader_token = s:GetToken(a:class)
  let leader = char2nr(leader_token[0])
  let token = leader_token[1]
  let expansion =
      \ substitute(g:{a:class}#generic_mapping_{leader}_{a:trigger},
      \ "<token>", token, "g")
  let printText = repeat("\<bs>", strcharlen(token) + 1)
	\ . "\<c-g>u"
	\ . "\<c-v>"
	\ . expansion

  return s:AddMovement(printText, linenum)
endfunc
" }}}
" vim:ft=vim:fdm=marker
