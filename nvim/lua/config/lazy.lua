local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{ import = "plugins.coding.autopairs" },
		{ import = "plugins.coding.treesitter" },
		{ import = "plugins.coding.lsp" },
		{ import = "plugins.coding.cmp" },
		{ import = "plugins.coding.trouble" },
		{ import = "plugins.editor.gitsigns" },
		{ import = "plugins.editor.lazygit" },
		{ import = "plugins.editor.tmux" },
		{ import = "plugins.editor.mini" },
		{ import = "plugins.editor.nvim-tree" },
		{ import = "plugins.editor.lualine" },
		{ import = "plugins.editor.telescope" },
		{ import = "plugins.formatting.conform" },
		{ import = "plugins.languages.astro" },
		{ import = "plugins.languages.docker" },
		{ import = "plugins.languages.vue" },
		{ import = "plugins.languages.typescript" },
		{ import = "plugins.languages.python" },
		{ import = "plugins.linting.core" },
		{ import = "plugins.ui.colorscheme" },
		{ import = "plugins.ui.dressing" },
		{ import = "plugins.ui.dashboard" },
	},
	checker = { enabled = false },
})
