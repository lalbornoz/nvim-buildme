--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Based on <https://github.com/ojroques/nvim-buildme> by Olivier Roques
--

local api, cmd, fn, vim = vim.api, vim.cmd, vim.fn, vim
local fmt = string.format

local utils = require("roarie-buildme.utils")
local utils_buffer = require("roarie-buildme.buffer")

local M = {}

local nkeys = api.nvim_replace_termcodes('<C-\\><C-n>G', true, false, true)

M.jobs = {
	build = {args_default=nil, buffer=nil, id=nil, maps=nil, window=nil, qflist=nil},
	run = {args_default=nil, buffer=nil, id=nil, maps=nil, window=nil, qflist=nil},
}

-- {{{ local function check_file(edit_on_nonexistent, file, kind)
local function check_file(edit_on_nonexistent, file, kind)
	if fn.filereadable(file) == 0 then
		utils.echo("WarningMsg", fmt("%s file '%s' not found", kind:gsub("^%l", string.upper), file))

		if edit_on_nonexistent then
			edit(file)
		end
		return false
	else
		return true
	end
end
-- }}}
-- {{{ local function format_command(args, args_default, bang, file, force, interpreter)
local function format_command(args, args_default, bang, file, force, interpreter)
	-- Format interpreter string
	if interpreter ~= "" then
		interpreter = fmt("%s ", interpreter)
	end

	if bang and force ~= "" then
		force = fmt(" %s", force)
	end

	if args ~= "" then
		args = fmt(" %s", args)
	elseif (args_default ~= nil) and (args_default ~= "") then
		args = fmt(" %s", args_default)
	end

	return fmt(
		"%s%s%s%s", interpreter,
		fn.shellescape(file), force, args)
end
-- }}}
-- {{{ local function job_on_exit(buffer, close_on_exit, kind, on_exit, window)
local function job_on_exit(buffer, close_on_exit, kind, on_exit, window)
	return function(id, exit_code, _)
		local hlgroup = exit_code == 0 and "None" or "WarningMsg"
		local msg = fmt("Job %d has finished with exit code %d", id, exit_code)
		utils.echo(hlgroup, msg)

		local qflist_items = utils_buffer.setqflist(buffer)
		if qflist_items ~= nil then
			M.jobs[kind].qflist = qflist_items
			utils_buffer.select_qfitem_first(
				buffer, kind,
				function() return M.jobs[kind].qflist end)
		end

		if (close_on_exit == "always")
		or ((close_on_exit == "on_error") and (exit_code > 0))
		or ((close_on_exit == "on_success") and (exit_code == 0))
		then
			api.nvim_win_close(window, true)
		end

		if on_exit ~= nil then
			on_exit()
		end
	end
end
-- }}}
-- {{{ local function running(id)
local function running(id)
	return id and (fn.jobwait({id}, 0)[1] == -1)
end
-- }}}

-- {{{ M.edit = function(file)
M.edit = function(file)
	cmd(fmt("edit %s", file))

	-- Make the build file executable
	local autocmd = 'au BufWritePost <buffer> call jobstart("chmod +x %s")'
	cmd(fmt(autocmd, file))
end
-- }}}
-- {{{ M.editargs = function(args, args_new, prompt_kind)
M.editargs = function(args, args_new, prompt_kind)
	if args_new ~= "" then
		return args_new
	else
		vim.ui.input({
			default=args,
			prompt=fmt("%s default arguments: ", prompt_kind),
			}, function(input)
				args = input
			end)
		return args
	end
end
-- }}}
-- {{{ M.run = function(args, args_default, bang, buffer, buffer_name, close_on_exit, current_wd, edit_on_nonexistent, file, force, id, interpreter, kind, on_exit, wincmd)
M.run = function(
	args, args_default, bang, buffer, buffer_name,
	close_on_exit, current_wd, edit_on_nonexistent,
	file, force, id, interpreter, kind, on_exit, wincmd
)
	if running(id) then
		utils.echo("ErrorMsg", fmt("A %s job is already running (id: %d)", kind, id))
		return buffer, id
	elseif (current_wd ~= nil)
	   and (not check_file(edit_on_nonexistent,
			current_wd .."/".. file, kind))
	then
		return buffer, id
	elseif (current_wd == nil)
	   and (not check_file(edit_on_nonexistent, file, kind))
	then
		return buffer, id
	end

	--
	-- Create buffer, start build job,
	-- exit terminal mode, rename buffer
	--

	buffer, M.jobs[kind].maps = utils_buffer.create(
		buffer, kind, M.jobs[kind].maps,
		function() return M.jobs[kind].qflist end)
	utils_buffer.jump(buffer, kind, wincmd)
	local window = api.nvim_get_current_win()
	M.jobs[kind].buffer = buffer
	M.jobs[kind].window = window

	local command = format_command(
		args, args_default, bang,
		file, force, interpreter)
	id = fn.termopen(
		command, {
			cwd=current_wd,
			on_exit=job_on_exit(
				buffer, close_on_exit,
				kind, on_exit, window)})
	M.jobs[kind].id = id
	api.nvim_feedkeys(nkeys, "n", false)
	api.nvim_buf_set_name(buffer, buffer_name)

	return buffer, id, window
end
-- }}}
-- {{{ M.stop = function(kind)
M.stop = function(kind)
	local id = (M.jobs[kind] or {}).id
	if running(id) then
		fn.jobstop(id)
		utils.echo("None", fmt("Stopped job %d", id))
	else
		utils.echo("None", "No job to stop")
	end
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
