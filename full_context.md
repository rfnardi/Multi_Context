


Considere este meu projeto de plugin do neovim. Analise-o profundamente.

Esta será a fase 48. Estamos propondo agora a solução para uma restrição do Git local, uma melhoria drástica de UI/UX (que evita poluição visual no título do Neovim) e a integração final do *Swarm State* com a AST Polimórfica (permitindo que enxames passados sejam comprimidos pelo Arquivista, economizando os tokens que o JSON gigante gastava).

Isso unifica a plataforma perfeitamente. Abaixo está o **Plano de Refatoração TDD/BDD para a Fase 48**, dividido em 3 etapas modulares.

Vamos operar da seguinte forma: você escreverá scripts em bash que vou salvar como `refactorate.sh`, `create_tests.sh` ou `collect_info.sh` na pasta raíz do projeto e rodar diretamente do terminal interno do neovim com ":!bash %". Eles devem corrigir o código diretamente (sem criar segundos scripts que necessitam ser rodados posteriormente). Nossa implementação deve sempre perseguir as melhores práticas de escrita de código (clean code: DRY, SOLID, modularidade, YAGNI, KISS) e seguir uma estratégia estritamente baseada em TEST DRIVEN DEVELOPMENT, mais precisamente, BEHAVIOR DRIVEN DEVELOPMENT, entendendo que os detalhes arquiteturais devem ser resolvidos para entregar o comportamento esperado ao usuário.

======================================================================
📂 VERIFICAÇÃO DOS ARQUIVOS PARA A FASE 48
======================================================================
✅ [OK] CONTEXT.md
# MultiContext AI - Neovim Plugin

## Overview
MultiContext AI is a native, asynchronous, high-performance plugin for Neovim that integrates autonomous AI assistants directly into the editor (inspired by the Devin/Claude Code paradigm). The plugin enables interaction with multiple specialized agents through a chat interface, providing direct access to the file system, terminal execution, autonomous reasoning loops (ReAct), and active context window management. 

In its **V2.4.3** release, it features an advanced **Swarm Architecture** (Mixture of Agents - MoA), asynchronous state persistence (Stateful Workspaces), **Meta-Agent Squads**, **Quadripartite Memory (Predictive Watchdog)**, a **Pluggable and Editable Skills Ecosystem** provided with community templates, **Context Injectors (\)** for dynamic prompt composition, ultra-fast global search using **Ripgrep**, surgical code navigation via **Neovim LSP** (Go to Definition/References), a **DevOps Agent** for local Git automation, an extensive **Virtual Master Command Center**, **Situational Awareness Tools**, **Just-in-Time LSP Auto-Setup**, an **Cognitive Optimization & Internationalization (i18n) Engine**, **Active Semantic Indexing with a Cognitive Load Balancer**, a **Polymorphic Immutable Ledger** that transparently compresses context via background APIs without destroying historical data, **Enterprise-Grade Security** with Zero-UI Freeze asynchronous execution and strict Sandbox Escape prevention, and a **100% Deterministic Asynchronous Testing Architecture** guaranteeing absolute stability across the entire codebase.

## Technical Architecture

### Core Technologies
- **Language**: Lua (native integration with Neovim).
- **Testing Framework**: `plenary.nvim` (busted) - **281 Unit and Integration Tests (100% Absolute Success Rate)**, featuring severe mock isolation (I/O, Kernel, Network), a custom **Async Barrier** (Queue Draining) for Neovim's Event Loop, and a strict **Restore-Before-Assert** pattern preventing Global State Bleeding.
- **Asynchronous Operations & Networking**: `vim.fn.jobstart` / `vim.fn.jobstop` abstracted via a custom transport module (non-blocking `curl` promises with robust TCP chunking buffers).
- **XML Processing & Ledger**: Fault-tolerant functional parser, featuring implicit tag auto-closing. Chat state is natively structured as an Immutable Ledger using `<block>` tags with relational attributes (`id`, `status`, `covers`). All ReAct loops and user interactions are strictly and idempotently wrapped to preserve AST integrity.
- **Concurrency**: Native *Worker Pool* implementation managing asynchronous HTTP streams without blocking Neovim's main UI thread.
- **State Serialization & Visual Engine**: Metadata Envelopes and JSON-in-XML injection to save and restore Swarm sessions. Leverages Neovim's native `conceallevel` and `foldexpr` to invisibly render XML metadata while cleanly grouping archived history under semantic summaries.

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
├── skills_ontology.lua   # Semantic resolution mapping Agent Skills to System Tools (MCP)
├── lsp_utils.lua         # Silent bridge with Neovim LSP (Go to Definition/References)
├── lsp_manager.lua       # JIT LSP Provisioning, Extension Mappings, and Mason.nvim integration
├── react_loop.lua        # Session state manager and Circuit Breaker
├── memory_tracker.lua    # Predictive Watchdog with EMA calculation and Initial Turn Immunity
├── archiver.lua          # Relational compression engine manipulating the AST blocks
├── dynamic_watchdog.lua  # Asynchronous background librarian orchestrator
├── context_builders.lua  # Context extractors injecting strict line numbering (1 | code)
├── context_controls.lua  # Master Command Center (13 Sections: API, IAM, Skills, Tools, Swarm...)
├── tools.lua             # Native tools (read, edit, bash, LSP, Unified Diff, Git, Ripgrep)
├── utils.lua             # Token calculation and Workspace serialization tools
├── ui/
│   ├── popup.lua         # Floating window logic, dynamic styling, carousel, and keymaps
│   ├── scroller.lua      # Smart Auto-Scroll logic and directional tracker
│   └── highlights.lua    # Unified syntax highlights and global palette
├── tests/                # Automated Test Suite (TDD/Plenary) with complex mocks
│   ├── i18n_spec.lua             # Language Engine and Fallback Tests
│   ├── git_tools_spec.lua        # Git Automation and Gatekeeper Tests
│   ├── archiver_spec.lua         # Relational Compression and RAG Tests
│   ├── visual_engine_spec.lua    # Native Folds and Conceal Tests
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
- **13-Section Declarative Grid**: A unified interactive interface accessed via `:ContextControls`. Renders visual toggles (`[ ON ]`, `[ ✓ ]`), dots (`· · ·`), and expandable nodes (`[+]/[-]`).
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
- Pluggable custom scripts via `~/.config/nvim/mctx_tools/` with Gatekeeper validation, autonomous hot-reload, and scope isolation.

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

### 16. Just-in-Time LSP Auto-Setup (Phase 39)
- **Proactive Infrastructure**: When the AI attempts to edit or run diagnostics on a file, the system checks the target extension (e.g., `.rs`, `.go`) to ensure the proper LSP is active.
- **Mason.nvim Integration**: If the LSP is missing, the AI's execution is paused, and the user is prompted to install it seamlessly via `Mason` (`[S/N]`).
- **Stateful Alert Fatigue Prevention**: Rejected installations are saved in the `StateManager` to ensure the user is not repeatedly bothered during the same session.
- **JIT Attachment**: Successfully installed LSPs are dynamically attached to the buffers (`BufReadPost` hook) without requiring the user to reload the file, allowing the AI to instantly receive accurate syntax errors.

### 17. Semantic Ontology and MCP Alignment (Phases 40 and 41)
- **Model Context Protocol (MCP) Adoption**: The architecture cleanly separates **Semantic Skills** (responsibilities, behaviors, and military rules of engagement) from **System Tools** (raw executable mechanisms like bash or lua scripts).
- **Semantic IAM Dashboard**: The Master Command Center (`:ContextControls`) was visually refactored. The Gatekeeper now assigns high-level Semantic Skills (e.g., `code_refactoring`, `git_automation`) to Agents, rather than giving them blind access to raw tools.
- **Skill Guardrails & Editing**: A dedicated *Semantic Skills* UI section allows users to create new behaviors, map which System Tools they contain, and press `e` to edit their strict `Purpose`, `Trigger`, and `Protocol` in an isolated Neovim buffer. This completely eliminates the UI's cognitive dissonance and prevents raw tool hallucination.
- **Dynamic Tool Resolution**: Behind the scenes, the `skills_ontology` compiler resolves the agent's semantic skills down to a flat array of System Tools just-in-time for the API payload, acting as a flawless auto-wrapper.

### 18. Immutable Ledger, Relational Compression & Asynchronous Librarian (Phase 42)
- **Polymorphic XML Blocks**: The chat history transitioned from destructive string-based garbage collection to an append-only XML ledger. Operations and dialogue are encapsulated in `<block>` tags governed by strict metadata (`id`, `status`, `type`, `covers`), guaranteeing robust parsing and absolute structural integrity.
- **Asynchronous Librarian (Dynamic Watchdog)**: The Predictive Watchdog now features a `dynamic` mode. It transparently delegates semantic summarization to a secondary, user-selected background API (e.g., a faster/cheaper model). This eliminates UI freezes during context compression and preserves the expensive main model's context window.
- **Local RAG Capabilities (`deep_dive` tool)**: Swarm Agents are now equipped with a surgical tool to "unfold" compressed context. By executing `deep_dive` on a summary's target ID, the agent retrieves the original raw data from archived blocks on demand.
- **Native Neovim Visual Engine**: Employs Neovim's built-in `conceal` capabilities to hide raw XML tags from the user, ensuring the interface remains as readable as markdown. It dynamically creates `folds` wrapping archived interactions under their summaries (e.g., `📦 [X archived lines]`), providing a sleek UI experience while ensuring the underlying `.mctx` file remains fully hackable text.

