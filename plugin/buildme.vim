" nvim-buildme
" By Olivier Roques
" github.com/ojroques

if exists('g:loaded_buildme')
  finish
endif

command! -bang BuildMe lua require('buildme').build('<bang>' == '!')
command! RunMe lua require('buildme').run('')
command! BuildMeEdit lua require('buildme').editbuild()
command! RunMeEdit lua require('buildme').editrun()
command! BuildMeJump lua require('buildme').jumpbuild()
command! RunMeJump lua require('buildme').jumprun()
command! BuildMeStop lua require('buildme').stopbuild()
command! RunMeStop lua require('buildme').stoprun()

let g:loaded_buildme = 1
