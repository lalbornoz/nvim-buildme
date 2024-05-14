--
-- Copyright (c) 2024 Lucía Andrea Illanes Albornoz <lucia@luciaillanes.de>
-- Based on <https://github.com/ojroques/nvim-buildme> by Olivier Roques
--

local api, cmd, fn, vim = vim.api, vim.cmd, vim.fn, vim
local fmt = string.format

local M = {}

-- {{{ M.echo = function(hlgroup, msg)
M.echo = function(hlgroup, msg)
	cmd(fmt("echohl %s", hlgroup))
	cmd(fmt('echo "[buildme] %s"', msg))
	cmd("echohl None")
end
-- }}}

return M

-- vim:filetype=lua noexpandtab sw=8 ts=8 tw=0
