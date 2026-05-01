local tools = require('multi_context.ecosystem.native_tools')

describe("Fase 31 - Passo 1: Automação Git (Agente DevOps)", function()
    local orig_system
    local executed_cmds = {}

    before_each(function()
        executed_cmds = {}
        orig_system = vim.fn.system
        vim.fn.system("true")
        
        vim.fn.system = function(cmd)
            table.insert(executed_cmds, cmd)
            if type(cmd) == "string" and cmd:match("git rev%-parse") then
                return "/mock/repo/root\n"
            end
            if type(cmd) == "string" and cmd:match("git.*add") then
                return ""
            end
            if type(cmd) == "string" and cmd:match("git.*checkout") then
                return "Switched to branch\n"
            end
            if type(cmd) == "string" and cmd:match("git.*commit") then
                return "[feature/xyz 12345] Commit realizado\n"
            end
            if type(cmd) == "string" and cmd:match("git.*status") then
                return " M arquivo1.lua\n?? arquivo2.lua\n"
            end
            return orig_system(cmd)
        end
    end)

    after_each(function()
        vim.fn.system = orig_system
    end)

    it("Deve retornar o git status formatado (git_status)", function()
        local res = tools.git_status()
        assert.truthy(res:match("arquivo1%.lua"), "Deve conter o status dos arquivos")
        local cmd_found = false
        for _, c in ipairs(executed_cmds) do if c:match("git.*status") then cmd_found = true end end
        assert.is_true(cmd_found, "Deve invocar o git status no repositório")
    end)

    it("Deve realizar checkout e criar nova branch se requisitado (git_branch)", function()
        local res = tools.git_branch("feature/nova-tela", true)
        assert.truthy(res:match("SUCESSO") or res:match("SUCCESS"), "Deve reportar sucesso")
        local cmd_found = false
        for _, c in ipairs(executed_cmds) do if c:match("git.*checkout %-b.*feature/nova%-tela") then cmd_found = true end end
        assert.is_true(cmd_found, "Deve invocar git checkout -b")
    end)

    it("Deve proibir explicitamente git add em massa como '.' ou '*' (git_commit)", function()
        local res_dot = tools.git_commit(".", "Mensagem")
        assert.truthy(res_dot:match("ERRO") or res_dot:match("ERROR"), "Deve proibir o uso de '.'")

        local res_star = tools.git_commit("src/*", "Mensagem")
        assert.truthy(res_star:match("ERRO") or res_star:match("ERROR"), "Deve proibir o uso de '*'")
    end)

    it("Deve fazer add e commit apenas dos arquivos especificos (git_commit)", function()
        local res = tools.git_commit("file1.lua, src/file2.lua", "feat: atualiza arquivos")
        
        local add_cmd_found = false
        local commit_cmd_found = false
        
        for _, cmd in ipairs(executed_cmds) do
            if cmd:match("git.*add.*file1%.lua.*src/file2%.lua") then add_cmd_found = true end
            if cmd:match("git.*commit.*%-m.*feat: atualiza arquivos") then commit_cmd_found = true end
        end
        
        assert.is_true(add_cmd_found, "O comando 'git add' deve ser restrito aos arquivos passados")
        assert.is_true(commit_cmd_found, "O comando 'git commit' deve ser efetuado com a mensagem passada")
        assert.truthy(res:match("SUCESSO") or res:match("SUCCESS"), "Deve reportar sucesso final")
    end)
end)

describe("Fase 31 - Passo 2: O Agente DevOps, Gatekeeper e Swarm XML", function()
    local agents = require('multi_context.agents')
    local tool_runner = require('multi_context.ecosystem.tool_runner')
    local swarm = require('multi_context.core.swarm_manager')
    local api_client = require('multi_context.llm.api_client')

    it("Deve existir a persona @devops com ferramentas Git", function()
        local loaded = agents.load_agents()
        assert.is_not_nil(loaded["devops"])
        
        local has_commit = false
        for _, skill in ipairs(loaded["devops"].skills) do
            if skill == "git_commit" then has_commit = true end
        end
        assert.is_true(has_commit, "O devops deve ter a skill git_commit habilitada")
    end)
    
    it("O Gatekeeper deve interceptar comandos git destrutivos (push, reset, rebase)", function()
        local orig_confirm = vim.fn.confirm
        vim.fn.confirm = function() return 2 end
        
        local tool_data = {
            name = "run_shell",
            inner = "git push origin main --force",
            raw_tag = "<tool_call name='run_shell'>"
        }
        local approve_ref = { value = false }
        local out = tool_runner.execute(tool_data, true, approve_ref, nil)
        
        assert.truthy(out:match("NEGADO") or out:match("DENIED"), "Deve bloquear um git push autônomo sem confirmacao humana")
        
        vim.fn.confirm = orig_confirm
    end)

    it("O swarm_manager deve exigir detalhamento estruturado das operações Git no <final_report>", function()
        swarm.init_swarm('{"tasks":[{"agent":"coder","instruction":"teste"}]}')
        swarm.state.workers = { { api = { name = "mock", abstraction_level = "high" }, busy = false } }
        
        local captured_sys_prompt = ""
        local orig_exec = api_client.execute
        
        api_client.execute = function(msgs, on_start, on_chunk, on_done)
            captured_sys_prompt = msgs[1].content
            if on_done then on_done({name="mock"}, nil) end
        end
        
        swarm.dispatch_next()
        
        assert.truthy(captured_sys_prompt:match("<final_report>"), "Deve cobrar a tag de limite <final_report>")
        assert.truthy(captured_sys_prompt:match("Git operations"), "Deve exigir explicitamente que a IA liste as operações Git")
        
        api_client.execute = orig_exec
    end)
end)
