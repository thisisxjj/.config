return {
	-- =====================================================================
	-- 核心 LSP 注入 (只保留金刚不坏的动态加载 + 兜底防御)
	-- =====================================================================
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}

			-- 步骤 A：动态获取 Tailwind 官方默认支持的 filetypes
			local default_filetypes = {}
			local ok, tw_config = pcall(require, "lspconfig.server_configurations.tailwindcss")

			if ok and tw_config and tw_config.default_config then
				default_filetypes = tw_config.default_config.filetypes or {}
			else
				-- 步骤 B：终极兜底防御
				default_filetypes = {
					"aspnetcorerazor",
					"astro",
					"astro-markdown",
					"blade",
					"clojure",
					"django-html",
					"htmldjango",
					"edge",
					"eelixir",
					"elixir",
					"ejs",
					"erb",
					"eruby",
					"gohtml",
					"gohtmltmpl",
					"haml",
					"handlebars",
					"hbs",
					"html",
					"html-eex",
					"heex",
					"jade",
					"leaf",
					"liquid",
					"markdown",
					"mdx",
					"mustache",
					"njk",
					"nunjucks",
					"php",
					"razor",
					"slim",
					"twig",
					"css",
					"less",
					"postcss",
					"sass",
					"scss",
					"stylus",
					"sugarss",
					"javascript",
					"javascriptreact",
					"reason",
					"rescript",
					"typescript",
					"typescriptreact",
					"vue",
					"svelte",
				}
			end

			-- 步骤 C：执行个性化过滤
			local exclude = { "markdown", "mdx" }
			local include = {}

			local final_filetypes = vim.tbl_filter(function(ft)
				return not vim.tbl_contains(exclude, ft)
			end, default_filetypes)

			vim.list_extend(final_filetypes, include)

			-- 步骤 D：注入到你的配置体系中
			opts.servers.tailwindcss = vim.tbl_deep_extend("force", opts.servers.tailwindcss or {}, {
				filetypes = final_filetypes,
				settings = {
					tailwindCSS = {
						includeLanguages = {
							elixir = "html-eex",
							heex = "html-eex",
						},
						experimental = {
							-- 穿透 clsx, cva, twMerge 等动态类名工具函数
							classRegex = {
								{ "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
								{ "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
								{ "twMerge\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
							},
						},
					},
				},
			})
		end,
	},
}
