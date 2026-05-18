#!/bin/fish

gitgo '
fix(ui): encapsulate swarm json payloads in native folds and add regression shields

- Swarm UI Folds: Fixed visual pollution where massive JSON payloads leaked
  into the chat buffer. Added native Neovim folds for `<block type="swarm">`
  with clean semantic labels (e.g., 🐝 [Enxame de IA: Rodando]).
- Regression Shields: Implemented strict headless tests for OS-level I/O
  failures (E482 Kernel Simulator) and UI folding events, permanently 
  protecting the Sandbox and the Visual Engine from future regressions.
- Test Calibration: Fixed false negatives in headless CI environments by
  binding phantom buffers to active windows and simulating tool signatures.
- Docs: Updated CONTEXT.md and README.md with Phase 48 final specs, Swarm AST,
  Minimalist UX, and the new absolute test count (284 passing).

Ref: Phase 48
'

