# MultiContext AI - Neovim Plugin

## Overview
MultiContext AI is a native, asynchronous, high-performance plugin for Neovim that integrates autonomous AI assistants directly into the editor (inspired by the Devin/Claude Code paradigm). The plugin enables interaction with multiple specialized agents through a chat interface, providing direct access to the file system, terminal execution, autonomous reasoning loops (ReAct), and active context window management. 

In its **V1.3+** release, it features an advanced **Swarm Architecture** (Mixture of Agents - MoA), asynchronous state persistence (Stateful Workspaces), **Meta-Agent Squads**, **Quadripartite Memory (Predictive Watchdog)**, a **Pluggable and Editable Skills Ecosystem** provided with community templates, **Context Injectors (\)** for dynamic prompt composition, ultra-fast global search using **Ripgrep**, surgical code navigation via **Neovim LSP** (Go to Definition/References), a **DevOps Agent** for local Git automation, an extensive **Virtual Master Command Center**, **Situational Awareness Tools**, and a **Cognitive Optimization & Internationalization (i18n) Engine**.

## Technical Architecture

### Core Technologies
- **Language**: Lua (native integration with Neovim).
- **Testing Framework**: `plenary.nvim` (busted) - **214 Unit and Integration Tests (100% Absolute Success Rate)**, featuring severe mock isolation (I/O, Kernel, Network).
- **Asynchronous Operations & Networking**: `vim.fn.jobstart` / `vim.fn.jobstop` abstracted via a custom transport module (non-blocking `curl` promises with robust TCP chunking buffers).
- **XML Processing**: Fault-tolerant functional parser, featuring implicit tag auto-closing to prevent LLM hallucinations.
- **Concurrency**: Native *Worker Pool* implementation managing asynchronous HTTP streams without blocking Neovim's main UI thread.
- **State Serialization**: Metadata Envelopes and JSON-in-XML injection to save and restore Swarm sessions without losing the readability of the raw Markdown chat file.

### Directory Structure
```text
lua/multi_context/
├── init.lua              # Main orchestrator, live stream monitoring, and hooks
├── config.lua            # Settings, User Bootstrapping, and Auto-Setup
├── i18n.lua              # Internationalization Engine and Language Fallback (en, pt-BR)
├── agents.lua            # Initializer for the user's mctx_agents.json
├── injectors.lua         # Visual engine (\ menu) and Loader for user's dynamic macros
├── api_client.lua        # Queue router and API fallbacks
├── transport.lua         # HTTP engine (curl), streams, telemetry (debug), and cleanup
├── prompt_parser.lua     # Intent parser and Dynamic Prompt/Skill Assembler
├── tool_parser.lua       # Functional extractor and XML tag sanitizer (Auto-close logic)
├── tool_runner.lua       # Permission Gatekeeper, native executor, and plugin router
├── swarm_manager.lua     # Swarm Brain: queues, workers, ReAct, MoA, Pipelines, and Choreography
├── squads.lua            # Loader and resolver for Meta-Agent Squads
├── skills_manager.lua    # Async loader and external code validator (Hot-Reload)
├── lsp_utils.lua         # Silent bridge with Neovim LSP (Go to Definition/References)
├── react_loop.lua        # Session state manager and Circuit Breaker
├── memory_tracker.lua    # Predictive Watchdog with EMA calculation and Initial Turn Immunity
├── context_builders.lua  # Context extractors injecting strict line numbering (1 | code)
├── context_controls.lua  # Master Command Center (12 Sections: API, IAM, Swarm, History, Vault...)
├── tools.lua             # Native tools (read, edit, bash, LSP, Unified Diff, Git, Ripgrep)
├── utils.lua             # Token calculation and Workspace serialization tools
├── ui/
│   ├── popup.lua         # Floating window logic, dynamic styling, carousel, and keymaps
│   ├── scroller.lua      # Smart Auto-Scroll logic and directional tracker
│   └── highlights.lua    # Unified syntax highlights and global palette
├── tests/                # Automated Test Suite (TDD/Plenary) with complex mocks
│   ├── i18n_spec.lua             # Language Engine and Fallback Tests
│   ├── git_tools_spec.lua        # Git Automation and Gatekeeper Tests
│   ├── lsp_utils_spec.lua        # Silent LSP Bridge Tests
│   ├── tool_runner_lsp_spec.lua  # LSP Routing Tests
│   └── ... (plus 40+ files)
└── examples/
    ├── skills/           # Community Skill Templates (Jira, Pytest, SQL)
    └── injectors/        # Community Injector Templates (Project Dump, LSP Errors, Git Log)
```

