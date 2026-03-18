---@param config {type?:string, args?:string[]|fun():string[]?}
local function get_args(config)
	local args = type(config.args) == "function" and (config.args() or {}) or config.args or {} --[[@as string[] | string ]]
	local args_str = type(args) == "table" and table.concat(args, " ") or args --[[@as string]]

	config = vim.deepcopy(config)
	---@cast args string[]
	config.args = function()
		local new_args = vim.fn.expand(vim.fn.input("Run with args: ", args_str)) --[[@as string]]
		if config.type and config.type == "java" then
			---@diagnostic disable-next-line: return-type-mismatch
			return new_args
		end
		return require("dap.utils").splitstr(new_args)
	end
	return config
end

return {
	-- 1. 核心调试引擎与快捷键
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			{
				"theHamsta/nvim-dap-virtual-text",
				opts = { virt_text_win_col = 80 },
			},
		},
		keys = {
			{
				"<leader>da",
				function()
					require("dap").continue({ before = get_args })
				end,
				desc = "Run with Args",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle Breakpoint",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Breakpoint Condition",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Run/Continue",
			},
			{
				"<leader>dC",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to Cursor",
			},
			{
				"<leader>de",
				function()
					require("dapui").eval()
				end,
				desc = "Evaluate",
			},
			{
				"<leader>dg",
				function()
					require("dap").goto_()
				end,
				desc = "Go to Line (No Execute)",
			},
			{
				"<leader>dn",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<leader>dk",
				function()
					require("dap").down()
				end,
				desc = "Down",
			},
			{
				"<leader>di",
				function()
					require("dap").up()
				end,
				desc = "Up",
			},
			{
				"<leader>dl",
				function()
					require("dap").run_last()
				end,
				desc = "Run Last",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<leader>dP",
				function()
					require("dap").pause()
				end,
				desc = "Pause",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Toggle REPL",
			},
			{
				"<leader>ds",
				function()
					require("dap").session()
				end,
				desc = "Session",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Toggle DAPUI",
			},
			{
				"<leader>dw",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Widgets",
			},
		},
		config = function()
			vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

			local dap_icons = {
				Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
				Breakpoint = { " ", "DiagnosticInfo" },
				BreakpointCondition = { " ", "DiagnosticInfo" },
				BreakpointRejected = { " ", "DiagnosticError" },
				LogPoint = { ".>", "DiagnosticInfo" },
			}
			for name, sign in pairs(dap_icons) do
				vim.fn.sign_define(
					"Dap" .. name,
					{ text = sign[1], texthl = sign[2], linehl = sign[3], numhl = sign[3] }
				)
			end

			local vscode = require("dap.ext.vscode")
			local json = require("plenary.json")
			vscode.json_decode = function(str)
				return vim.json.decode(json.json_strip_comments(str))
			end

			-- 🌟 精准时序控制：确保所有语言适配器加载后再由 Mason 接管
			local mason_nvim_dap = require("lazy.core.config").spec.plugins["mason-nvim-dap.nvim"]
			if mason_nvim_dap then
				local Plugin = require("lazy.core.plugin")
				local mason_nvim_dap_opts = Plugin.values(mason_nvim_dap, "opts", false)
				require("mason-nvim-dap").setup(mason_nvim_dap_opts)
			end
		end,
	},
	-- 2. 调试器 UI 面板自动启停配置
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			-- 🌟 完美归位：dap-ui 的专属核心底层依赖
			"nvim-neotest/nvim-nio",
		},
		keys = {
			{
				"<leader>du",
				function()
					require("dapui").toggle({})
				end,
				desc = "Dap UI",
			},
			{
				"<leader>de",
				function()
					require("dapui").eval()
				end,
				desc = "Eval",
				mode = { "n", "v" },
			},
		},
		opts = {
			-- 🌟 键盘至上：关掉鼠标点击悬浮控制条，保持界面沉浸清爽
			controls = { enabled = false },
		},
		config = function(_, opts)
			local dap = require("dap")
			local dapui = require("dapui")
			dapui.setup(opts)

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open({})
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close({})
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close({})
			end
		end,
	},
	-- 3. Mason 与 DAP 桥接声明 (只存配置，阻断自动执行)
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = "williamboman/mason.nvim",
		cmd = { "DapInstall", "DapUninstall" },
		opts = {
			automatic_installation = true,
			handlers = {},
			ensure_installed = {},
		},
		-- 🌟 阻止其过早接管
		config = function() end,
	},
}
