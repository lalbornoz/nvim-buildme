-- nvim-buildme
-- By Olivier Roques
-- github.com/ojroques

-------------------- VARIABLES -----------------------------
local api, cmd, fn, vim = vim.api, vim.cmd, vim.fn, vim
local fmt = string.format
local nkeys = api.nvim_replace_termcodes('<C-\\><C-n>G', true, false, true)
local job_buffer_build, job_id_build
local job_buffer_run, job_id_run
local args_default_build
local args_default_run
local current_wd
local M = {}

-------------------- OPTIONS -------------------------------
local options = {
  buildfile = '.buildme.sh',    -- the build file to execute
  runfile = '.runme.sh',        -- the run file to execute
  edit_on_nonexistent = true,   -- edit non-existent build/run file on build/run
  interpreter = 'bash',         -- the interpreter to use (bash, python, ...)
  force = '--force',            -- the option to pass when the bang is used
  save_current_wd = false,      -- save working directory of editor at startup; used to look for {build,run}file
  wincmd = '',                  -- a window command to run prior to a build job
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

local function editargs(args, args_new, prompt_kind)
  if args_new ~= "" then
    return args_new
  else
    vim.ui.input({
      default=args,
      prompt=fmt('%s default arguments: ', prompt_kind),
      }, function(input)
        args = input
      end)
    return args
  end
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

local function job_check_file(file, kind)
  if fn.filereadable(file) == 0 then
    echo('WarningMsg', fmt("%s file '%s' not found", kind:gsub("^%l", string.upper), file))
    if options.edit_on_nonexistent then
      edit(file)
    end
    return false
  else
    return true
  end
end

local function job_run(args, args_default, bang, buffer, buffer_name, file, force, id, current_wd, kind)
  if job_running(id) then
    echo('ErrorMsg', fmt('A %s job is already running (id: %d)', kind, id))
    return buffer, id
  end
  if (current_wd ~= nil) and (not job_check_file(current_wd .."/".. file, kind)) then
    return buffer, id
  elseif (current_wd == nil) and (not job_check_file(file, kind)) then
    return buffer, id
  end
  -- Format interpreter string
  local interpreter = ''
  if options.interpreter ~= '' then
    interpreter = fmt('%s ', options.interpreter)
  end
  if bang and force ~= '' then
    force = fmt(' %s', force)
  end
  if args ~= '' then
    args = fmt(' %s', args)
  elseif (args_default ~= nil) and (args_default ~= '') then
    args = fmt(' %s', args_default)
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
  local command = fmt("%s%s%s%s", interpreter, fn.shellescape(file), force, args)
  id = fn.termopen(command, {cwd = current_wd, on_exit = job_exit})
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

function M.editargsbuild(args_new)
  args_default_build = editargs(args_default_build, args_new, "BuildMe")
end

function M.editrun()
  edit(options.runfile)
end

function M.editargsrun(args_new)
  args_default_run = editargs(args_default_run, args_new, "RunMe")
end

function M.editcwd(cwd_new)
  if cwd_new ~= "" then
    current_wd = cwd
  else
    vim.ui.input({
      default=current_wd or "",
      prompt=fmt('{Build,Run}Me working directory: '),
      }, function(input)
        if input == nil then
          current_wd = current_wd
        elseif #input == 0 then
          current_wd = nil
        else
          current_wd = input
        end
      end)
  end
end

function M.jumpbuild()
  jump(job_buffer_build, 'buildme')
end

function M.jumprun()
  jump(job_buffer_run, 'runme')
end

function M.build(bang, args)
  job_buffer_build, job_id_build = job_run(
    args, args_default_build, bang, job_buffer_build,
    'buildme://buildjob', options.buildfile, options.force,
    job_id_build, current_wd, 'build')
end

function M.run(bang, args)
  job_buffer_run, job_id_run = job_run(
    args, args_default_run, bang, job_buffer_run,
    'buildme://runjob', options.runfile, "",
    job_id_run, current_wd, 'run')
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
  if options.save_current_wd then
    current_wd = fn.getcwd()
  end
end

------------------------------------------------------------
return M
