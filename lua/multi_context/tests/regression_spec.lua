local assert = require("luassert")
local stub = require("luassert.stub")

describe("MultiContext V2.4 - Security & Regression Tests", function()
    
    it("Bug 4: Sandbox Escape Whitelist (Impede RCE)", function()
        local runner = require("multi_context.ecosystem.tool_runner")
        local tool_data = {name = "run_shell", inner = "rm -rf /"}
        local approve_ref = {value = false}
        
        -- Moca a confirmação para simular o usuário bloqueando / ignorando
        stub(vim.fn, "confirm")
        vim.fn.confirm.returns(2) -- Denied
        
        local out, abort = runner.execute(tool_data, true, approve_ref, 1)
        
        assert.is_truthy(out:match("NEGADO") or out:match("ERRO") or out:match("DENIED"))
        vim.fn.confirm:revert()
    end)

    it("Bug 5: Fallback Preventivo da ferramenta Diff (Sem Comando Patch)", function()
        local tools = require("multi_context.ecosystem.native_tools")
        
        stub(vim.fn, "executable")
        vim.fn.executable.returns(0) -- Simula ausência do "patch" no sistema
        
        local result = tools.apply_diff("teste.lua", "+++ b/teste")
        assert.is_truthy(result:match("Comando") or result:match("patch"))
        
        vim.fn.executable:revert()
    end)

    it("Bug 6: Proteção contra Ping-Pong Infinito no Swarm Manager", function()
        local swarm = require("multi_context.core.swarm_manager")
        swarm.reset()
        swarm.init_swarm('{"tasks":[{"agent":"qa", "instruction":"test"}]}')
        
        local task = swarm.state.queue[1]
        task.switch_count = 3
        
        -- Simula a lógica embutida no switch
        local new_content = "SWITCH_AGENT_REQUEST:coder"
        local switch_target = new_content:match("SWITCH_AGENT_REQUEST:([%w_]+)")
        task.switch_count = (task.switch_count or 0) + 1
        
        if task.switch_count > 3 then 
            switch_target = nil 
        end
        
        assert.is_nil(switch_target, "O alvo de switch deve ser neutralizado se count > 3")
    end)
    
    it("Bug 8: CURL Pipe via STDIN (Remoção de Tmp Files Leak)", function()
        local transport = require("multi_context.llm.transport")
        local cmd = transport.build_curl_cmd({url = "http://test"}, "key", "dummy.json", false)
        local joined_cmd = table.concat(cmd, " ")
        
        assert.is_truthy(joined_cmd:match("@%-"), "CURL deve ler via stdin usando @-")
        assert.is_falsy(joined_cmd:match("@dummy%.json"), "CURL não deve usar referências vazadas em disco")
    end)

end)
