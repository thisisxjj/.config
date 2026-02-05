# Repository Guidelines (Neovim config)

## Scope
- This repo is a Neovim configuration written in Lua.
- Primary entrypoint: `init.lua` -> `lua/config/init.lua`.
- Plugin manager: Lazy.nvim (`lua/config/lazy.lua`).

## Project Structure & Module Organization
- `init.lua` is the minimal bootstrap and only calls `require("config")`.
- `lua/config/` contains core settings:
  - `options.lua` for `vim.o`/`vim.opt` settings.
  - `keymaps.lua` for all keymap definitions.
  - `autocommands.lua` for autocmds.
  - `lazy.lua` for Lazy.nvim bootstrap and plugin spec imports.
- `lua/plugins/` holds Lazy.nvim plugin specs grouped by domain.
  - Example: `lua/plugins/editor/`, `lua/plugins/ui/`, `lua/plugins/coding/`.
- `lazy-lock.json` pins plugin versions; keep it in sync with Lazy updates.

## Build, Lint, and Test Commands
- Launch Neovim with this configuration:
  - `nvim`
- Install/update plugins in headless mode:
  - `nvim --headless "+Lazy! sync" +qa`
- Plugin manager UI (inside Neovim):
  - `:Lazy`
  - `:Lazy sync`
- Environment health check (inside Neovim):
  - `:checkhealth`
- No dedicated lint/format command is configured (no `stylua.toml` or `.editorconfig`).

## Single-Test Guidance
- No automated test framework is configured.
- There is no notion of running a single test. Use manual verification:
  - Open Neovim and verify keymaps/options.
  - Check `:messages` for errors.
  - For plugin changes, run `:Lazy sync` and restart.

## Cursor/Copilot Rules
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` found.

## Coding Style
- Language: Lua (Neovim runtime).
- Indentation: 2 spaces (align with `tabstop`, `shiftwidth`).
- Keep files small and focused by area (options, keymaps, plugins).
- Prefer `local` for functions and variables.
- Return module tables at the end of files when needed.
- Use `vim.o` for simple options and `vim.opt` for list/table options.
- Default to ASCII in new code/comments; only use non-ASCII when a file already uses it.

## Imports and Module Loading
- Use `require("config.<module>")` for config modules.
- Keep config load order as in `lua/config/init.lua` unless required:
  - autocommands -> options -> keymaps -> lazy.
- Plugin specs are imported via Lazy.nvim `spec = { { import = "plugins..." } }`.
- Prefer absolute module names (no relative `./`).
- Keep top-level requires at the top of files.

## Naming Conventions
- Config files: `lua/config/<topic>.lua`.
- Plugin spec files: `lua/plugins/<area>/<plugin>.lua`.
- Use lowercase filenames; hyphens are acceptable (e.g., `lualine-theme.lua`).
- Lua locals use `snake_case` or concise descriptive names.
- Use descriptive option/keymap groups in comments only when needed.

## Keymaps
- Use `vim.keymap.set` with local aliases:
  - `local keymap = vim.keymap.set`
- Use a shared `opts` table for `noremap` and `silent`.
- Define mode tables once (e.g., `local modes = { "n", "v", "x", "o" }`).
- Keep related keymaps grouped and labeled by purpose.
- Prefer `<Cmd>...<CR>` mappings over `:` when possible.

## Keymap Philosophy
- Remap core movement from `hjkl` to `jkli`.
- Remap insert from `i` to `n`.
- Remap search-next from `n` to `h`.
- If a conflict appears, move the displaced behavior to another key; do not change unrelated keys.

## Formatting
- Keep lines concise; break long tables and function calls sensibly.
- Prefer trailing commas in multi-line tables for easy reordering.
- Avoid trailing whitespace and extra blank lines.
- Use consistent quote style within a file.
- Align multi-line tables with 2-space indentation.

## Error Handling and Diagnostics
- When invoking shell commands, check `vim.v.shell_error` and handle failures.
- Prefer `vim.api.nvim_echo` or `vim.notify` for user-visible errors.
- Avoid `os.exit` except for hard failures during bootstrap.
- Use `vim.diagnostic.config` for global diagnostic settings.

## Lazy.nvim Conventions
- Keep Lazy setup centralized in `lua/config/lazy.lua`.
- Add new plugin specs under `lua/plugins/<area>/`.
- Keep the plugin list minimal and structured by domain.
- Update `lazy-lock.json` when plugin versions change.
- In plugin specs, return a table; keep plugin-specific config close to its spec.
- Prefer lazy-loading options over eager loading when practical.

## Common Tasks
- Add a new option: edit `lua/config/options.lua`.
- Add a keymap: edit `lua/config/keymaps.lua`.
- Add a plugin: create spec in `lua/plugins/<area>/` and import it in `lua/config/lazy.lua`.
- Add an autocmd: edit `lua/config/autocommands.lua`.
- Add UI tweaks: prefer plugin spec configuration under `lua/plugins/ui/`.

## Manual Verification Checklist
- `nvim` launches without errors.
- `:checkhealth` reports no new critical failures.
- Keymaps behave as expected in normal/visual/operator modes.
- Plugin UIs open correctly (`:Lazy`, dashboards, etc.).
- No new errors in `:messages` after startup.

## Git/Repo Notes
- `lazy-lock.json` is treated as the source of truth for plugin versions.
- Avoid hardcoding machine-specific paths; use `vim.fn.stdpath` when possible.
- Do not commit secrets or local-only machine paths.
- Do not remove or rename `lazy-lock.json` unless intentionally updating plugins.

## Writing New Code
- Keep changes minimal and scoped to the file responsible for the behavior.
- Remove unused locals and dead code.
- Use comments only to explain non-obvious behavior or invariants.
- Avoid global state unless required by Neovim APIs.
- Prefer small helper locals over deep inline logic.

## Option Guidelines
- Set leader early in `lua/config/options.lua`.
- Use `vim.o` for booleans/strings and `vim.opt` for list/table settings.
- Keep related options grouped (UI, search, indent, splits).

## Autocommand Guidelines
- Create augroups for related autocmds.
- Use `vim.api.nvim_create_autocmd` and `vim.api.nvim_create_augroup`.
- Avoid duplicating autocmds across files.

## Plugin Spec Guidelines
- One plugin per spec file unless tightly related.
- Keep spec tables concise; avoid unused opts/keys.
- Use `config = function()` blocks for explicit setup when needed.
- Keep dependencies in `dependencies = { ... }`.

## Types and Lua Patterns
- No type system is enforced; avoid adding type annotations unless the file already uses them.
- Prefer `local function name()` for helpers.
- Avoid mutating tables from other modules unless intentional.

## Diagnostics for Agents
- If a change affects keymaps, validate with a quick manual check.
- If a plugin is added/removed, run `:Lazy sync` and restart Neovim.
- If startup errors occur, inspect `:messages` and `:checkhealth`.
