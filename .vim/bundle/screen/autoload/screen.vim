" Author: Eric Van Dewoestine <ervandew@gmail.com>
"
" License: {{{
"   Copyright (c) 2009 - 2010
"   All rights reserved.
"
"   Redistribution and use of this software in source and binary forms, with
"   or without modification, are permitted provided that the following
"   conditions are met:
"
"   * Redistributions of source code must retain the above
"     copyright notice, this list of conditions and the
"     following disclaimer.
"
"   * Redistributions in binary form must reproduce the above
"     copyright notice, this list of conditions and the
"     following disclaimer in the documentation and/or other
"     materials provided with the distribution.
"
"   * Neither the name of Eric Van Dewoestine nor the names of its
"     contributors may be used to endorse or promote products derived from
"     this software without specific prior written permission of
"     Eric Van Dewoestine.
"
"   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
"   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
"   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
"   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
"   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
"   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
"   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
"   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
"   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
"   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
"   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" }}}

let s:save_cpo=&cpo
set cpo&vim

" Script Variables {{{

  if has('win32') || has('win64') || has('win32unix')
    let s:terminals = ['bash']
  elseif has('mac') && has('gui_running')
    let s:terminals = ['Terminal.app']
  else
    let s:terminals = [
        \ 'gnome-terminal', 'konsole',
        \ 'urxvt', 'multi-aterm', 'aterm', 'mrxvt', 'rxvt',
        \ 'xterm',
      \ ]
  endif

" }}}

" ScreenShellCommands() {{{
function! screen#ScreenShellCommands()
  command -nargs=? -complete=shellcmd ScreenShell
    \ :call screen#ScreenShell('<args>', 'horizontal')
  command -nargs=? -complete=customlist,screen#CommandCompleteScreenSessions
    \ ScreenShellAttach :call screen#ScreenShellAttach('<args>')

  if !has('gui_running') &&
   \ !g:ScreenShellExternal &&
   \ (g:ScreenImpl == 'Tmux' || g:ScreenShellGnuScreenVerticalSupport != '')
    command -nargs=? -complete=shellcmd ScreenShellVertical
      \ :call screen#ScreenShell('<args>', 'vertical')
  endif
endfunction " }}}

" ScreenShell(cmd, orientation) {{{
" Open a split shell.
function! screen#ScreenShell(cmd, orientation)
  if g:ScreenImpl != 'GnuScreen' && g:ScreenImpl != 'Tmux'
    echohl WarningMsg
    echom 'Unsupported g:ScreenImpl value "' . g:ScreenImpl . '".  ' .
      \ 'Supported values included "GnuScreen" or "Tmux".'
    echohl Normal
    return
  endif

  if !s:screen{g:ScreenImpl}.isValid()
    return
  endif

  let s:orientation = a:orientation

  " Specifies a name to be supplied to vim's --servername arg when invoked in
  " a new screen session.
  if !exists('g:ScreenShellServerName')
    " Perform this here so that g:ScreenShellExternal can be set after vim
    " starts.
    let s:servername = g:ScreenShellExternal ? '' : 'vim'
  else
    let s:servername = g:ScreenShellServerName
  endif

  try
    let bootstrap = !has('gui_running') &&
      \ !exists('g:ScreenShellBootstrapped') &&
      \ expand('$TERM') !~ '^screen'

    " if using an external shell without the need to set the vim servername,
    " then don't bootstrap
    if bootstrap
      if g:ScreenShellExternal &&
       \ (s:servername == '' || g:ScreenImpl == 'Tmux' ||
       \  !has('clientserver') || has('win32') || has('win64'))
        let bootstrap = 0
      endif
    endif

    if bootstrap
      call s:ScreenBootstrap(a:cmd)
    else
      call s:ScreenInit(a:cmd)
    endif
  finally
    " wrapping in a try without catching anything just cleans up the vim error
    " produced by an exception thrown from one of the above functions.
  endtry
endfunction " }}}

