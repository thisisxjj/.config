# Repository Guidelines

## Project Structure & Module Organization
- `init.lua` bootstraps the config and loads `lua/config/init.lua`.
- `lua/config/` holds core settings: options, keymaps, autocommands, and plugin bootstrap (`lazy.lua`).
- `lua/plugins/` contains Lazy.nvim plugin specs, grouped by domain (e.g., `editor/`, `ui/`).
- `lazy-lock.json` pins plugin versions; treat it as the source of truth for reproducible setups.

## Build, Test, and Development Commands
- `nvim` — start Neovim with this configuration.
- `nvim --headless "+Lazy! sync" +qa` — install/update plugins in headless mode.
- Inside Neovim: `:Lazy` to manage plugins, `:Lazy sync` to reconcile installs.
- `:checkhealth` — sanity-check provider/tooling health (Python, Node, etc.).

## Coding Style & Naming Conventions
- Language: Lua.
- Indentation: 2 spaces (align with `tabstop`/`shiftwidth` settings).
- Prefer `local` for functions/vars and keep module tables returned at the end.
- Module naming: `lua/config/<topic>.lua`, `lua/plugins/<area>/<plugin>.lua`.
- Use descriptive keymap comments when remapping core motion or mode behaviors.

## Testing Guidelines
- No automated test framework is configured.
- Validate changes manually by launching `nvim`, checking `:messages`, and verifying keymaps/options.
- For plugin changes, run `:Lazy sync` and restart Neovim to confirm load order.

## Commit & Pull Request Guidelines
- This directory does not include a `.git` history, so no local commit conventions are discoverable.
- If you are contributing via a parent repo, follow its commit/PR standards.
- Otherwise, use short, present-tense commit subjects (e.g., “Refactor keymaps”) and include a brief change summary in PRs.

## Security & Configuration Tips
- Avoid hardcoding machine-specific paths unless required; use `vim.fn.stdpath` where possible.
- Keep sensitive tokens out of the repo; prefer environment variables or local-only overrides.