### 19. Active Semantic Indexing & Cognitive Load Balancer (Phase 44)
- **Structured Multi-Block Injectors**: Context macros (like `project_dump`) now return structured arrays of files instead of massive raw strings, automatically encapsulating each file into its own distinct XML `<block>`.
- **Zero-Freeze UX (Provisional Abstracts)**: Massive file dumps no longer clutter the screen or freeze the UI. Files are instantly injected with a provisional `<abstract>` (e.g., `Indexing: src/main.lua...`), which is immediately folded by Neovim's visual engine.
- **Cognitive Load Balancer**: A background routing engine (`dynamic_watchdog`) distributes semantic summarization tasks (RAG) across a designated pool of secondary APIs using a Round-Robin algorithm. This enables massive parallel indexing without hitting rate limits on a single provider.
- **Asynchronous Popcorn Patching**: As the background APIs complete their tasks, the system asynchronously patches the buffer in real-time, replacing the provisional tags with true semantic abstracts (`🧠 [Cognitive Abstract] ...`), without interrupting the user's typing.

### 20. Enterprise-Grade Resilience & Security (Phases 45 and 46)
- **Zero UI-Freeze Async Tools**: Heavy native tools (`run_shell`, `apply_diff`) were entirely refactored to use Neovim's asynchronous `jobstart` API. This prevents the editor from locking up during long-running tasks (like `npm install` or applying massive patches), ensuring a completely fluid user experience.
- **Anti-OOM (Out of Memory) Protection**: Enforced strict line-read limits and binary file detection mechanisms on context builders and file dumpers. This safeguards Neovim from crashing when the user attempts to accidentally inject massive datasets (e.g., multi-gigabyte log files).
- **I/O Caching & Stutter Prevention**: Implemented intelligent session-level caching for heavy synchronous shell calls (such as resolving the git root directory). This eliminated micro-stutters during typing inside the chat buffer.
- **Sandbox Escape Prevention**: Hardened the Gatekeeper's Regex engine to strictly anchor string evaluations and proactively block shell chaining operators (`|`, `&&`, `$()`, backticks). This completely neutralizes RCE (Remote Code Execution) vulnerabilities arising from potential AI tool call hallucinations.
- **Pure Scope Isolation**: Eradicated all `_G` global variables from the architecture, shifting entirely to encapsulated module states (`StateManager`), guaranteeing zero memory leaks across sessions and multi-buffer setups.
- **Idempotent AST Encapsulation**: The ReAct orchestrator now enforces strict XML `<block>` wrapping for all user and AI interactions, completely eliminating hybrid parsing ambiguities and Double-Wrapping bugs.

### 21. Deterministic Test Architecture & State Isolation (Phase 47)
- **Async Barrier (Queue Draining)**: Intercepts Neovim's native event loop APIs (`vim.schedule` and `vim.defer_fn`) globally across the test suite. This guarantees that all background asynchronous promises resolve before a test buffer is torn down, eliminating silent `Plenary.busted` crashes and phantom leakage.
- **Global State Anti-Bleeding**: Implementation of a strict *Restore-Before-Assert* pattern ensuring global Neovim I/O and Kernel mocks (e.g., `vim.fn.system`, `vim.fn.executable`) are unfailingly restored to their original state even when `assert` exceptions interrupt the runtime flow.
- **Deterministic Suite Execution**: Ensured 100% stability in test counts (abolishing hash-based directory loading inconsistencies in Linux environments) by structurally confining every `it` evaluation within meticulously scoped `describe` lifecycle bounds.

---

## Current Development State

### ✅ Implemented, Stable, and Tested (V2.4.3 Architecture)
The core of the product is a cutting-edge industrial orchestration engine.
- **Plenary Test Coverage:** 281 isolated Unit and Integration tests (0 Failures / 0 Errors - 100% Absolute Success).
- 100% Deterministic Asynchronous Test Suite with custom Async Barriers and State Leakage Prevention.
- Idempotent XML AST enforcing strict `<block>` encapsulation for all UI and LLM I/O.
- 100% Internationalized System (i18n) and Cognitive Backend.
- `LazyVim`-like interface with Anchored Dynamic Footer and 13 Master Modules.
- Dual Extensibility: Active Polyglot Skills for the AI, Textual Injectors (`\`) for the User.
- Predictive Watchdog 2.0 (Flexible Compression Engines) & Safe Undo.
- Real-time IAM for Agents and Semantic Skills (Safe Deletion, Isolated Prompt Editing).
- Advanced Swarm (MoA, Mutable Cognitive Levels, Pipelines, Choreography).
- Pure Lua PubSub Architecture (EventBus) with Centralized State Management.
- Situational Awareness Tools enabling active environmental inspection.
- Just-in-Time LSP Provisioning with `Mason.nvim` integration.
- Unified Diff, Persistent Workspaces, and Meta-Agent Squads.
- Deep integration with Neovim LSP and Ripgrep for deterministic navigation.
- Local Git automation via DevOps Agent with atomic security locks.
- Polymorphic Immutable Ledger with Asynchronous Background Summarization (Dynamic Watchdog), Local RAG (`deep_dive`), and Native Visual Folds/Conceal.
- Active Semantic Indexing with Zero-Freeze UX, Popcorn Patching, and Cognitive Load Balancer.
- Asynchronous Tool Execution (`jobstart`) and Robust Out-of-Memory (OOM) Protection.
- Strict Sandbox Security against remote execution bypasses.
--------------------------------------
✅ [OK] lua/multi_context/tools/docs/spawn_swarm.md
<tool_definition>
  <name>spawn_swarm</name>
  <description>Delega tarefas pesadas para sub-agentes assíncronos. VOCÊ É O TECH LEAD: Não escreva código longo. Apenas leia o contexto, monte a arquitetura e delegue o trabalho braçal usando esta ferramenta.</description>
  <parameters>
    <parameter name="json_payload" type="string" required="true">JSON estrito contendo o array "tasks".</parameter>
  </parameters>
  <content_description>
    CRÍTICO / TERMINANTEMENTE PROIBIDO: 
    - NÃO envolva o JSON em uma chave inventada como {"json_payload": ...}. 
    - NÃO use blocos de código Markdown (```json).
    - Escreva o objeto JSON puro e diretamente no corpo da tag.
    
    Exemplo CORRETO de execução:
    <tool_call name="spawn_swarm">
    {
      "tasks": [
        {
          "agent": "coder",
          "chain": ["qa"],
          "context": ["src/main.lua"],
          "instruction": "Refatorar função X. O QA revisará em seguida."
        }
      ]
    }
    </tool_call>
  </content_description>
</tool_definition>
--------------------------------------
✅ [OK] lua/multi_context/tests/prompt_hardening_spec.lua
require("multi_context.tests.libuv_barrier")
local prompt_parser = require('multi_context.llm.prompt_parser')
local registry = require('multi_context.tools.registry')
local config = require('multi_context.config')

describe("Fase 36 - Prompt Hardening e Anti-Alucinação:", function()
    before_each(function()
        -- Mock simples do config para evitar poluição
        config.options.language = "en"
    end)

    it("Deve informar explicitamente quando um agente NÃO possui ferramentas", function()
        -- Simulando um agente sem skills
        local mock_agents = {
            filosofo = { system_prompt = "Sou apenas uma IA de texto.", skills = {} }
        }
        
        local prompt = prompt_parser.build_system_prompt("Base", nil, "filosofo", mock_agents, 100)
        
        assert.truthy(prompt:match("WARNING: You currently have NO TOOLS available"), 
            "O prompt DEVE alertar a IA que ela não possui braços/ferramentas para evitar alucinações.")
    end)

    it("Deve aplicar o Recency Bias Guardrails no final absoluto do prompt", function()
        local mock_agents = { coder = { system_prompt = "Codifique.", skills = {"read_file"} } }
        local prompt = prompt_parser.build_system_prompt("Base", "Mem", "coder", mock_agents, 100)
        
        assert.truthy(prompt:match("FINAL GUARDRAILS %(OBEY STRICTLY%)"), "A seção de guardrails finais deve existir.")
        
        -- Verifica se a regra contra Markdown XML está presente
        assert.truthy(prompt:match("NEVER output ```xml wrappers around your tags"), 
            "Deve proibir ativamente os wrappers markdown ao redor do XML.")
        
        -- Garante que o Guardrail é a última grande instrução injetada
        local pos_guardrail = prompt:find("FINAL GUARDRAILS")
        local pos_sys = prompt:find("CURRENT PROJECT STATE")
        assert.truthy(pos_guardrail > pos_sys, "Os Guardrails DEVEM vir no fim do arquivo para aproveitar o Recency Bias da IA.")
    end)
    
    it("O Registry de Skills deve conter as regras críticas para agentes operacionais", function()
        local manual = registry.build_manual_for_skills({"edit_file", "run_shell"})
        
        assert.truthy(manual:match("STRICT XML ONLY"), "O manual de ferramentas deve forçar XML.")
        assert.truthy(manual:match("ONE ACTION PER TURN"), "O manual de ferramentas deve forçar 1 ação por turno.")
        assert.truthy(manual:match("AUTO%-LSP ACTIVE"), "Deve avisar a IA sobre o diagnóstico automático.")
    end)
end)
--------------------------------------
✅ [OK] lua/multi_context/ui/chat_view.lua
local api = vim.api
local M   = {}