## Implemented Features and Capabilities

### 1. Dynamic Canvas and Context Injectors (Phase 28)
- **Context Macros**: Pressing the `\` key in Insert Mode opens a virtual fuzzy selector (similar to the `@` command for agents), allowing users to dynamically inject project data directly below the cursor, preserving prompt readability.
- **Local Injector Ecosystem**: Users can program their own connectors by writing a simple Lua/Bash/Python script in `~/.config/nvim/mctx_injectors/`. Community templates are provided for LSP Diagnostics, Project Dumps, and Git Logs.

### 2. Master Command Center and Identity & Access Management (IAM)
- **12-Section Declarative Grid**: A unified interactive interface accessed via `:ContextControls`. Renders visual toggles (`[ ON ]`, `[ ✓ ]`), dots (`· · ·`), and expandable nodes (`[+]/[-]`).
- **Dynamic Anchored Footer**: The panel's footer dynamically instructs the user on which action to take (`<Space>`, `c`, `e`, `<CR>`) depending on cursor position, using Neovim 0.10+ native `footer` API.
- **Interactivity and State Mutation**: Total keyboard control. Allows toggling permissions, editing loop limits, ordering API fallback queues (`dd` and `p`), editing Master Prompts, and toggling telemetry. Features native protection against the `E37` error.
- **Agent Permission Matrix**: Fine-grained control listing every agent, allowing users to toggle specific tools (Skills) individually, enforcing a Principle of Least Privilege saved in `mctx_agents.json`.
- **Advanced Persona Management**: Create, safely delete, and edit an agent's *System Prompt* in an isolated temporary buffer with transparent background *Auto-Save* (`BufWritePost`).
- **Dynamic Entity Factory**: Instant creation of new Skills, Injectors, and Personas via `[ + ]` buttons in the virtual DOM, generating boilerplate code and opening the buffer immediately.

### 3. Advanced Swarm Architecture (MoA, Pipelines, and Choreography)
- **On-the-Fly Choreography (Global Flags)**: Instantly define execution flows directly in your prompt without pre-configuring JSONs:
  - **`--queue`**: Transforms your prompt into an automated Assembly Line. When one agent finishes, the next is automatically invoked without waiting for manual checkpoints.
  - **`--moa`**: Triggers a Semantic Swarm. It groups all mentioned agents and delegates the entire block to the `@tech_lead`, who autonomously reads the intent, generates the `spawn_swarm` JSON, and orchestrates the agents in parallel or pipelines.
- **Tech Lead Delegation**: Deep orchestration via the `spawn_swarm` JSON payload.
- **Dynamic Cognitive Routing (MoA)**: The visual panel allows users to define API **Cognitive Abstraction Levels** (`low/medium/high`). The system automatically checks compatibility between an API's cognitive capacity and an agent's demand, routing tasks to the most suitable idle worker (Directional Fallback/Starvation Prevention).
- **Pipelines and Choreography**: Task reincarnation in execution chains and injection of the `switch_agent` request, allowing an agent to yield control and reconfigure the *in-flight* persona without breaking the async loop.

### 4. Predictive Guardian, Quadripartite Compression, and 3 Engines
- **Watchdog via EMA**: A predictive tracker calculates the geometric Exponential Moving Average (EMA) of generated tokens, adding the weight of the current buffer. Real-time telemetry is displayed on the UI.
- **3 Compression Engines**: Configurable via the interactive panel (Semantic, Percentage, and Fixed limits).
- **The @archivist Persona**: When the limit is breached, the system intercepts the request and summons the Archivist to transmute the entire buffer into a strict XML model (`<genesis>`, `<plan>`, `<journey>`, `<now>`), hyper-compressing memory while retaining critical data.

### 5. Meta-Agent Squads and Pluggable Skills (Community V1.0)
- Transparent compilation of squad mentions (e.g., `@squad_dev`).
- Full Squad management through the panel, visualizing the execution chain and editing the `.json` file.
- Pluggable custom scripts via `~/.config/nvim/mctx_skills/` with Gatekeeper validation, autonomous hot-reload, and scope isolation.

### 6. Unified Diff and Workspace Persistence
- **Visual Resurrection**: The `History and Workspaces` section in the panel automatically lists the latest `.mctx` files saved in the project, allowing users to load complex conversations (and their background Swarm state) with a single `<CR>`.
- State persistence via JSON-in-XML injection.
- Native surgical edits coupled to the UNIX Kernel via `patch --force`.

### 7. Fuzzy Canvas and Predictive UX (Phase 29)
- **Smart Selectors (Telescope-like)**: Invoking `@` (Agents) or `\` (Injectors) operates as a live Fuzzy Finder parsing text in Insert Mode (`TextChangedI`).
- **Smart Placement**: The injection engine protects the user's prompt by placing massive context blocks (dumps, logs) on the line *below* the cursor.

### 8. Polyglot Engine (Language Agnostic)
- **Absolute Freedom**: Skills and Injectors are no longer restricted to `.lua` scripts. The engine now accepts **any executable system script** (`.sh`, `.fish`, `.py`, `.js`, compiled Golang/Rust binaries).
- **Metadata Injection via Comments**: Users document their scripts freely using simple headers (`# DESC: ...` and `# PARAM: target | string | true | desc`).
- **Environment Variable Bridge**: The AI interacts with the user's languages by exporting extracted parameters as POSIX `env` variables (e.g., sends a `query` parameter as `$MCTX_QUERY` directly to the local Bash/Fish script).

