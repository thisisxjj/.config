# AGENTS Guide (nvim)

## Scope and entrypoints
- This repo is a Neovim Lua config; startup is `init.lua` -> `lua/config/init.lua`.
- Load order is fixed: `autocommands` -> `options` -> `keymaps` -> `lazy` (`lua/config/init.lua`).
- Plugin manager is Lazy.nvim, bootstrapped in `lua/config/lazy.lua`; plugin versions are pinned in `lazy-lock.json`.

## Fast commands
- Start normally: `nvim`
- Sync plugins headless: `nvim --headless "+Lazy! sync" +qa`
- Health check after changes: `nvim --headless "+checkhealth" +qa`

## Core behavior you must preserve (from options/keymaps)
- This config is **JKLI-first**, not HJKL-first:
  - movement remap in normal/visual/operator: `j->h`, `k->j`, `i->k`, `l->l`
  - insert is migrated to `n` (`n`/`N` act like native `i`/`I`)
  - search next is migrated to `h`/`H` (native `n`/`N`)
- When adding keymaps/plugins, adapt to JKLI conventions first; avoid introducing default-HJKL-only mappings.
- Leader is space; many global mappings are under `<leader>c*`, `<leader>s*`, `<leader>t*`, `<leader>b*`.
- Folding is Treesitter-based in options (`foldexpr = v:lua.vim.treesitter.foldexpr()`, default open with foldlevel 99).

## Plugin architecture conventions
- Plugin specs are split by domain under `lua/plugins/{coding,editor,formatting,languages,linting,ui}` and imported centrally in `lua/config/lazy.lua`.
- Language-specific files (e.g. `languages/vue.lua`, `languages/astro.lua`, `languages/typescript.lua`) **extend shared plugin opts**; do not replace upstream tables.
- Prefer defensive merges (`vim.tbl_deep_extend`, append-if-missing) because multiple language modules mutate the same `opts.servers`, `opts.formatters_by_ft`, and Treesitter lists.
- LSP bootstrapping is centralized in `plugins/coding/lsp.lua` and iterates `opts.servers`; mark a server as disabled with `{ enabled = false }`.

## Tooling and integration quirks
- Completion is `blink.cmp` (not nvim-cmp). Selection keys are customized for JKLI (`<C-k>` next, `<C-i>` prev).
- Telescope is the primary picker; `snacks.nvim` picker is explicitly disabled.
- Format-on-save is enabled via Conform (`plugins/formatting/conform.lua`) and can be toggled:
  - buffer-local: `:FormatToggle` / `<leader>tf`
  - global: `:FormatToggle!` / `<leader>tF`
- ESLint server runs `EslintFixAll` on `BufWritePre` and formatting is delegated away from ESLint.
- Python uses Pyright + Ruff; Ruff hover is disabled on attach to avoid hover conflicts.

## Verification focus after edits
- Check startup and runtime messages: `:messages`
- Verify JKLI remaps and migrated keys still work (`j/k/i/l`, `n`, `h`).
- For LSP/formatter changes, save a real file and confirm attach/format/lint behavior (not just `:checkhealth`).
