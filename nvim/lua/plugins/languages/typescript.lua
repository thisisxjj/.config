return {
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}

			opts.servers.tsserver = { enabled = false }
			opts.servers.ts_ls = { enabled = false }
			opts.servers.vtsls = opts.servers.vtsls or {}

			opts.servers.vtsls.filetypes = {
				"javascript",
				"javascriptreact",
				"javascript.jsx",
				"typescript",
				"typescriptreact",
				"typescript.tsx",
			}

			opts.servers.vtsls.settings = {
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
}