M.popup_buf = nil
M.popup_win = nil
M.code_buf_before_popup = nil
M.swarm_buffers = {}
M.current_swarm_index = 1

function M.create_popup(initial_content_or_bufnr)
    if not (M.popup_win and api.nvim_win_is_valid(M.popup_win)) then
        local cur = api.nvim_get_current_buf()
        if vim.bo[cur].buftype == "" then
            M.code_buf_before_popup = cur
        end
    end

    local config = require('multi_context.config')
    local hl     = require('multi_context.ui.highlights')
    
    local buf
    if type(initial_content_or_bufnr) == "number" and api.nvim_buf_is_valid(initial_content_or_bufnr) then
        buf = initial_content_or_bufnr
    else
        buf = api.nvim_create_buf(false, true)
        vim.bo[buf].buftype   = 'nofile'
        vim.bo[buf].bufhidden = 'hide'
        vim.bo[buf].swapfile  = false
        
        local user_prefix = "## " .. config.options.user_name .. " >> "
        if type(initial_content_or_bufnr) == "string" and initial_content_or_bufnr ~= "" then
            local init_lines = vim.split(initial_content_or_bufnr, "\n", { plain = true })
            api.nvim_buf_set_lines(buf, 0, -1, false, init_lines)
        else
            api.nvim_buf_set_lines(buf, 0, -1, false, { user_prefix })
        end
    end

    M.popup_buf = buf
    if not M.swarm_buffers or #M.swarm_buffers == 0 or M.swarm_buffers[1].buf ~= buf then
        M.swarm_buffers = { { buf = buf, name = "Main" } }
        M.current_swarm_index = 1
    end
    vim.bo[buf].filetype  = 'multicontext_chat'

    local km = { noremap = true, silent = true }
    api.nvim_buf_set_keymap(buf, "n", "<CR>", "<Cmd>lua require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = vim.api.nvim_get_current_buf() })<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<C-CR>", "<Esc><Cmd>lua require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = vim.api.nvim_get_current_buf() })<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<C-CR>", "<Cmd>lua require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = vim.api.nvim_get_current_buf() })<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<S-CR>", "<Esc><Cmd>lua require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = vim.api.nvim_get_current_buf() })<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<S-CR>", "<Cmd>lua require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = vim.api.nvim_get_current_buf() })<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<A-b>", "<Cmd>lua require('multi_context.utils.utils').copy_code_block()<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<A-b>", "<Esc><Cmd>lua require('multi_context.utils.utils').copy_code_block()<CR>a", km)
    api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>q<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<Tab>", "<Cmd>lua require('multi_context.ui.chat_view').cycle_swarm_buffer(1)<CR>", km)
    api.nvim_buf_set_keymap(buf, "n", "<S-Tab>", "<Cmd>lua require('multi_context.ui.chat_view').cycle_swarm_buffer(-1)<CR>", km)
    
    api.nvim_buf_set_keymap(buf, "n", "<C-x>", "<Cmd>lua require('multi_context.core.react_orchestrator').abort_stream(true)<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<C-x>", "<Esc><Cmd>lua require('multi_context.core.react_orchestrator').abort_stream(true)<CR>", km)

    api.nvim_buf_set_keymap(buf, "i", "@", "@<Esc><Cmd>lua require('multi_context.agents').open_agent_selector()<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "\\", "\\<Esc><Cmd>lua require('multi_context.ecosystem.injectors').open_selector()<CR>", km)

    api.nvim_buf_set_keymap(buf, "n", "<A-x>", "<Cmd>lua require('multi_context.core.react_orchestrator').ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>", km)
    api.nvim_buf_set_keymap(buf, "i", "<A-x>", "<Esc><Cmd>lua require('multi_context.core.react_orchestrator').ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>", km)

    local app = config.options.appearance or {}
    local width  = math.ceil(vim.o.columns * (tonumber(app.width) or 0.8))
    local height = math.ceil(vim.o.lines   * (tonumber(app.height) or 0.8))
    local row    = math.ceil((vim.o.lines   - height) / 2)
    local col    = math.ceil((vim.o.columns - width)  / 2)

    local win = api.nvim_open_win(buf, true, {
        relative  = 'editor',
        width     = width,
        height    = height,
        row       = row,
        col       = col,
        style     = 'minimal',
        border    = app.border or 'rounded',
        title     = require("multi_context.i18n").t("chat_title", 0),
        title_pos = 'center',
    })
    M.popup_win = win
    
    -- Ocultação NATIVA do Neovim para XML
    vim.wo[win].conceallevel = 2
    vim.wo[win].concealcursor = "nc"

    api.nvim_create_autocmd({"TextChanged", "TextChangedI", "TextChangedP"}, {
        buffer = buf,
        callback = function()
            require('multi_context.ui.chat_view').update_title()
        end
    })

    api.nvim_create_autocmd("WinClosed", {
        pattern  = tostring(win),
        once     = true,
        callback = function() M.popup_win = nil end,
    })

    local last_ln  = api.nvim_buf_line_count(buf)
    local last_txt = api.nvim_buf_get_lines(buf, last_ln - 1, last_ln, false)[1] or ""
    api.nvim_win_set_cursor(win, { last_ln, #last_txt })

    hl.apply_chat(buf)
    M.create_folds(buf)
    M.update_title()

    return buf, win
end

function M.fold_text()
    local lines_count = vim.v.foldend - vim.v.foldstart + 1
    local first_line = vim.fn.getline(vim.v.foldstart)
    
    -- FASE 43.5: Distinguindo "Abstracts" Cognitivos de "Arquivos Mortos"
    if first_line:match("<abstract>") then
        local summary_text = ""
        for i = vim.v.foldstart, vim.v.foldend do
            local l = vim.fn.getline(i)
            if l:match("<summary>") then
                summary_text = vim.trim(l:gsub("<[^>]+>", ""))
                break
            end
        end
        return " 🧠 [Cognitive Abstract] " .. summary_text
    else
        local preview = ""
        for i = vim.v.foldstart, vim.v.foldend do
            local l = vim.fn.getline(i)
            l = l:gsub("<[^>]+>", "")
            if l:match("%S") then
                preview = vim.trim(l)
                break
            end
        end
        return " 📦[" .. lines_count .. " linhas arquivadas] " .. preview
    end
end

function M.create_folds(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        local windows = vim.fn.win_findbuf(buf)
        for _, win in ipairs(windows) do
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_call(win, function()
                    vim.wo.foldmethod = "manual"
                    vim.wo.foldenable = true
                    vim.wo.foldtext = "v:lua.require('multi_context.ui.chat_view').fold_text()"
                    pcall(vim.cmd, 'normal! zE')

                    local total_lines = vim.api.nvim_buf_line_count(buf)
                    local fold_stack = {}
                    local fold_cmds = {}

										local all_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false) -- ✅ O(1) chamada C-API
                    for lnum = 1, total_lines do
											local line = all_lines[lnum]
                        if line then
                            if line:match('<block[^>]*status="archived"') then
                                table.insert(fold_stack, { type = "block", start = lnum })
                            elseif line:match('<abstract>') then
                                table.insert(fold_stack, { type = "abstract", start = lnum })
                            end
                            
                            if line:match('</block>') then
                                for i = #fold_stack, 1, -1 do
                                    if fold_stack[i].type == "block" then
                                        local start_fold = fold_stack[i].start
                                        if lnum > start_fold then
                                            table.insert(fold_cmds, string.format("%d,%dfold", start_fold, lnum))
                                            table.insert(fold_cmds, string.format("%dfoldclose", start_fold))
                                        end
                                        table.remove(fold_stack, i)
                                        break
                                    end
                                end
                            elseif line:match('</abstract>') then
                                for i = #fold_stack, 1, -1 do
                                    if fold_stack[i].type == "abstract" then
                                        local start_fold = fold_stack[i].start
                                        if lnum > start_fold then
                                            table.insert(fold_cmds, string.format("%d,%dfold", start_fold, lnum))
                                            table.insert(fold_cmds, string.format("%dfoldclose", start_fold))
                                        end
                                        table.remove(fold_stack, i)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Agrupa dezenas de dobras em uma única execução em C para performance extrema
                    if #fold_cmds > 0 then
                        pcall(vim.cmd, table.concat(fold_cmds, " | "))
                    end

                    local win_height = vim.api.nvim_win_get_height(win)
                    local target_scrolloff = math.floor(win_height / 3)
                    local current_so = vim.wo.scrolloff
                    vim.wo.scrolloff = target_scrolloff
                    pcall(vim.cmd, "normal! zb")
                    vim.wo.scrolloff = current_so
                end)
            end
        end
    end)
end

function M.update_title()
    if not M.popup_win or not vim.api.nvim_win_is_valid(M.popup_win) then return end
    local ok, conf = pcall(vim.api.nvim_win_get_config, M.popup_win)
    if ok and conf.relative and conf.relative ~= "" then
        local utils = require('multi_context.utils.utils')
        local active_buf = M.popup_buf
        if M.swarm_buffers and #M.swarm_buffers > 0 and M.current_swarm_index then
            local sb = M.swarm_buffers[M.current_swarm_index]
            if sb and sb.buf and vim.api.nvim_buf_is_valid(sb.buf) then
                active_buf = sb.buf
            end
        end
        local tokens = utils.estimate_tokens(active_buf)
        local new_title = ""
        if M.swarm_buffers and #M.swarm_buffers > 1 then
            local parts = {}
            for i, sb in ipairs(M.swarm_buffers) do
                local prefix = (i == M.current_swarm_index) and "*" or ""
                table.insert(parts, string.format("%s[%d:%s]", prefix, i, sb.name))
            end
            new_title = " " .. table.concat(parts, " | ") .. string.format(" | ~%d tokens ", tokens) .. " "
        else
            new_title = require("multi_context.i18n").t("chat_title", tokens)
        end
        local config = require("multi_context.config")
        if config.options.auto_inject_context_md and utils.get_context_md_path() then
            new_title = new_title .. "[📖 CONTEXT.md: Active] "
        end
        pcall(vim.api.nvim_win_set_config, M.popup_win, { title = new_title, title_pos = 'center' })
    end
end

function M.create_swarm_buffer(agent_name, initial_instruction, api_name)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype   = 'nofile'
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].swapfile  = false
    vim.bo[buf].filetype  = 'multicontext_chat'

    local lines = { 
        require("multi_context.i18n").t("swarm_worker_title"), 
        require("multi_context.i18n").t("agent_label") .. agent_name, 
        require("multi_context.i18n").t("api_label") .. (api_name or require("multi_context.i18n").t("unknown")), 
        "" 
    }
    if initial_instruction then
        for _, l in ipairs(vim.split(initial_instruction, "\n", {plain=true})) do table.insert(lines, l) end
    end
    table.insert(lines, "")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    if not M.swarm_buffers then M.swarm_buffers = {} end
    table.insert(M.swarm_buffers, { buf = buf, name = agent_name, status = "Rodando" })
    local km = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>q<CR>", km)
    vim.api.nvim_buf_set_keymap(buf, "n", "<Tab>", "<Cmd>lua require('multi_context.ui.chat_view').cycle_swarm_buffer(1)<CR>", km)
    vim.api.nvim_buf_set_keymap(buf, "n", "<S-Tab>", "<Cmd>lua require('multi_context.ui.chat_view').cycle_swarm_buffer(-1)<CR>", km)
    require('multi_context.ui.highlights').apply_chat(buf)
    M.create_folds(buf)
    return buf
end

function M.cycle_swarm_buffer(dir)
    if not M.swarm_buffers or #M.swarm_buffers < 2 then return end
    M.current_swarm_index = M.current_swarm_index + dir
    if M.current_swarm_index > #M.swarm_buffers then M.current_swarm_index = 1 end
    if M.current_swarm_index < 1 then M.current_swarm_index = #M.swarm_buffers end
    local target_buf = M.swarm_buffers[M.current_swarm_index].buf
    if M.popup_win and vim.api.nvim_win_is_valid(M.popup_win) then
        vim.api.nvim_win_set_buf(M.popup_win, target_buf)
        M.update_title()
    end
end

local EventBus = require('multi_context.core.event_bus')
EventBus.on("UI_APPEND_CHUNK", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    if type(payload.chunk) ~= "string" or payload.chunk == "" then return end
    local lines_to_add = vim.split(payload.chunk, "\n", {plain = true})
    local count = vim.api.nvim_buf_line_count(payload.buf)
    local last_line = vim.api.nvim_buf_get_lines(payload.buf, count - 1, count, false)[1] or ""
    lines_to_add[1] = last_line .. lines_to_add[1]
    vim.api.nvim_buf_set_lines(payload.buf, count - 1, count, false, lines_to_add)
    if M.popup_win and vim.api.nvim_win_is_valid(M.popup_win) then M.update_title() end
end)
EventBus.on("UI_SWARM_WORKER_UPDATE", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    local lines = vim.split(payload.text, "\n", {plain=true})
    vim.api.nvim_buf_set_lines(payload.buf, 4, -1, false, lines)
end)
EventBus.on("UI_TERMINATE_TURN", function(payload)
    local M_pop = require('multi_context.ui.chat_view')
    local buf = M_pop.popup_buf
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    local next_prompt_lines = { "", "## API atual: " .. payload.current_api, "## " .. payload.user_name .. " >> " }
    if payload.queued_tasks and payload.queued_tasks ~= "" then
        if not payload.is_queue_mode then table.insert(next_prompt_lines, require("multi_context.i18n").t("checkpoint")) end
        for _, q_line in ipairs(vim.split(payload.queued_tasks, "\n")) do table.insert(next_prompt_lines, q_line) end
    end
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, next_prompt_lines)
    M_pop.create_folds(buf)
    require('multi_context.ui.highlights').apply_chat(buf)
    M_pop.update_title()
    if M_pop.popup_win and vim.api.nvim_win_is_valid(M_pop.popup_win) then
        pcall(vim.api.nvim_win_set_cursor, M_pop.popup_win, { vim.api.nvim_buf_line_count(buf), 0 })
        vim.cmd("normal! zz"); vim.cmd("startinsert!")
    end
    if payload.auto_trigger then
        vim.cmd("stopinsert")
        vim.defer_fn(function() require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = buf }) end, 100)
    end
