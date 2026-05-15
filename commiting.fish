#!/bin/fish

gitgo '
feat(swarm): integrate state to AST, minimalist UX and git guardrails

- AST Polymorphic Swarm: Eradicated the legacy `<swarm_state>` tag. Swarm
  JSON states are now natively encapsulated as `<block type="swarm">` nodes
  in the Immutable Ledger. This allows the Asynchronous Librarian (Archiver)
  to hyper-compress completed MoA sessions, saving massive context tokens.
- Minimalist Carousel UX: Refactored `chat_view` floating window title to
  eliminate visual pollution. It dynamically hides inactive worker tabs,
  strictly rendering the `Main` chat and the focused Swarm agent.
- Anti-Branching Guardrails: Hardened `spawn_swarm` MCP documentation with
  `TERMINALLY FORBIDDEN` directives against parallel Git branch operations,
  neutralizing local Working Tree corruption during concurrent workflows.
- Test Architecture: Fixed legacy assertions from Phase 5 and Phase 18.5.
  Added strict validation for the new AST serialization and UI behavior
  (Maintained 100% Success Rate across 281 tests).
- Docs: Updated CONTEXT.md with Phase 48 specifications.

Ref: Phase 48
'

