function! s:PythonContext()
  let classlnum = searchpos('^class', 'bnW', 0, 40)[0]
  let classname = substitute(getline(classlnum), '^\s*class\s\+\([^(:]*\).*', '\1', '')
  let deflnum = searchpos('^\s*def\s', 'bnW', classlnum, 40)[0]
  let defname = substitute(getline(deflnum), '\s*def\s\+\([^:]*\).*', '\1', '')

  let starttime = reltime()
  if classlnum && deflnum && classlnum < deflnum
    let lnum = deflnum

    while classlnum < lnum
      if reltimefloat(reltime(starttime)) > 0.040
        return classname . '.' . defname . " ! LocationAwareness() timed out"
      endif
    if strlen(substitute(getline(lnum), '\s', '', 'g')) > 0 && indent(lnum) <= indent(classlnum) && synIDattr(synID(lnum, 1, 0), 'name') != 'pythonDocstring'
        return defname
    endif
      let lnum -= 1
    endwhile

    return classname . '.' . defname
  elseif classlnum
    return classname
  elseif deflnum
    return defname
  else
    return ''
  endif
endfunction

function! s:PythonFormat(line)
  if g:location_awareness_format == 2
    let filepath = expand('%:r')
    let filepath = substitute(filepath, '/', '.', 'g')
  else
    let filepath = ""
  endif
  if len(filepath) > 0 && len(a:line) > 0
    let sep = g:location_awareness_format == 2 ? '.' : ':'
  else
    let sep = ''
  endif
  return filepath . sep . a:line
endfunction


function! locationawareness#LocationAwareness(force)
  if &filetype != 'python'
    return ""
  endif
  if a:force == 0 && exists('b:location_awareness_last_location') && exists('b:location_awareness_last_check') && reltimefloat(reltime(b:location_awareness_last_check)) < 0.5
    return b:location_awareness_last_location
  endif
  let b:location_awareness_last_check = reltime()
  let line = s:PythonContext()
  let b:location_awareness_last_location = s:PythonFormat(line)
  return b:location_awareness_last_location
endfunction


function! locationawareness#toggle_format()
  let g:location_awareness_format=(g:location_awareness_format+1) % 3
  call locationawareness#LocationAwareness(1)
  redrawstatus!
endfunction