end)
EventBus.on("UI_SET_LINES_PARTIAL", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    vim.api.nvim_buf_set_lines(payload.buf, payload.start_idx, payload.end_idx, false, payload.lines)
end)
EventBus.on("UI_SET_LINES", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    vim.api.nvim_buf_set_lines(payload.buf, 0, -1, false, payload.lines)
end)
EventBus.on("UI_APPEND_LINES", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    vim.api.nvim_buf_set_lines(payload.buf, -1, -1, false, payload.lines)
    require('multi_context.ui.highlights').apply_chat(payload.buf)
end)
EventBus.on("UI_ARCHIVIST_DONE", function(payload)
    if not payload.buf or not vim.api.nvim_buf_is_valid(payload.buf) then return end
    local p = require('multi_context.ui.chat_view')
    require('multi_context.ui.highlights').apply_chat(payload.buf)
    p.create_folds(payload.buf)
    p.update_title()
end)
EventBus.on("UI_UPDATE_TITLE", function() require('multi_context.ui.chat_view').update_title() end)
EventBus.on("UI_START_STREAMING", function(payload)
    local p = require('multi_context.ui.chat_view')
    require('multi_context.ui.scroller').start_streaming(payload.buf, p.popup_win)
end)
EventBus.on("UI_STOP_STREAMING", function(payload) require('multi_context.ui.scroller').stop_streaming(payload.buf) end)
EventBus.on("UI_CHUNK_RECEIVED", function(payload)
    local p = require('multi_context.ui.chat_view')
    require('multi_context.ui.scroller').on_chunk_received(payload.buf, p.popup_win)
end)

return M
--------------------------------------
✅ [OK] lua/multi_context/tests/chat_view_spec.lua
require("multi_context.tests.libuv_barrier")
local EventBus = require('multi_context.core.event_bus')
local popup = require('multi_context.ui.chat_view')

describe("UI View Arquitetura 2.0 (popup.lua):", function()
    it("Deve injetar texto no buffer ao escutar o evento UI_APPEND_CHUNK", function()
        local buf, win = popup.create_popup("Inicio")
        
        -- Em vez de chamar funções da UI, emitimos um evento no barramento global!
        EventBus.emit("UI_APPEND_CHUNK", { buf = buf, chunk = "Texto do LLM injetado via Evento!" })
        
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        
        assert.truthy(content:match("Texto do LLM injetado via Evento!"), "A UI falhou em reagir ao evento do core")
    end)
    
    it("Deve atualizar o buffer do worker do Swarm ao escutar UI_SWARM_WORKER_UPDATE", function()
        local buf = popup.create_swarm_buffer("mock_agent", "instrucao", "mock_api")
        
        EventBus.emit("UI_SWARM_WORKER_UPDATE", { buf = buf, text = "Relatorio do Swarm via Evento" })
        
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        assert.truthy(content:match("Relatorio do Swarm via Evento"), "A UI do Swarm falhou em reagir ao evento")
    end)
end)
--------------------------------------
✅ [OK] lua/multi_context/utils/utils.lua
-- lua/multi_context/utils.lua
local M   = {}
local api = vim.api

M.get_context_md_path = function()
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
    local path = root .. "/CONTEXT.md"
    if vim.fn.filereadable(path) == 1 then return path end
    return nil
end

M.estimate_tokens = function(buf)
    if not buf or not api.nvim_buf_is_valid(buf) then return 0 end
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local char_count = 0
    for _, line in ipairs(lines) do
        char_count = char_count + #line + 1
    end
    return math.floor(char_count / 4)
end


