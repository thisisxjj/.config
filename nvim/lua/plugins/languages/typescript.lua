return {
	{
		"neovim/nvim-lspconfig",
		dependencies = { "yioneko/nvim-vtsls" },
		opts = function(_, opts)
			opts.servers = opts.servers or {}

			opts.servers.tsserver = { enabled = false }
			opts.servers.ts_ls = { enabled = false }

			opts.servers.vtsls = opts.servers.vtsls or {}
			opts.servers.vtsls.filetypes = opts.servers.vtsls.filetypes or {}

			local base_ft = {
				"javascript",
				"javascriptreact",
				"javascript.jsx",
				"typescript",
				"typescriptreact",
				"typescript.tsx",
			}

			-- 循环追加，绝对不会覆盖掉 vue.lua 里加进去的 "vue"
			for _, ft in ipairs(base_ft) do
				if not vim.tbl_contains(opts.servers.vtsls.filetypes, ft) then
					table.insert(opts.servers.vtsls.filetypes, ft)
				end
			end

			-- 🌟 修复 2：使用 vim.tbl_deep_extend 安全合并 settings，绝不能用 "=" 直接覆盖！
			local vtsls_settings = {
				complete_function_calls = true,
				vtsls = {
					enableMoveToFileCodeAction = true,
					autoUseWorkspaceTsdk = true,
					experimental = {
						maxInlayHintLength = 30,
						completion = { enableServerSideFuzzyMatch = true },
					},
				},
				typescript = {
					updateImportsOnFileMove = { enabled = "always" },
					suggest = { completeFunctionCalls = true },
					inlayHints = {
						enumMemberValues = { enabled = true },
						functionLikeReturnTypes = { enabled = true },
						parameterNames = { enabled = "literals" },
						parameterTypes = { enabled = true },
						propertyDeclarationTypes = { enabled = true },
						variableTypes = { enabled = false },
					},
				},
			}
			-- 将上面的配置安全地合并进现有的 settings 中，保护 Vue 插件不被删除
			opts.servers.vtsls.settings =
				vim.tbl_deep_extend("force", opts.servers.vtsls.settings or {}, vtsls_settings)

			-- 下面保留你原本的 js 继承 ts 逻辑
			opts.servers.vtsls.settings.javascript = vim.tbl_deep_extend(
				"force",
				{},
				opts.servers.vtsls.settings.typescript,
				opts.servers.vtsls.settings.javascript or {}
			)

			-- ✅ 核心修复：使用 Neovim 原生的 LspAttach 监听器，精确拦截 vtsls
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("vtsls-custom-attach", { clear = true }),
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local bufnr = args.buf

					-- 如果不是 vtsls 启动，立刻退出，绝不污染其他语言
					if not client or client.name ~= "vtsls" then
						return
					end

					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "TS: " .. desc })
					end

					-- 完美还原你旧配置中的 Trouble 调用逻辑
					map("gD", function()
						local position_params = vim.lsp.util.make_position_params(0, client.offset_encoding)
						require("trouble").open({
							mode = "lsp_command",
							params = {
								command = "typescript.goToSourceDefinition",
								arguments = { position_params.textDocument.uri, position_params.position },
							},
						})
					end, "Goto Source Definition")

					map("gR", function()
						require("trouble").open({
							mode = "lsp_command",
							params = {
								command = "typescript.findAllFileReferences",
								arguments = { vim.uri_from_bufnr(0) },
							},
						})
					end, "File References")

					-- 基础 TS 快捷键
					map("<leader>co", "<cmd>VtsExec organize_imports<cr>", "Organize Imports")
					map("<leader>cM", "<cmd>VtsExec add_missing_imports<cr>", "Add missing imports")
					map("<leader>cu", "<cmd>VtsExec remove_unused_imports<cr>", "Remove unused imports")
					map("<leader>cD", "<cmd>VtsExec fix_all<cr>", "Fix all diagnostics")
					map("<leader>cV", "<cmd>VtsExec select_ts_version<cr>", "Select TS workspace version")
					map("<leader>cT", function()
						vim.cmd("LspRestart vtsls")
					end, "Restart TS Server")

					-- 劫持并重写底层的“移动文件重构”逻辑
					client.commands["_typescript.moveToFileRefactoring"] = function(command, _)
						local action, uri, range = unpack(command.arguments)
						---@cast action string
						---@cast uri string
						---@cast range table

						local function move(newf)
							client:request("workspace/executeCommand", {
								command = command.command,
								arguments = { action, uri, range, newf },
							})
						end
						local fname = vim.uri_to_fname(uri)
						client:request("workspace/executeCommand", {
							command = "typescript.tsserverRequest",
							arguments = {
								"getMoveToRefactoringFileSuggestions",
								{
									file = fname,
									startLine = range.start.line + 1,
									startOffset = range.start.character + 1,
									endLine = range["end"].line + 1,
									endOffset = range["end"].character + 1,
								},
							},
						}, function(_, result)
							if not result or not result.body or not result.body.files then
								return
							end
							local files = result.body.files
							table.insert(files, 1, "Enter new path...")
							vim.ui.select(files, {
								prompt = "Select move destination:",
								format_item = function(f)
									return vim.fn.fnamemodify(f, ":~:.")
								end,
							}, function(f)
								if f and f:find("^Enter new path") then
									vim.ui.input({
										prompt = "Enter move destination:",
										default = vim.fn.fnamemodify(fname, ":h") .. "/",
										completion = "file",
									}, function(newf)
										return newf and move(newf)
									end)
								elseif f then
									move(f)
								end
							end)
						end)
					end
				end,
			})
		end,
	},
	{
		"mfussenegger/nvim-dap",
		optional = true,
		opts = function()
			local dap = require("dap")

			-- A: 安全注册 Adapter
			for _, adapterType in ipairs({ "node", "chrome", "msedge" }) do
				local pwaType = "pwa-" .. adapterType

				if not dap.adapters[pwaType] then
					local mason_registry = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
					dap.adapters[pwaType] = {
						type = "server",
						host = "localhost",
						port = "${port}",
						executable = {
							command = "node",
							args = {
								mason_registry .. "/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
								"${port}",
							},
						},
					}
				end

				if not dap.adapters[adapterType] then
					dap.adapters[adapterType] = function(cb, config)
						config.type = pwaType
						local nativeAdapter = dap.adapters[pwaType]
						if type(nativeAdapter) == "function" then
							nativeAdapter(cb, config)
						else
							cb(nativeAdapter)
						end
					end
				end
			end

			-- B: 安全追加 Filetypes
			local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
			local vscode = require("dap.ext.vscode")

			vscode.type_to_filetypes["node"] = vscode.type_to_filetypes["node"] or {}
			vscode.type_to_filetypes["pwa-node"] = vscode.type_to_filetypes["pwa-node"] or {}

			for _, ft in ipairs(js_filetypes) do
				if not vim.tbl_contains(vscode.type_to_filetypes["node"], ft) then
					table.insert(vscode.type_to_filetypes["node"], ft)
					table.insert(vscode.type_to_filetypes["pwa-node"], ft)
				end
			end

			-- C: 独立注入 Configuration
			for _, language in ipairs(js_filetypes) do
				if not dap.configurations[language] then
					local runtimeExecutable = nil
					if language:find("typescript") then
						runtimeExecutable = vim.fn.executable("tsx") == 1 and "tsx" or "ts-node"
					end

					dap.configurations[language] = {
						{
							type = "pwa-node",
							request = "launch",
							name = "Launch file",
							program = "${file}",
							cwd = "${workspaceFolder}",
							sourceMaps = true,
							runtimeExecutable = runtimeExecutable,
							skipFiles = { "<node_internals>/**", "node_modules/**" },
							resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
						},
						{
							type = "pwa-node",
							request = "attach",
							name = "Attach",
							processId = require("dap.utils").pick_process,
							cwd = "${workspaceFolder}",
							sourceMaps = true,
							runtimeExecutable = runtimeExecutable,
							skipFiles = { "<node_internals>/**", "node_modules/**" },
							resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
						},
					}
				end
			end
		end,
	},
	-- 3. 防护与美化组件 (防御性追加配置)
	{
		"jay-babu/mason-nvim-dap.nvim",
		optional = true,
		opts = function(_, opts)
			opts.automatic_installation = opts.automatic_installation or {}
			if type(opts.automatic_installation) == "boolean" then
				opts.automatic_installation = {}
			end
			opts.automatic_installation.exclude = opts.automatic_installation.exclude or {}

			if not vim.tbl_contains(opts.automatic_installation.exclude, "chrome") then
				table.insert(opts.automatic_installation.exclude, "chrome")
			end
		end,
	},

	{
		"echasnovski/mini.icons",
		optional = true,
		opts = function(_, opts)
			opts.file = opts.file or {}
			local frontend_icons = {
				[".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
				[".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
				[".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
				[".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
				["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
				["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
				["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
				["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
				["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
			}
			opts.file = vim.tbl_deep_extend("force", opts.file, frontend_icons)
		end,
	},
}
