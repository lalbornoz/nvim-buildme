--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Based on <https://github.com/ojroques/nvim-buildme> by Olivier Roques
--

local api, cmd, fn, vim = vim.api, vim.cmd, vim.fn, vim
local fmt = string.format

local utils = require("roarie-buildme.utils")

local M = {}

-- {{{ local function wrap_qfitem_action(fn_name, ...)
local function wrap_qfitem_action(fn_name, ...)
	local args = {...}
	return function(M, buffer, kind, qflist_fn)
		return function()
			return M[fn_name](buffer, kind, qflist_fn, unpack(args))
		end
	end
end
-- }}}
-- {{{ local maps_default = {}
local maps_default = {
	["<CR>"] = wrap_qfitem_action("edit_qfitem"),
	["<C-PageDown>"] = wrap_qfitem_action("select_qfitem", 1, false),
	["<C-PageUp>"] = wrap_qfitem_action("select_qfitem", -1, false),
	["<C-S-PageDown>"] = wrap_qfitem_action("select_qfitem", 1, true),
	["<C-S-PageUp>"] = wrap_qfitem_action("select_qfitem", -1, true),
}
-- }}}

-- {{{ local function setup_maps(buffer, kind, qflist_fn)
local function setup_maps(buffer, kind, qflist_fn)
	for lhs, rhs in pairs(M.maps or {}) do
		vim.keymap.del({"n", "i"}, lhs, {buffer=buffer})
	end
	M.maps = {}

	for lhs, rhs in pairs(maps_default) do
		vim.keymap.set(
			{"n", "i"}, lhs, rhs(M, buffer, kind, qflist_fn),
			{buffer=buffer, noremap=true})
		M.maps[lhs] = rhs
	end
end
-- }}}

-- {{{ M.create = function(buffer, kind, qflist_fn)
M.create = function(buffer, kind, qflist_fn)
	if (buffer == nil) or (not M.exists(buffer)) then
		buffer = api.nvim_create_buf(true, true)
		api.nvim_buf_set_option(buffer, "filetype", "buildme")
	end
	api.nvim_buf_set_option(buffer, "modified", false)
	setup_maps(buffer, kind, qflist_fn)
	return buffer
end
-- }}}
-- {{{ M.exists = function(buffer)
M.exists = function(buffer)
	return buffer and fn.buflisted(buffer) == 1
end
-- }}}
-- {{{ M.jump = function(buffer, kind, wincmd)
M.jump = function(buffer, kind, wincmd)
	if not M.exists(buffer) then
		utils.echo("WarningMsg", "No " .. kind .. " buffer")
		return
	end

	-- Jump to the buffer window if it exists
	local job_window = fn.bufwinnr(buffer)
	if job_window ~= -1 then
		cmd(fmt("%d wincmd w", job_window))
		return
	end

	-- Run window command
	if wincmd ~= "" then
		cmd(wincmd)
	end

	cmd(fmt("buffer %d", buffer))
end
-- }}}
-- {{{ M.setqflist = function(buffer)
M.setqflist = function(buffer)
	local lines = api.nvim_buf_get_lines(buffer, 0, -1, false)
	local qflist = fn.getqflist({lines=lines})
	if #qflist.items then
		for idx, _ in ipairs(qflist.items) do
			qflist.items[idx].bufnr = buffer
		end
		fn.setqflist(qflist.items, "r")
	end
	return (qflist or {}).items
end
-- }}}

-- {{{ M.edit_qfitem = function(buffer, kind, qflist_fn)
M.edit_qfitem = function(buffer, kind, qflist_fn)
	local qflist = qflist_fn()
	if qflist ~= nil then
		local pos = api.nvim_win_get_cursor(0)
		local qf_item = qflist[pos[1]]
		if (qf_item ~= nil) and (qf_item.valid == 1) then
			local job_window = fn.bufwinnr(buffer)
			if job_window ~= -1 then
				cmd(fmt("wincmd p"))
				cmd(fmt("e %s", qf_item.module))
				api.nvim_win_set_cursor(0, {qf_item.lnum, qf_item.col})
			end
		end
	end
end
-- }}}
-- {{{ M.select_qfitem = function(buffer, kind, qflist_fn, dir, open)
M.select_qfitem = function(buffer, kind, qflist_fn, dir, open)
	local qflist = qflist_fn()
	if qflist ~= nil then
		local pos = api.nvim_win_get_cursor(0)

		local function select(idx)
			if qflist[idx].valid == 1 then
				api.nvim_win_set_cursor(0, {idx, 0})
				if open then
					local job_window = fn.bufwinnr(buffer)
					if job_window ~= -1 then
						cmd(fmt("wincmd p"))
						cmd(fmt("e %s", qflist[idx].module))
						api.nvim_win_set_cursor(0, {qflist[idx].lnum, qflist[idx].col})
					end
				end
				return true
			end
			return false
		end

		if dir > 0 then
			for idx=pos[1]+1,#qflist do
				if select(idx) then
					break
				end
			end
		else
			for idx=pos[1]-1,1,-1 do
				if select(idx) then
					break
				end
			end
		end
	end
end
-- }}}
-- {{{ M.select_qfitem_first = function(buffer, kind, qflist_fn)
M.select_qfitem_first = function(buffer, kind, qflist_fn)
	local qflist = qflist_fn()
	if qflist ~= nil then
		local pos = api.nvim_win_get_cursor(0)
		for idx=1,#qflist do
			if qflist[idx].valid == 1 then
				api.nvim_win_set_cursor(0, {idx, 0})
				break
			end
		end
	end
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