M.build_workspace_content = function(buf, existing_filename)
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    local session_id = existing_filename and string.match(existing_filename, "chat_(%d+_%d+).mctx")
    local created_at = os.date("%Y-%m-%dT%H:%M:%S")
    local updated_at = os.date("%Y-%m-%dT%H:%M:%S")

    -- Se já for uma sessão antiga, extraímos o ID/Creation e removemos a tag suja
    local existing_session = content:match("<mctx_session(.-)/>")
    if existing_session then
        local old_id = existing_session:match('id="([^"]+)"')
        local old_created = existing_session:match('created="([^"]+)"')
        if old_id then session_id = old_id end
        if old_created then created_at = old_created end
        content = content:gsub("<mctx_session.-/>%s*", "")
    end
    
    if not session_id then session_id = os.date("%Y%m%d_%H%M%S") end
    
    -- Limpa estado do swarm antigo e substitui
    content = content:gsub("<swarm_state>.-</swarm_state>%s*", "")
    
    local swarm = require('multi_context.core.swarm_manager')
    local popup = require('multi_context.ui.chat_view')
    
    local state_data = { queue = swarm.state.queue or {}, reports = swarm.state.reports or {}, buffers = {} }
    
    if popup.swarm_buffers then
        for i, sb in ipairs(popup.swarm_buffers) do
            if i > 1 and sb.buf and api.nvim_buf_is_valid(sb.buf) then
                local b_lines = api.nvim_buf_get_lines(sb.buf, 0, -1, false)
                table.insert(state_data.buffers, { name = sb.name, status = sb.status, lines = b_lines })
            end
        end
    end
    
    local ok, json_state = pcall(vim.fn.json_encode, state_data)
    local swarm_xml = ""
    if ok and json_state and json_state ~= "{}" then
        swarm_xml = "\n<swarm_state>\n" .. json_state .. "\n</swarm_state>"
    end
    
    local header = string.format('<mctx_session id="%s" created="%s" updated="%s" />\n', session_id, created_at, updated_at)
    local new_content = header .. vim.trim(content) .. "\n" .. swarm_xml
    
    local new_filename = existing_filename
    if not new_filename then
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
        local chat_dir = root .. "/.mctx_chats"
        new_filename = chat_dir .. "/chat_" .. session_id .. ".mctx"
    end
    
    return new_filename, new_content
end

M.load_workspace_state = function(buf)
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    local swarm_state_str = content:match("<swarm_state>%s*(.-)%s*</swarm_state>")
    if swarm_state_str then
        local ok, parsed = pcall(vim.fn.json_decode, swarm_state_str)
        if ok and type(parsed) == "table" then
            local swarm = require('multi_context.core.swarm_manager')
            local popup = require('multi_context.ui.chat_view')
            
            swarm.state.queue = parsed.queue or {}
            swarm.state.reports = parsed.reports or {}
            
            if parsed.buffers then
                for _, bdata in ipairs(parsed.buffers) do
                    local exists = false
                    if popup.swarm_buffers then
                        for _, sb in ipairs(popup.swarm_buffers) do
                            if sb.name == bdata.name then exists = true; break end
                        end
                    end
                    if not exists then
                        local new_buf = api.nvim_create_buf(false, true)
                        vim.bo[new_buf].buftype   = 'nofile'
                        vim.bo[new_buf].bufhidden = 'hide'
                        vim.bo[new_buf].swapfile  = false
                        vim.bo[new_buf].filetype  = 'multicontext_chat'
                        api.nvim_buf_set_lines(new_buf, 0, -1, false, bdata.lines or {})
                        
                        if not popup.swarm_buffers then popup.swarm_buffers = {} end
                        table.insert(popup.swarm_buffers, { buf = new_buf, name = bdata.name, status = bdata.status or "Restaurado" })
                        require('multi_context.ui.highlights').apply_chat(new_buf)
                        popup.create_folds(new_buf)
                    end
                end
            end
        end
    end
end

M.export_to_workspace = function(content, existing_filename)
    local filename = existing_filename
    if not filename then
        local timestamp = os.date("%Y%m%d_%H%M%S")
        
        -- MÁGICA: Busca a raiz do projeto atual
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error == 0 then
            root = root:gsub("\n", "")
        else
            root = vim.fn.getcwd() -- Fallback caso não seja repositório git
        end
        
        local chat_dir = root .. "/.mctx_chats"
        
        if vim.fn.isdirectory(chat_dir) == 0 then
            vim.fn.mkdir(chat_dir, "p")
        end
        filename = chat_dir .. "/chat_" .. timestamp .. ".mctx"
    end
    
    local fname_esc = vim.fn.fnameescape(filename)
    local ok = pcall(vim.cmd, "edit " .. fname_esc)
    if not ok then vim.cmd("split " .. fname_esc) end
    
    local new_buf = vim.api.nvim_get_current_buf()
    vim.bo[new_buf].filetype = "multicontext_chat"
    
    local lines = M.split_lines(content)
    vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, lines)
    vim.bo[new_buf].modified = true
    
    local last_line = vim.api.nvim_buf_line_count(new_buf)
    vim.api.nvim_win_set_cursor(0, { last_line, 0 })
    vim.cmd("stopinsert")
    
    require('multi_context.ui.highlights').apply_chat(new_buf)
    require('multi_context.ui.chat_view').create_folds(new_buf)
    
    local km = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(new_buf, "i", "@", "@<Esc><Cmd>lua require('multi_context.agents').open_agent_selector()<CR>", km)
    api.nvim_buf_set_keymap(new_buf, "i", "\\", "\\<Esc><Cmd>lua require('multi_context.ecosystem.injectors').open_selector()<CR>", km)
    vim.api.nvim_buf_set_keymap(new_buf, "n", "<A-x>", "<Cmd>lua require('multi_context.core.react_orchestrator').ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>", km)
    vim.api.nvim_buf_set_keymap(new_buf, "i", "<A-x>", "<Esc><Cmd>lua require('multi_context.core.react_orchestrator').ExecuteTools(nil, vim.api.nvim_get_current_buf())<CR>", km)

    require('multi_context.core.event_bus').emit("WORKSPACE_SAVED", { file = filename })
    return filename
end

M.split_lines = function(s)
    if not s or s == "" then return {} end
    -- Usa a API nativa e otimizada do Neovim (não gera arrays com posições vazias fantasmas)
    return vim.split(s, "\n", { plain = true })
end

M.insert_after = function(buf, line_idx, lines)
    local target = (line_idx == -1) and api.nvim_buf_line_count(buf) or line_idx
    api.nvim_buf_set_lines(buf, target, target, false, lines)
end

M.copy_code_block = function()
    local buf    = api.nvim_get_current_buf()
    local cursor = api.nvim_win_get_cursor(0)[1]
    local lines  = api.nvim_buf_get_lines(buf, 0, -1, false)
    local s, e   = nil, nil
    for i = cursor, 1, -1 do
        if lines[i] and lines[i]:match("^```") then s = i; break end
    end
    for i = cursor, #lines do
        if lines[i] and lines[i]:match("^```") and i ~= s then e = i; break end
    end
    if s and e then
        vim.fn.setreg('+', table.concat(api.nvim_buf_get_lines(buf, s, e - 1, false), "\n"))
        vim.notify("Código copiado!")
    else
        vim.notify("Nenhum bloco de código encontrado.", vim.log.levels.WARN)
    end
end

M.apply_highlights        = function(b) require('multi_context.ui.highlights').apply_chat(b) end
M.get_git_diff            = function()  return require('multi_context.utils.context_builders').get_git_diff() end
M.get_tree_context        = function()  return require('multi_context.utils.context_builders').get_tree_context() end
M.get_all_buffers_content = function()  return require('multi_context.utils.context_builders').get_all_buffers_content() end
M.find_last_user_line     = function(b) return require('multi_context.core.conversation').find_last_user_line(b) end
M.load_api_config         = function()  return require('multi_context.config').load_api_config() end
M.load_api_keys           = function()  return require('multi_context.config').load_api_keys() end
M.set_selected_api        = function(n) return require('multi_context.config').set_selected_api(n) end
M.get_api_names           = function()  return require('multi_context.config').get_api_names() end
M.get_current_api         = function()  return require('multi_context.config').get_current_api() end

return M






--------------------------------------
✅ [OK] lua/multi_context/tests/utils_spec.lua
require("multi_context.tests.libuv_barrier")
local utils = require('multi_context.utils.utils')

describe("Utils Module:", function()
    it("Deve dividir strings por quebra de linha corretamente", function()
        local str = "linha1\nlinha2\nlinha3"
        local res = utils.split_lines(str)
        assert.are.same({"linha1", "linha2", "linha3"}, res)
    end)

    it("Deve estimar tokens corretamente (4 chars = 1 token)", function()
        local buf = vim.api.nvim_create_buf(false, true)
        -- Injeta 2 linhas. A lógica soma: (#linha + 1). Total: (5+1) + (5+1) = 12 chars
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"12345", "12345"})
        
        local tokens = utils.estimate_tokens(buf)
        -- 12 / 4 = 3 tokens
        assert.are.same(3, tokens)
    end)
end)






--------------------------------------
✅ [OK] lua/multi_context/core/swarm_manager.lua
local config = require('multi_context.config')
local api_client = require('multi_context.llm.api_client')
local popup = require('multi_context.ui.chat_view')
local tools = require('multi_context.ecosystem.native_tools')
local agents = require('multi_context.agents')
local tool_parser = require('multi_context.ecosystem.tool_parser')
local tool_runner = require('multi_context.ecosystem.tool_runner')
local i18n = require('multi_context.i18n')

local M = {}
M.state = { queue = {}, workers = {}, reports = {} }

M.reset = function() M.state.queue = {}; M.state.workers = {}; M.state.reports = {} end