" ScreenShellAttach(session) {{{
" Attach to an existing screen session.
function! screen#ScreenShellAttach(session)
  if !s:screen{g:ScreenImpl}.isValid()
    return
  endif

  let g:ScreenShellSession = s:screen{g:ScreenImpl}.attachSession(a:session)

  if g:ScreenShellSession != '0'
    if !exists(':ScreenSend')
      command -nargs=0 -range=% ScreenSend :call <SID>ScreenSend(<line1>, <line2>)
      let g:ScreenShellSend = s:ScreenSendFuncRef()
      let g:ScreenShellFocus = s:ScreenFocusFuncRef()
    endif

    if g:ScreenShellAttachTargetCurrent
      let g:ScreenShellWindow = 'screenshell'
      call s:screen{g:ScreenImpl}.setTitle()
    endif
  endif
endfunction " }}}

" s:ScreenBootstrap(cmd) {{{
" Bootstrap a new screen session.
function! s:ScreenBootstrap(cmd)
  try
    let g:ScreenShellBootstrapped = 1
    let g:ScreenShellSession = s:screen{g:ScreenImpl}.newSessionName()

    wa
    let save_sessionoptions = &sessionoptions
    set sessionoptions+=globals
    set sessionoptions-=tabpages
    let sessionfile = substitute(tempname(), '\', '/', 'g')
    exec 'mksession ' . sessionfile

    " when transitioning from windows vim to cygwin vim, the session file
    " needs to be purged of windows line endings.
    if has('win32') || has('win64')
      let winrestcmd = winrestcmd()
      try
        exec '1split ' . sessionfile
        set ff=unix
        exec "%s/\<c-m>$//g"
        wq
      finally
        exec winrestcmd
      endtry
    endif

    " support for taglist
    if exists(':TlistSessionSave') &&
     \ exists('g:TagList_title') &&
     \ bufwinnr(g:TagList_title)
      let g:ScreenShellTaglistSession = sessionfile . '.taglist'
      exec 'TlistSessionSave ' . g:ScreenShellTaglistSession
      exec 'silent! !echo "Tlist | TlistSessionLoad ' .
        \ g:ScreenShellTaglistSession . '" >> "' . sessionfile . '"'
    endif

    let bufend = bufnr('$')
    let bufnum = 1
    while bufnum <= bufend
      if bufnr(bufnum) != -1
        call setbufvar(bufnum, 'save_swapfile', getbufvar(bufnum, '&swapfile'))
        call setbufvar(bufnum, '&swapfile', 0)

        " suppress prompt and auto reload changed files for the user when
        " returning to this vim session
        augroup screenshell_filechanged
          exec 'autocmd! FileChangedShell <buffer=' . bufnum . '>'
          exec 'autocmd FileChangedShell <buffer=' . bufnum . '> ' .
            \ 'let v:fcs_choice = (v:fcs_reason == "changed" ? "reload" : "ask") | ' .
            \ 'autocmd! screenshell_filechanged FileChangedShell <buffer=' . bufnum . '>'
        augroup END
      endif
      let bufnum = bufnum + 1
    endwhile

    " supply a servername when starting vim if supported
    let server = ''
    if has('clientserver') && s:servername != ''
      let server = '--servername "' . s:servername . '" '
    endif

    " when transitioning from windows console vim to cygwin vim, we don't know
    " if the cygwin version support clientserver, so error on the safe side
    " (in my environment the cygwin vim doesn't support client server).
    if has('win32') || has('win64')
      let server = ''
    endif

    call s:screen{g:ScreenImpl}.bootstrap(server, sessionfile, a:cmd)
  finally
    redraw!

    unlet g:ScreenShellBootstrapped

    " if there was an error writing files, then we didn't get far enough to
    " need this cleanup.
    if exists('save_sessionoptions')
      let &sessionoptions = save_sessionoptions
      call delete(sessionfile)

      " remove taglist session file
      if exists('g:ScreenShellTaglistSession')
        call delete(g:ScreenShellTaglistSession)
      endif

      redraw!

      let possible_detach = 0
      let bufnum = 1
      let winrestcmd = winrestcmd()
      new
      try
        while bufnum <= bufend
          if bufnr(bufnum) != -1
            try
              call setbufvar(bufnum, '&swapfile', getbufvar(bufnum, 'save_swapfile'))
            catch /E325/
              let possible_detach = 1
              exec 'buffer ' . bufnum
              try
                redraw
                edit
              catch
              endtry
            endtry
          endif
          let bufnum = bufnum + 1
        endwhile
      finally
        quit!
        exec winrestcmd
      endtry

      if possible_detach
        echohl WarningMsg
        echom 'Warning: detatching from a screen session started by ' .
            \ ':ScreenShell may result in conflicting swap files like those ' .
            \ 'just encountered. Due to this possibility, detaching from a ' .
            \ 'screen session started by :ScreenShell is discouraged.  ' .
            \ 'Instead you should issue a :ScreenQuit or exit the vim ' .
            \ 'instance in screen normally (:qa)'
        echohl None
      endif
    endif
  endtry
endfunction " }}}

" s:ScreenInit(cmd) {{{
" Initialize the current screen session.
function! s:ScreenInit(cmd)
  let g:ScreenShellWindow = 'screenshell'
  " use a portion of the command as the title, if supplied
  "if a:cmd != '' && a:cmd !~ '^\s*vim\>'
  "  let g:ScreenShellWindow = s:ScreenCmdName(a:cmd)[:15]
  "endif

  " when already running in a screen session, never use an external shell
  let external = !exists('g:ScreenShellBootstrapped') &&
        \ expand('$TERM') =~ '^screen' ? 0 : g:ScreenShellExternal
  " w/ gvim always use an external shell
  let external = has('gui_running') ? 1 : external

  if exists('g:ScreenShellBootstrapped') || external
    command -nargs=0 ScreenQuit :call <SID>ScreenQuit(0)
    if g:ScreenShellQuitOnVimExit
      augroup screen_shell
        autocmd!
        autocmd VimLeave * call <SID>ScreenQuit(1)
      augroup END
    endif
  endif

  " use screen regions
  if !external
    let result = s:screen{g:ScreenImpl}.openRegion()

    if !v:shell_error && a:cmd != ''
      let result = s:screen{g:ScreenImpl}.send(a:cmd)
    endif

  " use an external terminal
  else
    let g:ScreenShellSession = exists('g:ScreenShellSession') ?
      \ g:ScreenShellSession : s:screen{g:ScreenImpl}.newSessionName()

    " This block should only be hit in console mode with external terminal +
    " vim server name set.
    " Not supported by tmux since it doesn't appear that you can have
    " more than one terminal connected to a session without them all
    " focusing the same window.
    if !has('gui_running') &&
     \ exists('g:ScreenShellBootstrapped') &&
     \ g:ScreenImpl != 'Tmux'

      let result = s:screen{g:ScreenImpl}.newWindow(0)

      if !v:shell_error
        let result = s:screen{g:ScreenImpl}.newTerminalMulti()

        if !v:shell_error && result != '0' && a:cmd != ''
          let result = s:screen{g:ScreenImpl}.send(a:cmd)
        endif
      endif

    else
      let result = s:screen{g:ScreenImpl}.newTerminal()
      if has('win32') || has('win64') || has('win32unix') || has('mac')
        " like, the sleep hack below, but longer for windows.
        sleep 3000m
      else
        " looks like this is needed for ubuntu as well... ugg.
        sleep 1000m
      endif

      if !v:shell_error && result != '0'
        " Hack, but should be plenty of time to let screen get to a state
        " where it will apply the title command.
        sleep 500m
        let result = s:screen{g:ScreenImpl}.setTitle()

        " execute the supplied command if any
        if !v:shell_error && a:cmd != ''
          let result = s:screen{g:ScreenImpl}.send(a:cmd)
        endif
      endif
    endif
  endif

  if v:shell_error
    delcommand ScreenQuit
    echoerr result
  else
    if !exists(':ScreenSend')
      command -nargs=0 -range=% ScreenSend :call <SID>ScreenSend(<line1>, <line2>)
      let g:ScreenShellSend = s:ScreenSendFuncRef()
      let g:ScreenShellFocus = s:ScreenFocusFuncRef()
      " remove :ScreenShell command to avoid accidentally calling it again.
      delcommand ScreenShell
      delcommand ScreenShellAttach
      if exists(':ScreenShellVertical')
        delcommand ScreenShellVertical
      endif
    endif
  endif
endfunction " }}}

" s:ScreenSend(string or list<string> or line1, line2) {{{
" Send lines to the screen shell.
function! s:ScreenSend(...)
  if a:0 == 1
    let argtype = type(a:1)
    if argtype == 1
      let lines = split(a:1, "\n")
    elseif argtype == 3
      let lines = a:1
    else
      echoe 'ScreenShell: Argument must be a string or list.'
      return
    endif
  elseif a:0 == 2
    if type(a:1) != 0 || type(a:2) != 0
      echoe 'ScreenShell: Arguments must be positive integer line numbers.'
      return
    endif

    let lines = getline(a:1, a:2)
    let mode = visualmode(1)
    if mode != '' && line("'<") == a:1
      if mode == "v"
        let start = col("'<") - 1
        let end = col("'>") - 1
        " slice in end before start in case the selection is only one line
        let lines[-1] = lines[-1][: end]
        let lines[0] = lines[0][start :]
      elseif mode == "\<c-v>"
        let start = col("'<")
        if col("'>") < start
          let start = col("'>")
        endif
        let start = start - 1
        call map(lines, 'v:val[start :]')
      endif
    endif
  else
    echoe 'ScreenShell: Invalid number of arguments for ScreenSend.'
    return
  endif

  if g:ScreenShellExpandTabs
    let expanded = ''
    let index = 0
    while index < &shiftwidth
      let expanded .= ' '
      let index += 1
    endwhile
    call map(lines, 'substitute(v:val, "\\t", expanded, "g")')
  endif

  let tmp = tempname()
  call writefile(lines, tmp)
  try
    let result = s:screen{g:ScreenImpl}.sendTempBuffer(tmp)
  finally
    call delete(tmp)
  endtry

  if v:shell_error
    echoerr result
  endif
endfunction " }}}

" s:ScreenFocus() {{{
function! s:ScreenFocus()
  let result = s:screen{g:ScreenImpl}.focus()

  if v:shell_error
    echoerr result
  endif
endfun " }}}

" s:ScreenSendFuncRef() {{{
function! s:ScreenSendFuncRef()
  let sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_ScreenSendFuncRef$')
  return function(printf('<SNR>%s_ScreenSend', sid))
endfun " }}}

" s:ScreenFocusFuncRef() {{{
function! s:ScreenFocusFuncRef()
  let sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_ScreenFocusFuncRef$')
  return function(printf('<SNR>%s_ScreenFocus', sid))
endfun " }}}

" s:ScreenQuit(onleave) {{{
" Quit the current screen session (short cut to manually quiting vim and
" closing all screen windows.
function! s:ScreenQuit(onleave)
  if exists('g:ScreenShellBootstrapped')
    if !a:onleave
      wa
    endif

    let bufend = bufnr('$')
    let bufnum = 1
    while bufnum <= bufend
      if bufnr(bufnum) != -1
        call setbufvar(bufnum, '&swapfile', 0)
      endif
      let bufnum = bufnum + 1
    endwhile
  else
    call screen#ScreenShellCommands()
    delcommand ScreenQuit
    delcommand ScreenSend
    unlet g:ScreenShellSend
    unlet g:ScreenShellFocus
    augroup screen_shell
      autocmd!
    augroup END
  endif

  let result = s:screen{g:ScreenImpl}.quit()

  if v:shell_error
    if result !~ 'No screen session found'
      echoerr result
    endif
  endif
endfunction " }}}

" s:ScreenCmdName(cmd) {{{
" Generate a name for the given command.
function! s:ScreenCmdName(cmd)
  let cmd = substitute(a:cmd, '^\s*\(\S\+\)\s.*', '\1', '')
  " if the command is a path to one, use the tail of the path
  if cmd =~ '/'
    let cmd = fnamemodify(cmd, ':t')
  endif
  return cmd
endfunction " }}}

" s:StartTerminal(command) {{{
function! s:StartTerminal(command)
  let terminal = s:GetTerminal()
  if !s:ValidTerminal(terminal)
    echoerr 'Unable to find a terminal, please set g:ScreenShellTerminal'
    return
  endif

  " handle using cygwin bash
  if has('win32') || has('win64') || has('win32unix')
    let result = ''
    let command = 'start "' . terminal . '"'
    if has('win32unix')
      let command = substitute(command, '\', '/', 'g')
      let command = 'cmd /c ' . command
    endif
    let command .= ' --login -c "' . a:command . '"'
    exec 'silent !' . command
    redraw!

  elseif has('mac') && has('gui_running')
    let result = ''
    exec s:MacGuiCmd(a:command, terminal)

  " gnome-terminal needs quotes around the screen call, but konsole and
  " rxvt based terms (urxvt, aterm, mrxvt, etc.) don't work properly with
  " quotes.  xterm seems content either way, so we'll treat gnome-terminal
  " as the odd ball here.
  elseif terminal == 'gnome-terminal'
    let result = system(terminal . ' -e "' . a:command . '" &')

  else
    let result = system(terminal . ' -e ' . a:command . ' &')
  endif
  return result
endfunction " }}}

" s:GetScreenSessions() {{{
" Gets a list of screen [session, state] pairs.
function! s:GetScreenSessions()
  let results = split(system('screen -wipe'), "\n")
  call filter(results, 'v:val =~ "(\\w\\+)"')
  call map(results, '[' .
    \ 'substitute(v:val, "^\\s*\\(\\S*\\).*", "\\1", ""), ' .
    \ 'tolower(substitute(v:val, "(\\(\\w\\+\\))$", "\\1", ""))]')
  return results
endfunction " }}}

" s:GetSize() {{{
function! s:GetSize()
  if s:orientation == 'vertical'
    let size = g:ScreenShellWidth
    let sizefunc = 'winwidth'
  else
    let size = g:ScreenShellHeight
    let sizefunc = 'winheight'
  endif

  if size <= 0
    exec 'let size = ' . sizefunc . '(winnr()) / 2'
  endif
  return size
endfunction " }}}

" s:GetTerminal() {{{
" Generate a name for the given command.
function! s:GetTerminal()
  if g:ScreenShellTerminal == ''
    for term in s:terminals
      if s:ValidTerminal(term)
        let g:ScreenShellTerminal = term
        break
      endif
    endfor
  endif
  return g:ScreenShellTerminal
endfunction " }}}

" s:ValidTerminal(term) {{{
function! s:ValidTerminal(term)
  if a:term == ''
    return 0
  endif

  " assumes that Terminal.app, or whatever the user may have set, is available
  if has('mac') && has('gui_running')
    return 1
  endif

  if has('win32unix')
    if !executable(a:term)
      let term = substitute(a:term, '\', '/', 'g')
      let term = substitute(system('cygpath "' . term . '"'), '\n', '', 'g')
      return executable(term)
    endif
  endif

  return executable(a:term)
endfunction " }}}

" s:MacGuiCmd(cmd, term) {{{
function! s:MacGuiCmd(cmd, term)
  if a:term != '0'
    return 'silent !osascript -e "tell application \"' . a:term .
      \ '\"" -e "do script \"' . a:cmd . '\"" -e "end tell"'
  endif

  let cmd = substitute(a:cmd, '"', "'", 'g')
  return 'silent !osascript -e "do shell script \"' . cmd . '\""'
endfunction " }}}

" CommandCompleteScreenSessions(argLead, cmdLine, cursorPos) {{{
function! screen#CommandCompleteScreenSessions(argLead, cmdLine, cursorPos)
  let cmdLine = strpart(a:cmdLine, 0, a:cursorPos)
  let cmdTail = strpart(a:cmdLine, a:cursorPos)
  let argLead = substitute(a:argLead, cmdTail . '$', '', '')

  if g:ScreenImpl == 'GnuScreen'
    let sessions = s:GetScreenSessions()
    if has('win32') || has('win64') || has('win32unix')
      call filter(sessions, 'v:val[1] != "detached"')
    endif
    call map(sessions, 'v:val[0]')
    if cmdLine !~ '[^\\]\s$'
      call filter(sessions, 'v:val =~ "^' . argLead . '"')
    endif

    return sessions
  endif

  return []
endfunction " }}}

let s:screenGnuScreen = {}

function s:screenGnuScreen.isValid() dict " {{{
  if !executable('screen')
    echoerr 'gnu screen not found in your path'
    return 0
  endif
  return 1
endfunction " }}}

function s:screenGnuScreen.attachSession(session) dict " {{{
  let sessions = s:GetScreenSessions()
  if a:session != ''
    let session = []
    for s in sessions
      if s[0] == a:session
        let session = s
        break
      endif
    endfor

    if len(session) == 0
      echoerr 'unable to find the gnu screen session "' . a:session . '"'
      return
    endif
  elseif len(sessions) > 0
    if has('win32') || has('win64') || has('win32unix')
      call filter(sessions, 'v:val[1] != "detached"')
    endif
    let session = sessions[0]
  else
    echoerr 'unable to find any gnu screen sessions'
    return
  endif

  if session[1] == 'detached'
    if has('win32') || has('win64') || has('win32unix')
      echoerr 'attaching to a session in the "Detached" state is not ' .
        \ 'supported on windows due to deficiencies in the cygwin version ' .
        \ 'of gnu screen.'
      return
    endif
    let result = s:screen{g:ScreenImpl}.newTerminalResume()
    if result == '0'
      return
    endif
    if v:shell_error
      echoerr result
    endif
  endif

  return session[0]
endfunction " }}}

function s:screenGnuScreen.bootstrap(server, sessionfile, cmd) dict " {{{
  let vertical = s:orientation == 'vertical' ? 'Vertical' : ''
  exec 'silent! !screen -S ' . g:ScreenShellSession .
    \ ' vim ' . a:server .
    \ '-c "silent source ' . escape(a:sessionfile, ' ') . '" ' .
    \ '-c "ScreenShell' . vertical . ' ' . a:cmd . '"'
endfunction " }}}

function s:screenGnuScreen.newSessionName() dict " {{{
  return substitute(tempname(), '\W', '', 'g')
endfunction " }}}

function s:screenGnuScreen.newTerminal() dict " {{{
  return s:StartTerminal('screen -S ' . g:ScreenShellSession)
endfunction " }}}

function s:screenGnuScreen.newTerminalMulti() dict " {{{
  return s:StartTerminal('screen -S ' . g:ScreenShellSession . ' -x')
endfunction " }}}

function s:screenGnuScreen.newTerminalResume() dict " {{{
  return s:StartTerminal('screen -r ' . g:ScreenShellSession)
endfunction " }}}

function s:screenGnuScreen.newWindow(focus) dict " {{{
  return self.exec(printf(
    \ '-X eval "screen -t %s" %s',
    \ g:ScreenShellWindow,
    \ a:focus ? '""' : '"other"'))
endfunction " }}}

function s:screenGnuScreen.openRegion() dict " {{{
  let splitcmd = 'split'
  if s:orientation == 'vertical'
    if g:ScreenShellGnuScreenVerticalSupport == 'patch'
      let splitcmd = 'vert_split'
    elseif g:ScreenShellGnuScreenVerticalSupport == 'native'
      let splitcmd = 'split -v'
    else
      echohl WarningMsg
      echom 'Unsupported g:ScreenShellGnuScreenVerticalSupport value "' .
        \ g:ScreenShellGnuScreenVerticalSupport . '". ' .
        \ 'Supported values included "patch" or "native".'
      echohl Normal
      let s:orientation = ''
    endif
  endif

  let focus = g:ScreenShellInitialFocus == 'shell' ? '' : ' "focus up"'
  let chdir = exists('g:ScreenShellBootstrapped') ? '' : '"chdir \"' . getcwd() . '\"" '
  let result = self.exec('-X eval ' .
    \ '"' . splitcmd . '" ' .
    \ '"focus down" ' .
    \ '"resize ' . s:GetSize() . '" ' .
    \ chdir .
    \ '"screen -t ' . g:ScreenShellWindow . '"' .
    \ focus)

  " if we ran a chdir, reset it
  if chdir != ''
    call self.exec('-X eval "chdir"')
  endif

  return result
endfunction " }}}

function s:screenGnuScreen.setTitle() dict " {{{
  return self.exec('-X title ' . g:ScreenShellWindow)
endfunction " }}}

function s:screenGnuScreen.send(value) dict " {{{
  let tmp = tempname()
  call writefile([a:value], tmp)
  try
    let result = s:screen{g:ScreenImpl}.sendTempBuffer(tmp)
  finally
    call delete(tmp)
  endtry
  return result
endfunction " }}}

function s:screenGnuScreen.sendTempBuffer(tmp) dict " {{{
  if exists('g:ScreenShellWindow')
    let result = self.exec(
      \ '-p ' . g:ScreenShellWindow .  ' -X eval ' .
      \ '"msgminwait 0" ' .
      \ '"msgwait 0" ' .
      \ '"readbuf ' . a:tmp . '" ' .
      \ '"at ' . g:ScreenShellWindow . ' paste ." ' .
      \ '"msgwait 5" ' .
      \ '"msgminwait 1"')
  else
    let result = self.exec(
      \ '-X eval ' .
      \ '"msgminwait 0" ' .
      \ '"msgwait 0" ' .
      \ '"readbuf ' . a:tmp . '" ' .
      \ '"paste ." ' .
      \ '"msgwait 5" ' .
      \ '"msgminwait 1"')
  endif
  return result
endfunction " }}}

function s:screenGnuScreen.focus() dict " {{{
  return self.exec('-X focus bottom')
endfunction " }}}

function s:screenGnuScreen.quit() dict " {{{
  return self.exec('-X quit')
endfunction " }}}

function s:screenGnuScreen.exec(cmd) dict " {{{
  let cmd = 'screen '
  if exists('g:ScreenShellSession')
    let cmd .= '-S ' . g:ScreenShellSession . ' '
  endif
  let cmd .= a:cmd

  if has('win32unix')
    let result = ''
    exec 'silent! !' . cmd
    redraw!
  elseif has('mac') && has('gui_running')
    let term = s:GetTerminal()
    let result = ''
    exec s:MacGuiCmd(cmd, '0')
  else " system() works for windows gvim too
    let result = system(cmd)
  endif
  return result
endfunction " }}}

let s:screenTmux = {}

function s:screenTmux.isValid() dict " {{{
  if !executable('tmux')
    echoerr 'tmux not found in your path'
    return 0
  endif

  if has('win32') || has('win64')
    echoerr 'ScreenShell does not currently support tmux on windows.'
    return 0
  endif

  return 1
endfunction " }}}

function s:screenTmux.attachSession(session) dict " {{{
  " TODO: currently unable to implement this since we use -S which creates a
  " new server, which a tmux list-sessions wouldn't be able to talk to.  As
  " for sessions created on the default server, we can get the list of
  " sessions, but tmux doesn't appear to have a way to send commands targeting
  " a specific session, which is why we use -S to target servers.
  echom 'Attaching to an existing session is currently not supported with tmux.'
  return
endfunction " }}}

function s:screenTmux.bootstrap(server, sessionfile, cmd) dict " {{{
  let vertical = s:orientation == 'vertical' ? 'Vertical' : ''
  exec printf('silent! !tmux %s -S %s new-session ' .
    \ '"vim %s -c \"silent source %s\" -c \"ScreenShell' . vertical . ' %s\""',
    \ g:ScreenShellTmuxInitArgs, g:ScreenShellSession,
    \ a:server, escape(a:sessionfile, ' '), a:cmd)
endfunction " }}}

function s:screenTmux.newSessionName() dict " {{{
  return tempname()
endfunction " }}}

function s:screenTmux.newTerminal() dict " {{{
  return s:StartTerminal(printf(
    \ 'tmux %s -S %s', g:ScreenShellTmuxInitArgs, g:ScreenShellSession))
endfunction " }}}

function s:screenTmux.newTerminalResume() dict " {{{
  return s:StartTerminal(printf(
    \ 'tmux %s -S %s  attach-session',
    \ g:ScreenShellTmuxInitArgs, g:ScreenShellSession))
endfunction " }}}

function s:screenTmux.newWindow(focus) dict " {{{
  return self.exec('new-window -n ' . g:ScreenShellWindow . (a:focus ? '' : ' -d'))
endfunction " }}}

function s:screenTmux.openRegion() dict " {{{
  let orient = s:orientation == 'vertical' ? '-h ' : ''
  let direction = s:orientation == 'vertical' ? '-L ' : '-U'
  let focus = g:ScreenShellInitialFocus == 'shell' ? '' : (' ; select-pane ' . direction)
  let result = self.exec(
    \ 'split ' .  orient . '-l ' . s:GetSize() . ' ; ' .
    \ 'rename-window ' . g:ScreenShellWindow .
    \ focus)
  if v:shell_error
    return result
  endif
endfunction " }}}

function s:screenTmux.setTitle() dict " {{{
  return self.exec('rename-window ' . g:ScreenShellWindow)
endfunction " }}}

function s:screenTmux.send(value) dict " {{{
  let tmp = tempname()
  call writefile([a:value], tmp)
  try
    let result = s:screen{g:ScreenImpl}.sendTempBuffer(tmp)
  finally
    call delete(tmp)
  endtry
  return result
endfunction " }}}

function s:screenTmux.sendTempBuffer(tmp) dict " {{{
  let result = self.focusWindow()
  if v:shell_error
    return result
  endif

  " hacky: how can we be sure the shell is at pane index 1 and vim at index 0?
  if exists('g:ScreenShellBootstrapped')
    call self.exec('select-pane -t 1')
  endif
  let result = self.exec(printf(
    \ 'load-buffer %s ; ' .
    \ 'paste-buffer', a:tmp
    \ ))
  if exists('g:ScreenShellBootstrapped')
    call self.exec('select-pane -t 0')
  endif

  return result
endfunction " }}}

function s:screenTmux.focus() dict " {{{
  return self.exec('select-pane -D')
endfunction " }}}

function s:screenTmux.quit() dict " {{{
  return self.exec('kill-session')
endfunction " }}}

function s:screenTmux.exec(cmd) dict " {{{
  let cmd = 'tmux '

  if exists('g:ScreenShellSession')
    let cmd .= '-S ' . g:ScreenShellSession . ' '
  endif

  return system(cmd . escape(a:cmd, ';'))
endfunction " }}}

function s:screenTmux.focusWindow() dict " {{{
  if !exists('g:ScreenShellWindow')
    return
  endif
  let result = self.exec('list-windows')
  if v:shell_error
    return result
  endif

  let windows = filter(
    \ split(result, "\n"),
    \ 'v:val =~ "^\\s*\\d\\+:\\s\\+' . g:ScreenShellWindow . '"')
  if len(windows)
    let window = substitute(windows[0], '^\s*\(\d\+\):.*', '\1', '')
    return self.exec('select-window -t:' . window)
  endif
endfunction " }}}

let &cpo = s:save_cpo

" vim:ft=vim:fdm=marker
