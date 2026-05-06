#!/bin/fish

gitgo "feat(core): implement JIT micro-archiving with background cognitive librarian (Phase 44)

- **JIT Dispatcher**: Added `dispatch_jit_task` to `dynamic_watchdog.lua` to trigger a lightweight summarization prompt asynchronously using a secondary fast/cheap background API.
- **Surgical Patching**: Implemented `patch_block_abstract` to seamlessly inject `<abstract>` and `<content>` tags into Neovim buffers and RAM state without disturbing the user's cursor or typing flow.
- **Orchestrator Hook**: Embedded the JIT hook directly into `react_orchestrator.lua` (`TerminateTurn`), ensuring the Cognitive Librarian wakes up seamlessly at the end of each interaction.
- **Testing**: Added BDD specifications for JIT behavior and `api_client` overriding, bringing the absolute test suite to 251 green tests.
"