M.init_swarm = function(json_payload)
    M.reset()
    if not json_payload or json_payload == "" then return false end
    local clean_payload = vim.trim(json_payload)
    local ok, decoded = pcall(vim.fn.json_decode, clean_payload)
    if not ok then
        -- A Mágica de Extração: Ignora tudo e pega do primeiro { até o último }
        local json_match = clean_payload:match("%b{}")
        if json_match then ok, decoded = pcall(vim.fn.json_decode, json_match) end
    end
    -- NOVO: Fallback para desembrulhar a alucinação "json_payload" do LLM
    if ok and type(decoded) == "table" and decoded.json_payload and type(decoded.json_payload) == "string" then
        local inner_ok, inner_decoded = pcall(vim.fn.json_decode, decoded.json_payload)
        if inner_ok and type(inner_decoded) == "table" then
            decoded = inner_decoded
        end
    end
    if not ok or type(decoded) ~= "table" or type(decoded.tasks) ~= "table" then 
        return false, "ERRO JSON: Formato inválido. Use apenas chaves { } e o array 'tasks'." 
    end
    local ok_sq, squads_manager = pcall(require, "multi_context.ecosystem.squads")
    local squads = ok_sq and squads_manager.load_squads() or {}
    local new_tasks = {}
    for _, task in ipairs(decoded.tasks) do
        local target = task.agent or (task.chain and task.chain[1])
        if target and squads[target] then
            local squad = squads[target]
            local main_task = vim.deepcopy(squad.tasks[1] or {})
            local col_purp = squad.collective_purpose or squad.description or ""
            local purpose_block = col_purp ~= "" and ("\n=== SQUAD MISSION: " .. col_purp .. " ===\n") or ""
            main_task.instruction = purpose_block .. (main_task.instruction or "") .. "\n\nDelegated Task: " .. (task.instruction or "")
            if not main_task.agent and main_task.chain and #main_task.chain > 0 then main_task.agent = main_task.chain[1] end
            table.insert(new_tasks, main_task)
            if squad.tasks then for i = 2, #squad.tasks do table.insert(new_tasks, squad.tasks[i]) end end
        else
            if not task.agent and type(task.chain) == "table" and #task.chain > 0 then task.agent = task.chain[1] end
            table.insert(new_tasks, task)
        end
    end
    M.state.queue = new_tasks
    local apis = require("multi_context.config").get_spawn_apis()
    for _, api_cfg in ipairs(apis) do table.insert(M.state.workers, { api = api_cfg, busy = false, current_task = nil }) end
    return true
end

M.dispatch_next = function()
    if #M.state.queue == 0 then
        local any_busy = false
        for _, w in ipairs(M.state.workers) do if w.busy then any_busy = true; break end end
        if not any_busy and M.on_swarm_complete then
            local summary = i18n.t("swarm_final_report") .. "\n"
            for _, rep in ipairs(M.state.reports) do
                summary = summary .. "\n" .. i18n.t("swarm_agent_res", rep.agent, rep.result)
            end
            M.on_swarm_complete(summary)
        end
        return
    end

    local level_val = { low = 1, medium = 2, high = 3 }
    local loaded_agents = require('multi_context.agents').load_agents()

    local i = 1
    local max_attempts = #M.state.queue
    local attempts = 0
    while i <= #M.state.queue and attempts < max_attempts do
        attempts = attempts + 1
        local task = M.state.queue[i]
        local agent_def = loaded_agents[task.agent]
        local req_level = (agent_def and agent_def.abstraction_level) and level_val[agent_def.abstraction_level] or 3
        
        local selected_worker = nil
        local best_diff = 999
        
        for _, worker in ipairs(M.state.workers) do
            if not worker.busy then
                local api_level = worker.api.abstraction_level and level_val[worker.api.abstraction_level] or 2
                if api_level >= req_level then
                    local diff = api_level - req_level
                    if diff < best_diff then
                        best_diff = diff
                        selected_worker = worker
                    end
                end
            end
        end

        if selected_worker then
            table.remove(M.state.queue, i)
            local worker = selected_worker
            worker.busy = true
            worker.current_task = task
            local buf_id = popup.create_swarm_buffer(task.agent, task.instruction, worker.api.name)
            
            local system_prompt = "You are a sub-agent operating in SWARM mode. Your strict task is: " .. (task.instruction or "")
            if loaded_agents[task.agent] then
                system_prompt = system_prompt .. "\n\n=== YOUR GUIDELINES ===\n" .. loaded_agents[task.agent].system_prompt
            end
            
            local registry = require('multi_context.tools.registry')
            local agent_def_for_skills = loaded_agents[task.agent] or loaded_agents["coder"] or {skills={}}
            system_prompt = system_prompt .. "\n\n" .. registry.build_manual_for_skills(agent_def_for_skills.skills)
            
            local context_text = "" 
            if type(task.context) == "table" then
                for _, path in ipairs(task.context) do
                    if path ~= "*" and path ~= "" then
                        context_text = context_text .. "\n== File: " .. path .. " ==\n" .. tools.read_file(path)
                    end
                end
            end
            system_prompt = system_prompt .. "\n\n=== INITIAL CONTEXT PROVIDED ===\n" .. context_text            
            system_prompt = system_prompt .. "\n\n=== DELIVERY RULES & TOOL SYNTAX (CRITICAL) ===\n1. TOOL SYNTAX: You must ONLY use the exact tool names provided in the ACTIVE SKILLS list. Do NOT invent tools or XML tags (e.g., no <bash>, <execute>, <function>). Parameters like 'path' MUST be passed as XML attributes, e.g.: <tool_call name=\"read_file\" path=\"src/main.ts\"></tool_call>\n2. TASK COMPLETION: When your task is fully completed and you DO NOT need to call any more tools, you MUST output your results inside <final_report>...</final_report> tags.\n3. FATAL ERROR WARNING: If you stop responding without using a tool AND without opening a <final_report> tag, the system will consider it a FATAL ERROR and fail your task. ALWAYS conclude with <final_report>. The report MUST include a clear summary of what was done, the edited files, and list in a structured way the executed Git operations (if any)."

            local cfg = require('multi_context.config').options
            if cfg.language == "pt-BR" then
                system_prompt = system_prompt .. i18n.t("sys_lang_directive")
            end

            local messages = {
                { role = "system", content = system_prompt },
                { role = "user", content = "Start executing your task. If you need more information, use the available tools. When you finish all the work, provide a summary." }
            }
            
            local visual_history = ""
            local final_report_text = ""

            local function execute_turn()
                local current_chunk = ""
                api_client.execute(messages,
                    function() end,
                    function(chunk) 
                        current_chunk = current_chunk .. chunk 
                        require('multi_context.core.event_bus').emit("UI_SWARM_WORKER_UPDATE", { 
                            buf = buf_id, 
                            text = visual_history .. "\n\n## IA >>\n" .. current_chunk 
                        })
                    end,
                    function(api_entry, metrics)
                        visual_history = visual_history .. "\n\n## IA >>\n" .. current_chunk
                        table.insert(messages, { role = "assistant", content = current_chunk })
                        
                        local extracted_report = current_chunk:match("<final_report>(.-)</final_report>")
                        if extracted_report then
                            final_report_text = vim.trim(extracted_report)
                        else
                            final_report_text = ""
                        end

                        local sanitized = tool_parser.sanitize_payload(current_chunk)
                        
                        if sanitized:match("<tool_call") then
                            local new_content = ""
                            local cursor = 1
                            local approve_ref = { value = true }
                            
                            while cursor <= #sanitized do
                                local parsed = tool_parser.parse_next_tool(sanitized, cursor)
                                if not parsed then break end
                                if parsed.is_invalid or not parsed.name or parsed.name == "" then
                                    cursor = parsed.close_end + 1
                                else
                                    local tag_out = tool_runner.execute(parsed, true, approve_ref, buf_id, task.agent)
                                    new_content = new_content .. "\n" .. tag_out
                                    cursor = parsed.close_end + 1
                                end
                            end
                            
                            if new_content ~= "" then
                                local switch_target = new_content:match("SWITCH_AGENT_REQUEST:([%w_]+)")
                                
                                task.turn_count = (task.turn_count or 0) + 1
                                if task.turn_count > 15 then
                                    new_content = "FATAL ERROR: Limite máximo de 15 turnos autônomos excedido no Swarm."
                                    switch_target = nil
                                end
                                
                                if switch_target then
                                    task.switch_count = (task.switch_count or 0) + 1
                                    if task.switch_count > 3 then 
                                        switch_target = nil
                                        new_content = "FATAL ERROR: Loop infinito de troca de agente detectado (limite de 3) excedido." 
                                    end
                                end
                                
                                if switch_target then
                                    local is_allowed = false
                                    if type(task.allow_switch) == "table" then
                                        for _, allowed in ipairs(task.allow_switch) do
                                            if allowed == switch_target then is_allowed = true; break end
                                        end
                                    end
                                    
                                    if is_allowed then
                                        task.agent = switch_target
                                        local loaded_agents = require('multi_context.agents').load_agents()
                                        local new_system = "You are a sub-agent operating in SWARM mode. Your strict task is: " .. (task.instruction or "")
                                        if loaded_agents[switch_target] then
                                            new_system = new_system .. "\n\n=== YOUR GUIDELINES ===\n" .. loaded_agents[switch_target].system_prompt
                                        end
                                        new_system = new_system .. "\n\n=== INITIAL CONTEXT PROVIDED ===\n" .. context_text
                                        new_system = new_system .. "\n\n=== DELIVERY RULES & TOOL SYNTAX (CRITICAL) ===\n1. TOOL SYNTAX: You must ONLY use exact tool names from ACTIVE SKILLS. Do NOT invent tags (no <bash>, <execute>). Parameters like 'path' MUST be XML attributes.\n2. TASK COMPLETION: When your task is fully completed, you MUST output results inside <final_report>...</final_report> tags.\n3. FATAL ERROR WARNING: Stopping without using a tool AND without a <final_report> is a FATAL ERROR. ALWAYS conclude with <final_report>. The report MUST include a clear summary of what was done, the edited files, and list in a structured way the executed Git operations (if any). This tag ends your execution, and without it, the master will not read your response."
                                        
                                        local cfg = require('multi_context.config').options
                                        if cfg.language == "pt-BR" then
                                            new_system = new_system .. i18n.t("sys_lang_directive")
                                        end
                                        
                                        messages[1].content = new_system
                                        new_content = i18n.t("swarm_success_switch", switch_target)
                                        
                                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                            local popup = require('multi_context.ui.chat_view')
                                            if popup.swarm_buffers then
                                                for _, sb in ipairs(popup.swarm_buffers) do
                                                    if sb.buf == buf_id then
                                                        sb.name = switch_target
                                                        break
                                                    end
                                                end
                                            end
                                            pcall(popup.update_title)
                                        end
                                    else
                                        new_content = i18n.t("swarm_err_switch", task.agent, switch_target)
                                    end
                                end

                                visual_history = visual_history .. "\n\n## Sistema >>\n" .. new_content
                                table.insert(messages, { role = "user", content = new_content })
                                execute_turn() 
                                return
                            end
                        end
                        
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                            table.insert(lines, "")
                            table.insert(lines, i18n.t("swarm_task_done"))
                            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                        end
                        
                        worker.busy = false
                        local clean_res = final_report_text:gsub("%s+", "")
                        
                        task.retries = task.retries or 0
                        if clean_res == "" and task.retries < 2 then
                            task.retries = task.retries + 1
                            if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                                table.insert(lines, i18n.t("swarm_api_empty", task.retries))
                                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                            end
                            table.insert(M.state.queue, task)
                        else
                            if clean_res == "" then final_report_text = i18n.t("swarm_fail_repeated") end
                            local has_next = false
                            if type(task.chain) == 'table' then
                                local c_idx = 0
                                for idx, a in ipairs(task.chain) do if a == task.agent then c_idx = idx; break end end
                                if c_idx > 0 and c_idx < #task.chain then
                                    task.agent = task.chain[c_idx + 1]
                                    task.instruction = (task.instruction or '') .. '\n\n' .. i18n.t("swarm_prev_report") .. '\n' .. final_report_text
                                    task.retries = 0
                                    table.insert(M.state.queue, task)
                                    has_next = true
                                end
                            end
                            if not has_next then
                            table.insert(M.state.reports, { agent = task.agent, result = final_report_text })
                            end
                        end
                        vim.schedule(M.dispatch_next)
                    end,
                    function(err)
                        if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                            local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                            table.insert(lines, "")
                            table.insert(lines, i18n.t("swarm_api_err", tostring(err)))
                            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                        end
                        worker.busy = false
                        task.retries = task.retries or 0
                        if task.retries < 2 then
                            task.retries = task.retries + 1
                            if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
                                local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
                                table.insert(lines, i18n.t("swarm_api_fail", worker.api.name, task.retries))
                                vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                            end
                            table.insert(M.state.queue, task)
                        else
                            table.insert(M.state.reports, { agent = task.agent, result = i18n.t("swarm_fatal_err", tostring(err)) })
                        end
                        vim.schedule(M.dispatch_next)
                    end,
                    worker.api
                )
            end
            
            execute_turn()
        else
            i = i + 1
        end
    end
