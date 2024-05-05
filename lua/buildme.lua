-- nvim-buildme
-- By Olivier Roques
-- github.com/ojroques

-------------------- VARIABLES -----------------------------
local api, cmd, fn, vim = vim.api, vim.cmd, vim.fn, vim
local fmt = string.format
local nkeys = api.nvim_replace_termcodes('<C-\\><C-n>G', true, false, true)
local job_buffer_build, job_id_build
local job_buffer_run, job_id_run
local M = {}

-------------------- OPTIONS -------------------------------
local options = {
  buildfile = '.buildme.sh',  -- the build file to execute
  runfile = '.runme.sh',      -- the run file to execute
  interpreter = 'bash',       -- the interpreter to use (bash, python, ...)
  force = '--force',          -- the option to pass when the bang is used
  wincmd = '',                -- a window command to run prior to a build job
}

-------------------- PRIVATE -------------------------------
local function echo(hlgroup, msg)
  cmd(fmt('echohl %s', hlgroup))
  cmd(fmt('echo "[buildme] %s"', msg))
  cmd('echohl None')
end

local function buffer_exists(buffer)
  return buffer and fn.buflisted(buffer) == 1
end

local function job_running(id)
  return id and fn.jobwait({id}, 0)[1] == -1
end

local function job_exit(id, exit_code, _)
  local hlgroup = exit_code == 0 and 'None' or 'WarningMsg'
  local msg = fmt('Job %d has finished with exit code %d', id, exit_code)
  echo(hlgroup, msg)
end

local function edit(file)
  cmd(fmt('edit %s', file))
  -- Make the build file executable
  local autocmd = 'au BufWritePost <buffer> call jobstart("chmod +x %s")'
  cmd(fmt(autocmd, file))
end

local function jump(buffer, kind)
  if not buffer_exists(buffer) then
    echo('WarningMsg', 'No ' .. kind .. ' buffer')
    return
  end
  local job_window = fn.bufwinnr(buffer)
  -- Jump to the buffer window if it exists
  if job_window ~= -1 then
    cmd(fmt('%d wincmd w', job_window))
    return
  end
  -- Run window command
  if options.wincmd ~= '' then
    cmd(options.wincmd)
  end
  cmd(fmt('buffer %d', buffer))
end

local function stop(id)
  if job_running(id) then
    fn.jobstop(id)
    echo('None', fmt('Stopped job %d', id))
    return
  end
  echo('None', 'No job to stop')
end

local function job_run(bang, buffer, buffer_name, file, force, id, kind)
  if job_running(id) then
    echo('ErrorMsg', fmt('A %s job is already running (id: %d)', kind, id))
    return buffer, id
  end
  if fn.filereadable(file) == 0 then
    echo('WarningMsg', fmt("%s file '%s' not found", kind:gsub("^%l", string.upper), file))
    edit(file)
    return nil, nil
  end
  -- Format interpreter string
  local interpreter = ''
  if options.interpreter ~= '' then
    interpreter = fmt('%s ', options.interpreter)
  end
  if bang and force ~= '' then
    force = fmt(' %s', force)
  end
  -- Create scratch buffer
  if not buffer_exists(buffer) then
    buffer = api.nvim_create_buf(true, true)
  end
  -- Jump to buffer
  jump(buffer, kind)
  -- Set buffer options
  api.nvim_buf_set_option(buffer, 'filetype', 'buildme')
  api.nvim_buf_set_option(buffer, 'modified', false)
  -- Start build job
  local command = fmt('%s%s%s', interpreter, file, force)
  id = fn.termopen(command, {on_exit = job_exit})
  -- Rename buffer
  api.nvim_buf_set_name(buffer, buffer_name)
  -- Exit terminal mode
  api.nvim_feedkeys(nkeys, 'n', false)
  return buffer, id
end

-------------------- PUBLIC --------------------------------
function M.editbuild()
  edit(options.buildfile)
end

function M.editrun()
  edit(options.runfile)
end

function M.jumpbuild()
  jump(job_buffer_build, 'buildme')
end

function M.jumprun()
  jump(job_buffer_run, 'runme')
end

function M.build(bang)
  job_buffer_build, job_id_build = job_run(bang, job_buffer_build, 'buildme://buildjob', options.buildfile, options.force, job_id_build, 'build')
end

function M.run(bang)
  job_buffer_run, job_id_run = job_run(bang, job_buffer_run, 'buildme://runjob', options.runfile, "", job_id_run, 'run')
end

function M.stopbuild()
  stop(job_id_build)
end

function M.stoprun()
  stop(job_id_run)
end

-------------------- SETUP ---------------------------------
function M.setup(user_options)
  options = vim.tbl_extend('keep', user_options, options)
  if user_options then
    options = vim.tbl_extend('force', options, user_options)
  end
end

------------------------------------------------------------
return M
