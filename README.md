![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=for-the-badge&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-100%25-blue.svg?style=for-the-badge&logo=lua)
![Release](https://img.shields.io/badge/Version-v1.3--Final-blue.svg?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 📖 Overview

**MultiContext AI** is a native, asynchronous, and high-performance Neovim plugin that integrates **autonomous** Artificial Intelligence assistants directly into the editor (inspired by the *Claude Code* and *Devin* paradigms).

Unlike conventional autocomplete plugins, MultiContext acts as a cutting-edge software engineer: it navigates your system using **LSP and Ripgrep**, edits files surgically via Unified Diff, runs terminal tests, concludes its work by performing pure Semantic Commits using the **@devops** persona, and processes complex architectural rules in its native training language (**English**) while outputting answers in your preferred UI language.

All of this is supported by an asynchronous multithreaded **Swarm Architecture** and governed by a virtual **Master Command Center** inside your Neovim.

---

## 🚀 The Power of the Autonomous Engineer

| Icon | Feature | Description |
|:---:|---|---|
| 🎛️ | **Command Center (Virtual UI)** | Centralized panel (`:ContextControls`) with a *Dynamic Footer*. Manage APIs, Telemetry, Watchdog limits, create Injectors, or handle IAM permissions right from your keyboard. |
| 🌍 | **Native Cognition & i18n** | Heavy orchestration rules run in **English** in the Backend (yielding zero LLM logic hallucinations) while the UI and Chat output adapt to your preferred language (e.g., pt-BR or en). |
| 🧩 | **Context Injectors (`\`)** | Compose prompts in a live fuzzy menu. Inject the File Tree, global LSP Errors, or Git Logs directly below your cursor without ruining your text. |
| 🐝 | **Swarm Architecture** | The `@tech_lead` invokes specialized teams (@coder, @qa, @devops) operating in a parallel asynchronous carousel, navigable via `<Tab>`. Includes **On-the-fly Choreography** using `--queue` (Sequential) and `--moa` (Semantic Parallel) flags directly in the chat. |
| 🛡️ | **Context Watchdog 2.0** | A predictive tracker (EMA) monitors tokens. If the limit is breached, the `@archivist` performs an aggressive Quadripartite Compression via XML. |
| 🔍 | **LSP & Ripgrep Navigation** | We abandoned noisy RAG. The AI tracks down code with ultra-fast `rg` and jumps into functions via **Go To Definition** using Neovim's own LSP for maximum token efficiency. |
| 👨‍💻 | **Git Automation (@devops)** | At the end of a task, the AI creates branches and surgically commits specific files through a strict Security Gatekeeper (blocking remote pushes). |
| 🧠 | **Cognitive Hardening** | Implements Recency Bias Guardrails and Zero-Skill Awareness to prevent tool hallucinations and strictly enforce XML outputs without markdown wrappers. |
| ⚡ | **V2.0 Event-Driven Core** | Pure Lua PubSub Architecture (EventBus) with Centralized State Management and Session AST, making the UI 100% reactive and decoupled. |
| 🔌 | **Polyglot Extensibility** | Teach custom skills (e.g., Pytest, Jira, Databases) by writing scripts in Bash, Python, or Go, and native `env` bridging will couple them to the AI. |

---

## 💡 Usage Examples

MultiContext AI allows you to compose powerful directives natively. Here are a few ways to drive the AI:

### 1. Basic Single Agent Execution
Ask an agent to do something. The system pauses at a `> [Checkpoint]` afterward to await your feedback.
```text
## User >>
@coder --auto Please refactor the authentication module to use JWT.
```
*(Note: The `--auto` flag grants the agent permission to use tools like `edit_file` without prompting you for `<Y/N>` confirmations).*

### 2. Assembly Line (Sequential Queue)
Use the `--queue` flag to chain multiple agents. The system will pass the baton automatically when the previous agent finishes, creating a hands-free workflow.
```text
## User >>
@coder --auto Implement the new login route.
Then, @qa --auto write integration tests for it.
Finally, @devops create a commit saving the progress. --queue
```

### 3. Semantic Swarm (Mixture of Agents)
Use the `--moa` flag to delegate complex coordination to the `@tech_lead`. It will analyze your semantic request, extract the mentioned agents, and spawn asynchronous sub-buffers natively.
```text
## User >>
@architect analyze this project and create a plan to improve its modularity following TDD.
@tech_lead subdivide the architect's plan into small jobs and distribute them across multiple developer and qa agents.
@devops commit the progress up to here. --moa
```

### 4. Context Injectors (Fuzzy Data)
Press `\` in Insert Mode to open the Injectors Menu. You can seamlessly paste LSP errors, Git Logs, or active buffers directly into your prompt without leaving the chat:
```text
## User >>
@coder Fix the following errors in my project:
=== LINTING ERRORS (LSP) ===
src/main.lua:42:10 [ERROR] undefined variable 'x'
```

### 5. Managing Permissions and Fallbacks
At any time during your work, type `:ContextControls` to pop up the Master Command Center. From there, you can:
- Change the `Watchdog` tolerance if the context gets too big.
- Edit your API Fallback list (if Claude fails, OpenAI assumes control).
- Toggle specific skills on/off for your agents (e.g., forbid `@coder` from using `run_shell`).

---

## 📦 Installation and Bootstrapping (Lazy.nvim)

MultiContext features an **Auto-Setup**. Upon running it for the first time, it will autonomously create all base configuration files isolated in `~/.config/nvim/`.

```lua
{
    "your-username/multi_context_plugin",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        user_name = "Your Name",
        language  = "en", -- Supports "en" or "pt-BR"
    },
    keys = {
        { "<leader>mc", "<cmd>ContextToggle<cr>", desc = "Toggle MultiContext Chat" },
        { "<leader>mp", "<cmd>ContextControls<cr>", desc = "Master Command Center" },
    }
}
```

> **Tip**: Right after installation, run `:help multicontext` to open the rich native Neovim manual.

---

## 🧪 Automated Testing and Reliability (TDD)

The engine of this plugin was strictly developed under TDD and is maintained with military-grade resilience (**149 isolated tests passing at 100%**).
```bash
make test_agregate_results
```

```text
======================================================================
🧪 Executing Full Suite (Plenary Isolation)...
======================================================================
...
======================================================================
📊 AGGREGATED GLOBAL SUMMARY (MULTI-CONTEXT)
======================================================================
✅ Success: 149
❌ Failed : 0
💥 Errors : 0
======================================================================