end

return M
--------------------------------------
✅ [OK] lua/multi_context/init.lua
local api = vim.api
local utils = require('multi_context.utils.utils')
local popup = require('multi_context.ui.chat_view')
local commands = require('multi_context.commands')
local config = require('multi_context.config')
local react_orchestrator = require('multi_context.core.react_orchestrator')

local M = {}
M.popup_buf = popup.popup_buf
M.popup_win = popup.popup_win
M.current_workspace_file = nil

M.setup = function(opts)
    if config and config.setup then config.setup(opts) end
    react_orchestrator.setup()
end

M.OnSwarmComplete = function(summary)
    local p = require('multi_context.ui.chat_view')
    local buf = p.popup_buf
    if not buf or not api.nvim_buf_is_valid(buf) then return end

    if p.swarm_buffers and #p.swarm_buffers > 0 then
        p.current_swarm_index = 1
        if p.popup_win and api.nvim_win_is_valid(p.popup_win) then
            api.nvim_win_set_buf(p.popup_win, p.swarm_buffers[1].buf)
            p.update_title()
        end
    end

    local cfg = require('multi_context.config')
    local user_prefix = "## " .. (cfg.options.user_name or "User") .. " >>"
    
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    table.insert(lines, "")
    table.insert(lines, user_prefix .. " [Sistema]:")
    
    local append_text = summary .. "\n\nPor favor, consolide essas informações, verifique se houve algum erro nos sub-agentes, e dê sua palavra final para o usuário."
    for _, l in ipairs(vim.split(append_text, "\n", {plain=true})) do
        table.insert(lines, l)
    end

    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    require('multi_context.ui.highlights').apply_chat(buf)
    p.create_folds(buf)

    if p.popup_win and api.nvim_win_is_valid(p.popup_win) then
        api.nvim_win_set_cursor(p.popup_win, {api.nvim_buf_line_count(buf), 0})
        vim.cmd("normal! zz")
    end

    vim.defer_fn(function() require('multi_context.core.event_bus').emit('USER_SUBMIT', { buf = buf }) end, 100)
end

M.ContextChatFull = commands.ContextChatFull
M.ContextChatSelection = commands.ContextChatSelection
M.ContextChatFolder = commands.ContextChatFolder
M.ContextChatHandler = commands.ContextChatHandler
M.ContextChatRepo = commands.ContextChatRepo
M.ContextChatGit = commands.ContextChatGit
M.ContextControls = commands.ContextControls
M.ContextApis = commands.ContextControls
M.ContextTree = commands.ContextTree
M.ContextBuffers = commands.ContextBuffers
M.TogglePopup = commands.TogglePopup

M.ContextUndo = function()
    local p = require('multi_context.ui.chat_view')
    local buf = p.popup_buf
    if not buf or not api.nvim_buf_is_valid(buf) then buf = api.nvim_get_current_buf() end
    if require('multi_context.core.state_manager').get('react').last_backup then
        api.nvim_buf_set_lines(buf, 0, -1, false, require('multi_context.core.state_manager').get('react').last_backup)
        require('multi_context.ui.highlights').apply_chat(buf)
        p.create_folds(buf)
        p.update_title()
        vim.notify(require("multi_context.i18n").t("chat_restored"), vim.log.levels.INFO)
    else
        vim.notify(require("multi_context.i18n").t("no_backup"), vim.log.levels.WARN)
    end
end

M.ToggleWorkspaceView = function()
    local ui_popup = require('multi_context.ui.chat_view')
    local is_popup = (ui_popup.popup_win and vim.api.nvim_win_is_valid(ui_popup.popup_win) and vim.api.nvim_get_current_win() == ui_popup.popup_win)
    if is_popup then
        vim.api.nvim_win_hide(ui_popup.popup_win)
        local new_filename, content = utils.build_workspace_content(ui_popup.popup_buf, M.current_workspace_file)
        M.current_workspace_file = utils.export_to_workspace(content, new_filename)
    else
        local cur_buf = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_get_name(cur_buf):match("%.mctx$") then
            M.current_workspace_file = vim.api.nvim_buf_get_name(cur_buf)
            utils.load_workspace_state(cur_buf)
            ui_popup.create_popup(cur_buf)
        else
            vim.notify(require("multi_context.i18n").t("not_workspace"), vim.log.levels.WARN)
        end
    end
end

local original_open_popup = popup.create_popup
popup.create_popup = function(initial_content)
    local b, w = original_open_popup(initial_content)
    M.popup_buf = popup.popup_buf
    M.popup_win = popup.popup_win
    return b, w
end

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        if require('multi_context.llm.transport')._temp_files then for _, f in ipairs(require('multi_context.llm.transport')._temp_files) do pcall(os.remove, f) end end
    end
})

vim.cmd([[
command! -range Context lua require('multi_context').ContextChatHandler(<line1>, <line2>)
command! -nargs=0 ContextUndo lua require('multi_context').ContextUndo()
command! -nargs=0 ContextFolder lua require('multi_context').ContextChatFolder()
command! -nargs=0 ContextRepo lua require('multi_context').ContextChatRepo()
command! -nargs=0 ContextGit lua require('multi_context').ContextChatGit()
command! -nargs=0 ContextControls lua require('multi_context').ContextControls()
command! -nargs=0 ContextApis lua require('multi_context').ContextControls()
command! -nargs=0 ContextTree lua require('multi_context').ContextTree()
command! -nargs=0 ContextBuffers lua require('multi_context').ContextBuffers()
command! -nargs=0 ContextToggle lua require('multi_context').TogglePopup()
command! -nargs=0 ContextReloadTools lua require('multi_context.ecosystem.tools_manager').load_tools(); vim.notify('Skills customizadas recarregadas!', vim.log.levels.INFO)
]])

