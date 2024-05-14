--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Based on <https://github.com/ojroques/nvim-buildme> by Olivier Roques
--

local api, cmd, fn, vim = vim.api, vim.cmd, vim.fn, vim
local fmt = string.format

local jobs = require("roarie-buildme.jobs")
local utils = require("roarie-buildme.utils")

local M = {}

local current_wd = nil

local options = {
	buildfile = ".buildme.sh",	-- the build file to execute
	runfile = ".runme.sh",		-- the run file to execute
	close_build_on_exit = "always",	-- close build window on exit: never, on_error, on_success, always
	close_run_on_exit = "always",	-- close run window on exit: never, on_error, on_success, always
	edit_on_nonexistent = true,	-- edit non-existent build/run file on build/run
	interpreter = "sh",		-- the interpreter to use (sh, bash, python, ...)
	force = "--force",		-- the option to pass when the bang is used
	save_current_wd = false,	-- save working directory of editor at startup; used to look for {build,run}file
	wincmd = "",			-- a window command to run prior to a build job
}

-- {{{ function M.editbuild()
function M.editbuild()
	jobs.edit(options.buildfile)
end
-- }}}
-- {{{ function M.editargsbuild(args_new)
function M.editargsbuild(args_new)
	jobs.jobs.build.args_default = jobs.editargs(jobs.jobs.build.args_default, args_new, "BuildMe")
end
-- }}}
-- {{{ function M.editrun()
function M.editrun()
	jobs.edit(options.runfile)
end
-- }}}
-- {{{ function M.editargsrun(args_new)
function M.editargsrun(args_new)
	jobs.jobs.run.args_default = jobs.editargs(jobs.jobs.run.args_default, args_new, "RunMe")
end
-- }}}
-- {{{ function M.editcwd(cwd_new)
function M.editcwd(cwd_new)
	if cwd_new ~= "" then
		current_wd = cwd
	else
		vim.ui.input({
			default=current_wd or "",
			prompt=fmt("{Build,Run}Me working directory: "),
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
-- }}}

-- {{{ function M.getargsbuild()
function M.getargsbuild()
	return jobs.jobs.build.args_default
end
-- }}}
-- {{{ function M.getargsrun()
function M.getargsrun()
	return jobs.jobs.run.args_default
end
-- }}}
-- {{{ function M.getcwd()
function M.getcwd()
	return current_wd
end
-- }}}

-- {{{ function M.jumpbuild()
function M.jumpbuild()
	jobs.jump("build", options.wincmd)
end
-- }}}
-- {{{ function M.jumprun()
function M.jumprun()
	jobs.jump("run", options.wincmd)
end
-- }}}

-- {{{ function M.build(bang, args, on_exit)
function M.build(bang, args, on_exit)
	jobs.run(
		args, jobs.jobs.build.args_default, bang, jobs.jobs.build.buffer,
		"buildme://buildjob", options.close_build_on_exit, current_wd,
		options.edit_on_nonexistent, options.buildfile, options.force,
		jobs.jobs.build.id, options.interpreter, "build", on_exit,
		options.wincmd)
end
-- }}}
-- {{{ function M.run(bang, args, on_exit)
function M.run(bang, args, on_exit)
	jobs.run(
		args, jobs.jobs.run.args_default, bang, jobs.jobs.run.buffer,
		"runme://runjob", options.close_run_on_exit, current_wd,
		options.edit_on_nonexistent, options.runfile, options.force,
		jobs.jobs.run.id, options.interpreter, "run", on_exit,
		options.wincmd)
end
-- }}}
-- {{{ function M.buildrun(bang, args)
function M.buildrun(bang, args)
	M.build(bang, args, function()
		M.run(bang, args)
	end)
end
-- }}}

-- {{{ function M.stopbuild()
function M.stopbuild()
	jobs.stop("build")
end
-- }}}
-- {{{ function M.stoprun()
function M.stoprun()
	jobs.stop("run")
end
-- }}}

-- {{{ function M.setautoclosebuild(autoclose_new)
function M.setautoclosebuild(autoclose_new)
	options.close_build_on_exit = autoclose_new
end
-- }}}
-- {{{ function M.setautocloserun(autoclose_new)
function M.setautocloserun(autoclose_new)
	options.close_run_on_exit = autoclose_new
end
-- }}}

-- {{{ function M.setup(user_options)
function M.setup(user_options)
	options = vim.tbl_extend("keep", user_options, options)
	if user_options then
		options = vim.tbl_extend("force", options, user_options)
	end
	if options.save_current_wd then
		current_wd = fn.getcwd()
	end
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
