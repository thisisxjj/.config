-- ==========================================================================
--  NEOVIM JKLI 布局终极配置
--  设计核心: 将 hjkl 右移至 jkli，并修复所有由此产生的逻辑冲突
-- ==========================================================================

-- 1. 基础设置 (让折叠和换行生效，方便测试高级移动)
-- --------------------------------------------------------------------------
-- 2. 快捷键定义辅助函数
-- --------------------------------------------------------------------------
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ==========================================================================
--  第一部分：核心移动层 (The Core Shift)
--  逻辑：h/j/k/l -> j/k/i/l
-- ==========================================================================

-- 普通模式、可视模式、选择模式
local modes = { "n", "v", "x", "o" }

-- j: 左移 (原 h)
keymap(modes, "j", "h", opts)
-- k: 下移 (原 j)
keymap(modes, "k", "j", opts)
-- i: 上移 (原 k) - [冲突源头]
keymap(modes, "i", "k", opts)
-- l: 右移 (原 l) - 保持不变，显式定义以防混淆
keymap(modes, "l", "l", opts)

-- ==========================================================================
--  第二部分：快速大幅移动 (Large Motions)
--  逻辑：J/K/I/L 对应方向的加强版
-- ==========================================================================

-- J: 到行首 (原 0/^)
keymap(modes, "J", "0", opts)
-- K: 向下 5 行 (原 5j)
keymap(modes, "K", "5j", opts)
-- I: 向上 5 行 (原 5k)
keymap(modes, "I", "5k", opts)
-- L: 到行尾 (原 $)
keymap(modes, "L", "$", opts)

-- ==========================================================================
--  第三部分：插入与搜索 (Insert & Search Migration)
--  逻辑：把被占用的键功能迁移到新家
-- ==========================================================================

-- --- 插入模式 (Insert) ---
-- n: 在光标前插入 (New, 原 i)
keymap("n", "n", "i", opts)
-- N: 在行首插入 (原 I)
keymap("n", "N", "I", opts)

-- --- 搜索跳转 (Search) ---
-- h: 搜索下一个 (Hunt, 原 n) - 因为 h 键的左移功能被 j 拿走了，现在 h 是空的
keymap("n", "h", "n", opts)
-- H: 搜索上一个 (Hunt back, 原 N)
keymap("n", "H", "N", opts)

-- 保存关闭当前文件
keymap("n", "<leader>w", ":w<cr>", opts)
keymap({ "n", "t" }, "<leader>q", ":q<cr>", opts)

-- Buffer functions
local function delete_other_buffers()
	local current_buf = vim.api.nvim_get_current_buf()
	local buffers = vim.api.nvim_list_bufs()

	for _, buf in ipairs(buffers) do
		if buf ~= current_buf and vim.api.nvim_buf_is_loaded(buf) then
			vim.api.nvim_buf_delete(buf, {})
		end
	end
end

-- buffer
keymap("n", "<leader>b'", ":bnext<CR>", opts)
keymap("n", "<leader>b;", ":bprevious<CR>", opts)
keymap("n", "<leader>bD", ":bwipeout<CR>", opts)
keymap("n", "<leader>bd", ":bdelete<CR>", opts)
keymap("n", "<leader>bo", delete_other_buffers, opts)

-- Yank to system clipboard
keymap("n", "<leader>y", '"+y')
keymap("v", "<leader>y", '"+y')
keymap("n", "<leader>Y", '"+Y')