return M
--------------------------------------
======================================================================
📝 DESCRIÇÃO E PROPÓSITO DE CADA ARQUIVO NESTA REFATORAÇÃO
======================================================================
▶ ETAPA 1 (Guardrails de Paralelismo Git)
  1. lua/multi_context/tools/docs/spawn_swarm.md
     ↳ Onde injetaremos a regra TERMINALLY FORBIDDEN contra branching paralelo.
  2. lua/multi_context/tests/prompt_hardening_spec.lua
     ↳ Onde escreveremos o teste TDD que verifica a restrição no manual.

▶ ETAPA 2 (UX do Carrossel de Abas)
  3. lua/multi_context/ui/chat_view.lua
     ↳ Foco na função 'update_title()' para enxugar o texto gerado na borda.
  4. lua/multi_context/tests/chat_view_spec.lua
     ↳ Teste TDD garantindo que apenas a Main e a aba corrente apareçam no título.

▶ ETAPA 3 (AST Serialization e Integração do Archivist)
  5. lua/multi_context/utils/utils.lua
     ↳ Foco em 'build_workspace_content' e 'load_workspace_state' para ler/gravar
       o JSON do Swarm dentro do novo <block type="swarm">.
  6. lua/multi_context/tests/utils_spec.lua
     ↳ Testes de serialização TDD para o novo formato XML do enxame.
  7. lua/multi_context/init.lua
     ↳ Onde a função 'OnSwarmComplete' mora. Aqui marcaremos status="completed"
       para que o Archivist possa recolher e comprimir a sessão concluída.
  8. lua/multi_context/core/swarm_manager.lua
     ↳ Pode ser necessário ajustar caso o estado precise sinalizar sua conclusão.
======================================================================
====================================== Início do plano de implementação (FASE 48) ======================================
 # 🗺️ PLANO DE ARQUITETURA: FASE 48
**Tema:** Otimização de Interface (UX), Integração de Swarm à AST e Guardrails de Paralelismo.

## ETAPA 1: Guardrail de Paralelismo Git (Anti-Branching)
**Objetivo:** Impedir que o `@tech_lead` alucine operações de mudança de branch concorrentes que destruam a *Working Tree* local.

### 📝 BDD (Behavior)
```gherkin
Feature: Prevenção de Conflitos Locais no Git (Swarm Guardrails)

  Scenario: Tech Lead é instruído a não usar branches no paralelismo
    Given o sistema inicializa os manuais de ferramentas (MCP)
    And o agente @tech_lead lê a documentação da ferramenta spawn_swarm
    Then o manual deve conter uma restrição explícita e terminantemente proibida ("TERMINALLY FORBIDDEN")
    And a restrição deve proibir a delegação de operações de mudança de branch (git checkout, git branch) para agentes rodando paralelamente.
    And deve instruir que integrações Git (DevOps) só podem ocorrer de forma sequencial (chain) no final da pipeline.
```

### 🧪 TDD (Execução)
1. **RED:** Abrir/Criar um teste em `git_tools_spec.lua` (ou `prompt_hardening_spec.lua`) que faça uma asserção verificando a existência da proibição de *parallel branching* no texto de `spawn_swarm.md`.
2. **GREEN:** Atualizar o arquivo `lua/multi_context/tools/docs/spawn_swarm.md` e, se necessário, a `system_prompt` da persona `@tech_lead` em `agents.lua`, injetando a regra para que o teste passe.
3. **REFACTOR:** N/A (Alteração documental).

---

## ETAPA 2: UX Minimalista — O Carrossel de Abas do Swarm
**Objetivo:** Enxugar o título do popup. Mostrar sempre a aba `Main` e APENAS a aba do *worker* do Swarm que está selecionada no momento.

### 📝 BDD (Behavior)
```gherkin
Feature: Interface Visual do Carrossel de Agentes (UX)

  Scenario: Título exibe apenas o buffer atual além do Main
    Given que um swarm foi iniciado com 3 agentes (coder, qa, devops)
    And o usuário está visualizando a aba principal (Main)
    When o título da janela for renderizado
    Then ele deve exibir apenas " Main | ~X tokens " (ou equivalente)

  Scenario: Título exibe apenas o agente selecionado
    Given que um swarm com 3 agentes está rodando
    When o usuário aperta <Tab> mudando o current_swarm_index para 2 (coder)
    Then o título da janela deve ocultar os agentes 1 e 3
    And deve exibir estritamente algo como " Main | [2:coder] | ~X tokens "
```

### 🧪 TDD (Execução)
1. **RED:** Modificar `chat_view_spec.lua` para criar 3 buffers de swarm. Forçar o `current_swarm_index = 2` e fazer uma asserção contra o título gerado pela função `update_title()`, garantindo que nomes dos outros buffers NÃO estejam na string.
2. **GREEN:** Reescrever a lógica do `update_title()` no `chat_view.lua`. Em vez do `for` loop que concatena todos os `sb.name`, injetar uma lógica if/else que fixa a string `Main` e apenas junta o `M.swarm_buffers[M.current_swarm_index]` (se `index > 1`).
3. **REFACTOR:** Garantir que o cálculo de tokens ainda funciona e não quebra se `auto_inject_context_md` estiver ligado.

---

## ETAPA 3: Integração do Swarm à AST Polimórfica (Cognitive RAG)
**Objetivo:** Abandonar o JSON isolado no final do arquivo (`<swarm_state>`). Converter o estado do Swarm em um `<block type="swarm">` padrão, imerso na linha do tempo do chat, suscetível à compressão do Archivist.

### 📝 BDD (Behavior)
```gherkin
Feature: Swarm AST Serialization e Arquivamento

  Scenario: Salvar Swarm State como Bloco Polimórfico
    Given um chat com um enxame em andamento
    When o usuário dispara o salvamento (ToggleWorkspaceView)
    Then o estado do swarm (JSON) deve ser salvo DENTRO do chat
    And deve ser envelopado pela tag <block type="swarm" status="running" id="...">
    And a tag global obsoleta <swarm_state> não deve mais ser gerada

  Scenario: Arquivista deve processar Enxames Concluídos
    Given o histórico de chat contém um bloco <block type="swarm" status="completed">
    When o motor do Archivist engatilhar a compressão
    Then o bloco do swarm concluído deve ser lido e sumarizado
    And o status do bloco do swarm deve mudar para "archived" (para ser ocultado da RAM principal)
```

### 🧪 TDD (Execução)
1. **RED (Serialization):** Modificar `utils_spec.lua` e `session_ast_spec.lua`. Escrever testes que passam uma tabela de `swarm_state` para o `build_workspace_content` e tentar ler a string resultante. O teste deve exigir que exista `<block id="..." type="swarm" status="running">` em vez de `<swarm_state>`.
2. **GREEN (Serialization):**
   - Alterar `utils.lua` (`build_workspace_content`): Modificar o *regex* que remove o `swarm_state` antigo. Transformar a string gerada em um formato `<block type="swarm" status="running">\n<content>\n{...json...}\n</content>\n</block>`. Ele será inserido após a última mensagem normal do chat.
   - Alterar `utils.lua` (`load_workspace_state`): Alterar o *regex* de captura para procurar `type="swarm"` e extrair o JSON de dentro de `<content>`.
3. **RED (Archivist):** Criar teste em `archiver_spec.lua` verificando se a função `compress()` consegue marcar um bloco `type="swarm"` como `archived`.
4. **GREEN (Archivist):** Ajustar o `Swarm Manager` para que, ao finalizar todas as tarefas da fila e imprimir o Relatório Final (`OnSwarmComplete`), ele atualize a propriedade `status` do bloco Swarm na AST para `"completed"`. Assim, o Arquivista (e o Dynamic Watchdog) passará a "ver" esse bloco como material sumarizável, hiper-comprimindo o JSON para recuperar tokens.

---

### Resumo do Impacto da Fase 48
Com este plano executado:
1. **Segurança:** O Git local não será mais corrompido por operações paralelas.
2. **UX:** O título flutuante do Neovim fica limpo, mostrando apenas o que importa.
3. **Performance/Memória:** O JSON monstruoso das *Swarm Sessions* deixa de ser um "peso morto" e entra na jurisdição do Guardião Preditivo, permitindo que sessões de enxame passadas sejam comprimidas no `CONTEXT.md` ou arquivadas localmente, liberando a janela de memória para novos trabalhos!

---

**Reforçando Nossa Doutrina de Trabalho:**
- **Strict TDD (Red, Green, Refactor):** Você **NÃO** deve escrever o código de produção longo e completo logo de cara. Você me entregará pequenos scripts bash (ex: `create_tests.sh` e `refactorate.sh`) para eu colar e rodar no meu Neovim.
- Faremos Inside-Out. A **Fase 48.1 e 48.2** serão o nosso foco inicial.
- Mantenha o código limpo (SOLID, DRY, KISS) e seguro contra `nil` values.

Antes de escrever código, analise profundamente este plano de implementação quanto à sua adequação em atender o objetivo. Confirme que entendeu a arquitetura proposta, que tem o conhecimento de todos os arquivos necessários e só então escreva o primeiro script.

====================================== Fim do plano de implementação (FASE 48) ======================================
