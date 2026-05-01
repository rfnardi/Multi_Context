#!/bin/fish

gitgo ' feat(core): implement Phase 38 Situational Awareness Tools

- Add `get_agents_info` to provide `@tech_lead` with workforce capabilities.
- Add `get_project_stack` for dynamic heuristic environment scanning (OS, Shell, Indentation, LSP, ecosystem markers).
- Add `get_git_env` to expose deep repository state (Branch, ahead/behind commits, merge/rebase locks) for `@devops`.
- Update `agents.lua` to grant the new awareness skills to appropriate personas.
- Add XML docs for the new tools.
- Fix Index Clamping bug in UI Menus.
- Refactor `nvim_buf_get_option` to `vim.bo` to align with modern Neovim APIs.

Tests: Reached 214 passing tests (100% green). '
