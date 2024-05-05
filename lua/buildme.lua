-- nvim-buildme
-- By Olivier Roques
-- github.com/ojroques

-------------------- VARIABLES -----------------------------
local api, cmd, fn, vim = vim.api, vim.cmd, vim.fn, vim
local fmt = string.format
local nkeys = api.nvim_replace_termcodes('<C-\\><C-n>G', true, false, true)
local job_buffer, job_id
local M = {}

-------------------- OPTIONS -------------------------------
local options = {
  buildfile = '.buildme.sh',  -- the build file to execute
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

local function buffer_exists()
  return job_buffer and fn.buflisted(job_buffer) == 1
end

local function job_running()
  return job_id and fn.jobwait({job_id}, 0)[1] == -1
end

local function job_exit(job_id, exit_code, _)
  local hlgroup = exit_code == 0 and 'None' or 'WarningMsg'
  local msg = fmt('Job %d has finished with exit code %d', job_id, exit_code)
  echo(hlgroup, msg)
end

-------------------- PUBLIC --------------------------------
function M.edit()
  cmd(fmt('edit %s', options.buildfile))
  -- Make the build file executable
  local autocmd = 'au BufWritePost <buffer> call jobstart("chmod +x %s")'
  cmd(fmt(autocmd, options.buildfile))
end

function M.jump()
  if not buffer_exists() then
    echo('WarningMsg', 'No buildme buffer')
    return
  end
  local job_window = fn.bufwinnr(job_buffer)
  -- Jump to the buffer window if it exists
  if job_window ~= -1 then
    cmd(fmt('%d wincmd w', job_window))
    return
  end
  -- Run window command
  if options.wincmd ~= '' then
    cmd(options.wincmd)
  end
  cmd(fmt('buffer %d', job_buffer))
end

function M.build(bang)
  if job_running() then
    echo('ErrorMsg', fmt('A build job is already running (id: %d)', job_id))
    return
  end
  if fn.filereadable(options.buildfile) == 0 then
    echo('WarningMsg', fmt("Build file '%s' not found", options.buildfile))
    M.edit()
    return
  end
  -- Format interpreter string
  local interpreter = ''
  local force = ''
  if options.interpreter ~= '' then
    interpreter = fmt('%s ', options.interpreter)
  end
  if bang and options.force ~= '' then
    force = fmt(' %s', options.force)
  end
  -- Create scratch buffer
  if not buffer_exists() then
    job_buffer = api.nvim_create_buf(true, true)
  end
  -- Jump to buffer
  M.jump()
  -- Set buffer options
  api.nvim_buf_set_option(job_buffer, 'filetype', 'buildme')
  api.nvim_buf_set_option(job_buffer, 'modified', false)
  -- Start build job
  local command = fmt('%s%s%s', interpreter, options.buildfile, force)
  job_id = fn.termopen(command, {on_exit = job_exit})
  -- Rename buffer
  api.nvim_buf_set_name(job_buffer, 'buildme://job')
  -- Exit terminal mode
  api.nvim_feedkeys(nkeys, 'n', false)
end

function M.stop()
  if job_running() then
    fn.jobstop(job_id)
    echo('None', fmt('Stopped job %d', job_id))
    return
  end
  echo('None', 'No job to stop')
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