### 9. Surgical Navigation and Search (LSP + Ripgrep) (Phase 30)
- **Native Ripgrep**: Intelligent use of `rg` (with safe fallback to `git grep`) via the `search_code` tool, ensuring instant global searches, respecting `.gitignore`, and indexing newly created files.
- **Advanced LSP Integration**: The AI acts like a human inside the IDE. Through the "Silent Bridge", the AI queries Neovim's LSP server (`lsp_definition`, `lsp_references`, `lsp_document_symbols`), finding where classes/functions were defined and extracting *only the relevant code blocks*, drastically saving tokens compared to noisy RAG (Vector DBs).

### 10. Git Automation and DevOps Agent (Phase 31)
- **Autonomous DevOps Agent**: A native persona (`@devops`) dedicated exclusively to version control, tasked with evaluating Diffs and performing pure Semantic Commits.
- **Local Git Tools**: Surgical tools (`git_status`, `git_branch`, `git_commit`) available to manage the working tree and isolate implementations in temporary branches.
- **Security Gatekeeper**: Deep algorithmic locks prevent the AI from running `git add .` (forcing surgical individual file commits) and strictly forbid remote/destructive commands like `git push`, `reset --hard`, or `rebase` without manual UI confirmation.

### 11. Internationalization and Cognitive Optimization (Phase 33)
- **i18n Engine**: A reactive translation dictionary (`en` and `pt-BR`) dynamically feeds the entire interface, system messages, I/O validations, and the Command Center.
- **Cognitive Backend**: Heavy structural rules (Swarm architecture, XML formatting, ReAct logic, Watchdog boundaries) are inherently passed to the LLM in **English**. Since foundation models are primarily trained on English datasets, this effectively reduces structural hallucinations and saves tokens.
- **Adaptive Language Directive**: A conditional `sys_lang_directive` is injected into the prompt. The AI processes complex rules in English but is instructed to output its final thoughts, comments, and code in the user's chosen `config.language`.