-- 声明前缀（很重要）
keymap(modes, "s", "<Nop>", opts)
keymap(modes, "<C-h>", "<Nop>", opts)
keymap(modes, "<leader>s", "<Nop>", opts)
-- split up (horizontal)
-- keymap(modes, "<leader>si", "<Cmd>set nosplitbelow<CR><Cmd>split<CR><Cmd>set splitbelow<CR>", opts)
-- split down (horizontal)
-- keymap(modes, "<leader>sk", "<Cmd>set splitbelow<CR><Cmd>split<CR>", opts)
-- split left (vertical)
-- keymap(modes, "<leader>sl", "<Cmd>set nosplitright<CR><Cmd>vsplit<CR><Cmd>set splitright<CR>", opts)
-- split right (vertical)
-- keymap(modes, "<leader>sj", "<Cmd>set splitright<CR><Cmd>vsplit<CR>", opts)
-- =========================
-- Re-arrange splits (still under leader+s*)
-- =========================
-- place windows up/down
keymap("n", "sh", "<Cmd>set splitbelow<CR><Cmd>split<CR>", opts)
-- place windows left/right
keymap("n", "sv", "<Cmd>set splitright<CR><Cmd>vsplit<CR>", opts)
-- ==========================================================================
--  第四部分：文本对象修复 (Text Objects)
--  逻辑：修复 diw, ci( 等操作
-- ==========================================================================

-- 在 Operator Pending 模式下，将 n 映射为 i (inner)
-- 效果：按 dnw 等同于原来的 diw (删除单词内部)
keymap("o", "n", "i", opts)

-- 针对 Visual 模式的 inner 选择 (例如 vnw 选中单词)
keymap("x", "n", "i", opts)

-- ==========================================================================
--  第五部分：高级移动修复 (Advanced Fixes)
--  逻辑：修复 g 键和 z 键的逻辑断层
-- ==========================================================================

-- --- 视觉行移动 (Visual/Display Line) ---
-- 逻辑：k 是下，所以 gk 应该是视觉下移 (原 gj)
keymap({ "n", "v" }, "gk", "gj", opts)
-- 逻辑：i 是上，所以 gi 应该是视觉上移 (原 gk)
keymap({ "n", "v" }, "gi", "gk", opts)

-- --- 折叠跳转 (Folds) ---
-- 逻辑：k 是下，zk 应该是下个折叠 (原 zj)
keymap("n", "zk", "zj", opts)
-- 逻辑：i 是上，zi 应该是上个折叠 (原 zk)
keymap("n", "zi", "zk", opts)

-- --- 搜索选中 (Visual Selection) ---
-- 逻辑：h 是搜下一个，所以 gh 选中下一个匹配 (原 gn)
keymap({ "n", "o", "x" }, "gh", "gn", opts)
keymap({ "n", "o", "x" }, "gH", "gN", opts)

-- ==========================================================================
--  第六部分：窗口管理 (Window Management)
--  逻辑：Alt + 方向键
-- ==========================================================================

-- 切换窗口
-- keymap('n', '<M-j>', '<C-w>h', opts) -- 左
-- keymap('n', '<M-k>', '<C-w>j', opts) -- 下
-- keymap('n', '<M-i>', '<C-w>k', opts) -- 上
-- keymap('n', '<M-l>', '<C-w>l', opts) -- 右

-- 调整窗口大小 (Alt + Shift + 方向)
-- keymap('n', '<M-J>', ':vertical resize -2<CR>', opts)
-- keymap('n', '<M-K>', ':resize +2<CR>', opts)
-- keymap('n', '<M-I>', ':resize -2<CR>', opts)
-- keymap('n', '<M-L>', ':vertical resize +2<CR>', opts)

-- 终端模式下的窗口切换 (让你在 terminal 里也能切出来)
keymap("t", "<M-j>", [[<C-\><C-n><C-w>h]], opts)
keymap("t", "<M-k>", [[<C-\><C-n><C-w>j]], opts)
keymap("t", "<M-i>", [[<C-\><C-n><C-w>k]], opts)
keymap("t", "<M-l>", [[<C-\><C-n><C-w>l]], opts)

-- ==========================================================================
--  第七部分：命令行增强 (Command Mode)
--  逻辑：Emacs / Readline 风格
-- ==========================================================================

local cmap = function(lhs, rhs)
	vim.keymap.set("c", lhs, rhs, { noremap = true })
end

cmap("<C-a>", "<Home>") -- 到行首
cmap("<C-e>", "<End>") -- 到行尾
cmap("<C-p>", "<Up>") -- 历史: 上一条
cmap("<C-n>", "<Down>") -- 历史: 下一条
cmap("<C-b>", "<Left>") -- 左移字符
cmap("<C-f>", "<Right>") -- 右移字符

-- 单词移动 (Meta/Alt 键)
cmap("<M-b>", "<S-Left>") -- 左跳一个词
cmap("<M-f>", "<S-Right>") -- 右跳一个词 (Forward)
cmap("<M-w>", "<S-Right>") -- 兼容写法 (如果你习惯 w 代表 word)

-- ==========================================================================
--  第八部分：找回丢失的重要功能
-- ==========================================================================

-- 因为 J 变成了行首，原来的 Join (合并行) 没了 -> 映射到 Leader j
keymap("n", "<leader>j", "J", opts)

-- 因为 K 变成了下移5行，原来的 Hover (查看文档) 没了 -> 映射到 Leader k
keymap("n", "<leader>k", "K", opts)

-- 因为 i 变成了上移，原 gi (Insert last) 冲突 -> 映射到 gn (Insert new last)
keymap("n", "gn", "gi", opts)

-- ==========================================================================
--  第九部分：可视模式移动选中行 (JKLI 方向适配)
-- ==========================================================================

-- 选中行下移/上移（与 k/i 方向保持一致）
keymap("v", "<C-k>", ":m '>+1<CR>gv=gv", opts)
keymap("v", "<C-i>", ":m '<-2<CR>gv=gv", opts)

keymap("n", "<leader>tn", ":tabnew<CR>")
keymap("n", "<leader>tq", ":tabclose<CR>")
keymap("n", "<leader>ts", ":tab split<CR>")
keymap("n", "<leader><Tab>", ":tabnext<CR>")
keymap("n", "<leader><S-Tab>", ":tabprevious<CR>")

keymap("i", "<C-j>", "<Left>", opts)
keymap("i", "<C-l>", "<Right>", opts)
keymap("i", "<C-k>", "<Down>", opts)
keymap("i", "<C-o>", "<C-o>o", opts)
keymap("n", "<Esc>", "<cmd>noh<cr><Esc>", opts)
