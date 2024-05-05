" nvim-buildme
" By Olivier Roques
" github.com/ojroques

if exists('g:loaded_buildme')
  finish
endif

command! -nargs=* -bang BuildMe lua require('buildme').build('<bang>' == '!', '<args>')
command! -nargs=* RunMe lua require('buildme').run('', '<args>')
command! BuildMeEdit lua require('buildme').editbuild()
command! BuildMeEditArgs lua require('buildme').editargsbuild()
command! RunMeEdit lua require('buildme').editrun()
command! RunMeEditArgs lua require('buildme').editargsrun()
command! BuildMeJump lua require('buildme').jumpbuild()
command! RunMeJump lua require('buildme').jumprun()
command! BuildMeStop lua require('buildme').stopbuild()
command! RunMeStop lua require('buildme').stoprun()

let g:loaded_buildme = 1
