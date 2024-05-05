" nvim-buildme
" By Olivier Roques
" github.com/ojroques

if exists('g:loaded_buildme')
  finish
endif

command! -nargs=* -bang BuildMe lua require('buildme').build('<bang>' == '!', '<args>')
command! -nargs=* RunMe lua require('buildme').run('', '<args>')
command! BuildMeEdit lua require('buildme').editbuild()
command! -nargs=* BuildMeEditArgs lua require('buildme').editargsbuild('<args>')
command! -nargs=* BuildMeEditCwd lua require('buildme').editcwd('<args>')
command! RunMeEdit lua require('buildme').editrun()
command! -nargs=* RunMeEditArgs lua require('buildme').editargsrun('<args>')
command! -nargs=* RunMeEditCwd lua require('buildme').editcwd('<args>')
command! BuildMeJump lua require('buildme').jumpbuild()
command! RunMeJump lua require('buildme').jumprun()
command! BuildMeStop lua require('buildme').stopbuild()
command! RunMeStop lua require('buildme').stoprun()

let g:loaded_buildme = 1
