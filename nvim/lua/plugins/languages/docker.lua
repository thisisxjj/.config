return {
	-- 1. 语法树：安全注入 Dockerfile
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			if type(opts.ensure_installed) == "table" and not vim.tbl_contains(opts.ensure_installed, "dockerfile") then
				table.insert(opts.ensure_installed, "dockerfile")
			end
		end,
	},

	-- 2. LSP：激活 Docker 和 Docker Compose 服务
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				-- 注意：Mason 里的包名叫 dockerfile-language-server，但 LSP 配置名叫 dockerls
				dockerls = {},
				docker_compose_language_service = {},
			},
		},
	},

	-- 3. 代码检查 (Linting)：挂载 Hadolint
	-- (前提是你安装了 mfussenegger/nvim-lint 插件)
	{
		"mfussenegger/nvim-lint",
		optional = true, -- 如果你没装 nvim-lint，这一段会自动被忽略，不会报错
		opts = function(_, opts)
			opts.linters_by_ft = opts.linters_by_ft or {}
			opts.linters_by_ft.dockerfile = { "hadolint" }
		end,
	},
}
