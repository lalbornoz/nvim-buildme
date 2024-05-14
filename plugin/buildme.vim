"
" Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
" Based on <https://github.com/ojroques/nvim-buildme> by Olivier Roques
"

if exists('g:loaded_buildme')
	finish
endif

command! -nargs=* -bang BuildMe lua require('roarie-buildme').build('<bang>' == '!', '<args>')
command! -nargs=* RunMe lua require('roarie-buildme').run('', '<args>')
command! -bang BuildRunMe lua require('roarie-buildme').buildrun('<bang>' == '!', '')

command! BuildMeEdit lua require('roarie-buildme').editbuild()
command! -nargs=* BuildMeEditArgs lua require('roarie-buildme').editargsbuild('<args>')
command! -nargs=* BuildMeEditCwd lua require('roarie-buildme').editcwd('<args>')

command! RunMeEdit lua require('roarie-buildme').editrun()
command! -nargs=* RunMeEditArgs lua require('roarie-buildme').editargsrun('<args>')
command! -nargs=* RunMeEditCwd lua require('roarie-buildme').editcwd('<args>')

command! BuildMeJump lua require('roarie-buildme').jumpbuild()
command! RunMeJump lua require('roarie-buildme').jumprun()

command! BuildMeStop lua require('roarie-buildme').stopbuild()
command! RunMeStop lua require('roarie-buildme').stoprun()

command! -complete=customlist,s:AutoClose -nargs=1 BuildMeSetAutoClose lua require('roarie-buildme').setautoclosebuild('<args>')
command! -complete=customlist,s:AutoClose -nargs=1 RunMeSetAutoClose lua require('roarie-buildme').setautocloserun('<args>')

fun! s:AutoClose(A, L, P)
	return ["always", "on_error", "on_success", "never"]
endfun

let g:loaded_buildme = 1

" vim:filetype=vim noexpandtab sw=8 ts=8 tw=0
