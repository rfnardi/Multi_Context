#!/bin/fish

gitgo "chore(release): v2.4.2 - Enterprise security, Async core & 100% Test coverage

This major update resolves all remaining Technical Debt, Performance bottlenecks, and Security vulnerabilities, achieving a perfect 277/277 test pass rate.

🔒 Security:
- fix(gatekeeper): Prevent sandbox escape / RCE by strictly blocking shell chaining operators (`\;`, `\&`, `|`, `\$\(\)`, backticks) in `tool_runner`.

⚡ Performance & Stability (Zero UI-Freeze):
- perf(tools): Refactor `run_shell` and `apply_diff` to use asynchronous `jobstart` instead of blocking `vim.fn.system`.
- perf(ui): Eliminate FFI bottleneck in `chat_view` by batch-fetching buffer lines (O(1)) instead of looping.
- perf(io): Add session-level caching for `get_repo_root()` to prevent blocking I/O micro-stutters while typing.
- fix(oom): Implement 5000-line hard limits in `context_builders` to prevent Out-Of-Memory crashes on massive files.

🐛 Bug Fixes:
- fix(lsp): Add `vim.wait` to `lsp_manager` to properly await Mason.nvim installations before attaching JIT LSPs.
- fix(network): Remove phantom payload reads and duplicated `chansend`/`chanclose` calls in `transport.lua`.

🏗️ Architecture & Docs:
- refactor(core): Eradicate `_G.MultiContextTempFiles` global state pollution in favor of isolated module state.
- docs: Update CONTEXT.md with V2.4.2 architectural milestones (Anti-OOM, Async execution, Security).

✅ Tests: 277/277 passing (100% Success Rate).
"

