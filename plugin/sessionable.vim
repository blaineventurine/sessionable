if exists('g:loaded_sessionable') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

let g:in_pager_mode = 0

let LuaSaveSession = luaeval('require("sessionable").SaveSession')
let LuaRestoreSession = luaeval('require("sessionable").RestoreSession')
let LuaDeleteSessionByName = luaeval('require("sessionable").DeleteSessionByName')
let LuaDisableAutoSave = luaeval('require("sessionable").DisableAutoSave')

let LuaAutoSaveSession = luaeval('require("sessionable").AutoSaveSession')
" let LuaAutoRestoreSession = luaeval('require("sessionable").AutoRestoreSession')

function! CompleteSessions(A,L,P) abort
  return luaeval('require"sessionable".CompleteSessions()')
endfunction

" Available commands
command! -nargs=* SaveSession call LuaSaveSession(expand('<args>'))
command! -nargs=* RestoreSession call LuaRestoreSession(expand('<args>'))
command! -nargs=* -complete=custom,CompleteSessions DeleteSession call LuaDeleteSessionByName(<f-args>)
command! -nargs=* DisableAutoSave call LuaDisableAutoSave()

aug StdIn
  autocmd!
  autocmd StdinReadPre * let g:in_pager_mode = 1
aug END

" augroup sessionable 
"   autocmd!
"   autocmd VimEnter * nested call LuaAutoRestoreSession()
"   autocmd VimLeave * call LuaAutoSaveSession()

"   " TODO: Experiment with saving session on more than just VimEnter and VimLeave
"   " autocmd BufWinEnter * if g:in_pager_mode == 0 | call LuaAutoSaveSession() | endif
"   " autocmd BufWinLeave * if g:in_pager_mode == 0 | call LuaAutoSaveSession() | endif
" augroup end

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_auto_session = 1