### 12. V2.0 Event-Driven Architecture & Session AST (Phase 35)
- **Clean Architecture**: The core logic is fully decoupled from the Neovim UI through a strict PubSub `EventBus`. The UI is 100% reactive, enabling potential headless executions.
- **Centralized State Management**: A Redux-like state manager eradicates global variables and ensures predictable state mutations.
- **Session AST**: Chat history is maintained as an Abstract Syntax Tree in RAM, replacing regex-heavy parsing and allowing structured prompt building.

### 13. Cognitive Hardening & Anti-Hallucination (Phase 36)
- **Recency Bias Guardrails**: Critical formatting rules (like strict XML enforcement without markdown wrappers) are injected at the absolute end of the system prompt, exploiting LLM recency bias for maximum obedience.
- **Zero-Skill Awareness**: Agents focused on planning or philosophy with no assigned tools are explicitly warned that they lack operational capabilities, completely eliminating tool-invention hallucinations.

### 14. Network Resilience & UX Boundary Hardening (Phase 37)
- **HTTP Stream Bufferization**: Robust TCP chunking abstraction that intercepts split JSON payloads during slow network conditions, preventing parser crashes.
- **Directional Fallback**: API Client gracefully hops to the next available provider upon 500/429 errors.
- **Boundary Clamping**: Safe cyclic index limits on Fuzzy Finders preventing Neovim UI crashes (`Index Out of Bounds`).
- **Safe Undo**: The `:ContextUndo` command restores the chat to its exact prior state before an Archivist compression occurs, ensuring safety for long contexts.

### 15. Situational Awareness Tools & Active Context (Phase 38)
- **Just-in-Time Intelligence**: Instead of inflating the System Prompt, agents are equipped with tools to query their environment dynamically, enabling true *ReAct* reasoning.
- **Workforce Matrix (`get_agents_info`)**: Allows `@tech_lead` to query available agents and their precise skills before orchestrating the swarm.
- **Project Heuristics (`get_project_stack`)**: Exposes OS, Base Shell, active LSPs, and indent configurations (Tabs vs Spaces) to prevent syntax/formatting errors across all agents.
- **Deep Git State (`get_git_env`)**: Exposes current branch, commits ahead/behind, and blocks (MERGE_HEAD/REBASE) to the `@devops` agent, avoiding blind commits during conflicts.

---

## Current Development State

### ✅ Implemented, Stable, and Tested (V2.1 Architecture)
The core of the product is a cutting-edge industrial orchestration engine.
- 100% Internationalized System (i18n) and Cognitive Backend.
- `LazyVim`-like interface with Anchored Dynamic Footer and 12 Master Modules.
- Dual Extensibility: Active Polyglot Skills for the AI, Textual Injectors (`\`) for the User.
- Predictive Watchdog 2.0 (Flexible Compression Engines) & Safe Undo.
- Real-time IAM for Agents and Skills (Safe Deletion, Isolated Prompt Editing).
- Advanced Swarm (MoA, Mutable Cognitive Levels, Pipelines, Choreography).
- Pure Lua PubSub Architecture (EventBus) with Centralized State Management.
- Situational Awareness Tools enabling active environmental inspection.
- Unified Diff, Persistent Workspaces, and Meta-Agent Squads.
- Deep integration with Neovim LSP and Ripgrep for deterministic navigation.
- Local Git automation via DevOps Agent with atomic security locks.
- **Plenary Test Coverage:** 214 isolated Unit and Integration tests (0 Failures / 0 Errors - 100% Absolute Success).
