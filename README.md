# nvim-buildme

A Neovim plugin to build or run a project using the built-in terminal. It is
very small (~100 SLOC) and written entirely in Lua. See [example](#example)
below for a demo.

## Installation
With [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {'ojroques/nvim-buildme'}
```

With [paq-nvim](https://github.com/savq/paq-nvim):
```lua
paq {'ojroques/nvim-buildme'}
```

## Usage
The plugin checks for a build/run file and runs it in a terminal buffer. By default,
this file is a shell script named `.buildme.sh`/`.runme.sh`, resp., located in the current
working directory.

If you want your working directory to be automatically set to your project root,
you should check [vim-rooter](https://github.com/airblade/vim-rooter).

To run a build/run job:
```vim
:BuildMe
:RunMe
:BuildRunMe

" Arguments may be optionally supplied, except to BuildRunMe:
:BuildMe -j4 putty
:RunMe --file @session
:BuildRunMe

" In the absence of arguments, default arguments, if any, will be used. These may be edited or set:
:BuildMeEditArgs
:RunMeEditArgs
:BuildMeEditArgs -j4 putty
:RunMeEditArgs --file @session

" An optional working directory specific to both of {Build,Run}Me may be edited and set; if
" the save_current_wd option below is configured as true, it will be set to the initial working
" directory of the editor at startup. The two commands are aliases of each other for convenience.
:BuildMeEditCwd
:RunMeEditCwd
:BuildMeEditCwd ../..
:RunMeEditCwd ../..
```
Use `:BuildMe!` to pass the `force` option (by default `--force`,
[configurable](#configuration)) to the final command.

To stop a running build/run job:
```vim
:BuildMeStop
:RunMeStop
```

To edit the build/run file:
```vim
:BuildMeEdit
:RunMeEdit
```

To jump to the buildme/runme buffer:
```vim
:BuildMeJump
:RunMeJump
```

## Configuration
You can pass options to the provided `setup()` function. Here are all available
options with their default settings:
```lua
require('buildme').setup {
  buildfile = '.buildme.sh',       -- the build file to execute
  runfile = '.runme.sh',           -- the run file to execute
  close_build_on_exit = 'always',  -- close build window on exit: never, on_error, on_success, always
  close_run_on_exit = 'always',    -- close run window on exit: never, on_error, on_success, always
  edit_on_nonexistent = true,      -- edit non-existent build/run file on build/run
  interpreter = 'sh',              -- the interpreter to use (sh, bash, python, ...)
  force = '--force',               -- the option to pass when the bang is used
  save_current_wd = false,         -- save working directory of editor at startup; used to look for {build,run}file
  wincmd = '',                     -- a command to run prior to a build job (split, vsplit, ...)
}
```

## Example
![demo](https://user-images.githubusercontent.com/23409060/188605771-4d90a9af-a11b-4e85-8cc5-325c2dbbfac6.gif)

Here the buildfile (in the right window) is a simple shell script with a single
command: `make everything`. Running `:BuildMe` executes this script
asynchronously in a new terminal buffer.

This is particularly useful when your build process is more complex than simply
running `make`, or if you want to run a Python script immediately after editing
it for instance.

Here's a full example of a buildme file for CMake:
[buildme.sh](https://gist.github.com/ojroques/9824c85cfd1eabafb3c0be5530c35b5a)

## License
[LICENSE](./LICENSE)
