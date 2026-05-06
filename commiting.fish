#!/bin/fish

gitgo '
feat(core): implement continuous semantic archiving and asymmetric memory (Phase 43)

- **AST & Ledger**: Refactored `session.lua` to parse dual-nature XML blocks (`<abstract>` and `<content>`), keeping graceful fallback for legacy nodes.
- **Cognitive Asymmetry**: Updated `prompt_parser.lua` to deliver raw content to Standard agents (e.g., @coder) and semantic topological maps (Abstracts + IDs) to Meta agents (e.g., @tech_lead), drastically saving tokens.
- **Local RAG Tools**: Added `read_block_content` and `archive_blocks` to `native_tools.lua`, enabling Meta agents to autonomously query and compress their own memory context.
- **Visual Engine**: Enhanced `chat_view.lua` and `highlights.lua` with a stack-based folding algorithm and native Neovim conceal, smoothly hiding XML ontology tags behind a `🧠 [Cognitive Abstract]` UI.
- **Testing**: Added 4 new BDD test suites (`session_ontology`, `prompt_parser_asymmetric`, `cognitive_tools`, `visual_ontology`). Test suite reached 246 absolute passing tests.
'
