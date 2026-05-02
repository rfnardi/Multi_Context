#!/bin/fish

gitgo 'feat(ecosystem): implement JIT LSP Auto-Setup via Mason (Phase 39)

- Add `lsp_manager.lua` to statically map file extensions to their respective LSP packages (e.g., `.rs` -> `rust_analyzer`).
- Implement Just-in-Time (JIT) provisioning that intercepts AI tool calls (`edit_file`, `replace_lines`, `get_diagnostics`) to ensure syntax validation is available.
- Integrate gracefully with `mason-registry` to prompt the user for seamless background installation of missing LSPs.
- Add stateful alert fatigue prevention via `StateManager` to remember user installation rejections per session.
- Force immediate LSP attachment post-installation using `BufReadPost` autocmd hooks, avoiding manual buffer reloads.
- Implement strict behavioral tests for the new LSP manager contracts.

Tests: Reached 216 passing tests (100% green). '
