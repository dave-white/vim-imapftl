" s:ExpansionLookup: {{{
" Description: {{{ Look up expansion text corresponding to the user-typed 
" token, or to a macro name matching it, in selected dictionary above.
" }}}
func s:ExpansionLookup(class, trigger, leader, token)
  let expansion = ''
  " Choose dictionary based on leader and trigger
  let dict = g:{a:class}#dict_{char2nr(a:leader)}_{a:trigger}

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

  " Found no macro name matching user-typed token, so return blank string.
  if empty(macroMatchList)
    if a:trigger == 13 " <cr>
      return "\\begin{".a:token."}\n<++>\n\\end{".a:token."}"
    elseif a:trigger == 9 " <tab>
      return "\\".a:token."{<++>}<++>"
    " elseif a:trigger == 32 " <space>
    "   return "\\begin{".a:token."}\n<++>\n\\end{".a:token."}"
    else
      return expansion
    endif
  endif

  if len(macroMatchList) == 1
    " Unique macro key matching token, so just grab that one's 
    " corresponding expansion text.
    let expansion = dict[macroMatchList[0]]
  else " Ask user which macro they want.
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
" Imapftl_GetMapping: {{{
" Description: to be written {{{
" args:
" 	trigger = char code of the keystroke imapped to trigger this lookup 
" 	below.
" }}}
func imapftl#Imapftl_GetMapping(trigger, class)
  " Set current pos, parameters.
  let line = getline(".")
  let linenum = line(".")
  let colnum = col(".")
  let leaderIdx = colnum - 2
  let maxMacroNameLen = 14 " currently comes from "subsubsection"

  " Search backward for a leader character.
  let stopidx = colnum - 2 - maxMacroNameLen
  while leaderIdx >= stopidx
      \ && index(g:{a:class}#leaders, line[leaderIdx]) < 0
      if line[leaderIdx] =~ '\s'
	" No whitespace characters allowed in macro names/tokens, so return 
	" immediately if we encounter one.
	return nr2char(a:trigger)
      endif
    let leaderIdx -= 1
  endwhile
  " No leader char found.
  if leaderIdx < stopidx
    return nr2char(a:trigger)
  endif

  " Get user-typed token: text between last leader char and pos of cursor 
  " at which trigger was inserted.
  let leader = line[leaderIdx]
  let token = slice(line, leaderIdx + 1, colnum - 1)
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
" vim:ft=vim:fdm=marker
