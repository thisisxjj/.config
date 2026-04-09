-- highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
	pattern = "*",
	desc = "highlight selection on yank",
	callback = function()
		vim.highlight.on_yank({ timeout = 200, visual = true })
	end,
})

-- restore cursor to file position in previous editing session
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			vim.api.nvim_win_set_cursor(0, mark)
			-- defer centering slightly so it's applied after render
			vim.schedule(function()
				vim.cmd("normal! zz")
			end)
		end
	end,
})

-- open help in horizontal split (bottom)
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("help_window", { clear = true }),
	pattern = "help",
	callback = function()
		vim.schedule(function()
			vim.cmd("wincmd J")
		end)
	end,
})

-- auto resize splits when the terminal's window is resized
vim.api.nvim_create_autocmd("VimResized", {
	command = "wincmd =",
})

-- no auto continue comments on new line
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("no_auto_comment", {}),
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- syntax highlighting for dotenv files
vim.api.nvim_create_autocmd("BufRead", {
	group = vim.api.nvim_create_augroup("dotenv_ft", { clear = true }),
	pattern = { ".env", ".env.*" },
	callback = function()
		vim.bo.filetype = "dosini"
	end,
})

-- show cursorline only in active window enable
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
	group = vim.api.nvim_create_augroup("active_cursorline", { clear = true }),
	callback = function()
		vim.opt_local.cursorline = true
	end,
})

-- refresh nvim-tree git state after lazygit actions
vim.api.nvim_create_autocmd({ "TermClose", "FocusGained" }, {
	group = vim.api.nvim_create_augroup("nvimtree_git_refresh", { clear = true }),
	pattern = { "term://*lazygit*", "*" },
	callback = function(args)
		if args.event == "TermClose" and not tostring(args.file):find("lazygit") then
			return
		end

		vim.cmd("checktime")

		local ok, api = pcall(require, "nvim-tree.api")
		if ok then
			api.tree.reload()
		end
	end,
})
