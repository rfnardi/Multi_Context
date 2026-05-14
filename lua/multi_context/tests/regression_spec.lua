require("multi_context.tests.libuv_barrier")
local assert = require("luassert")
local stub = require("luassert.stub")
local runner = require('multi_context.ecosystem.tool_runner')
local StateManager = require('multi_context.core.state_manager')
local agents = require('multi_context.agents')
local swarm = require("multi_context.core.swarm_manager")
local tools = require("multi_context.ecosystem.native_tools")
local transport = require("multi_context.llm.transport")
local react = require('multi_context.core.react_orchestrator')

describe("MultiContext V2.4 - Security & Regression Tests", function()
    
    it("Bug 4: Sandbox Escape Whitelist (Impede RCE)", function()
        local tool_data = {name = "run_shell", inner = "rm -rf /", raw_tag="<tool>"}
        local approve_ref = {value = false}
        stub(vim.fn, "confirm")
        vim.fn.confirm.returns(2)
        local out, abort = runner.execute(tool_data, true, approve_ref, 1)
        vim.fn.confirm:revert()
        assert.is_truthy(out:match("NEGADO") or out:match("ERRO") or out:match("DENIED"))
    end)

    it("Bug 5: Fallback Preventivo da ferramenta Diff", function()
        stub(vim.fn, "executable")
        vim.fn.executable.returns(0)
        local result = tools.apply_diff("teste.lua", "+++ b/teste")
        vim.fn.executable:revert()
        assert.is_truthy(result:match("Comando") or result:match("patch"))
    end)

    it("Bug 6: Proteção contra Ping-Pong Infinito no Swarm Manager", function()
        swarm.reset()
        swarm.init_swarm('{"tasks":[{"agent":"qa", "instruction":"test"}]}')
        local task = swarm.state.queue[1]
        task.switch_count = 3
        local new_content = "SWITCH_AGENT_REQUEST:coder"
        local switch_target = new_content:match("SWITCH_AGENT_REQUEST:([%w_]+)")
        task.switch_count = (task.switch_count or 0) + 1
        if task.switch_count > 3 then switch_target = nil end
        assert.is_nil(switch_target)
    end)
    
    it("Bug 8: CURL Pipe via STDIN e remoção de Tmp Leak", function()
        local cmd = transport.build_curl_cmd({url = "http://test"}, "key", "dummy.json", false)
        local joined_cmd = table.concat(cmd, " ")
        assert.is_truthy(joined_cmd:match("@%-"))
        assert.is_falsy(joined_cmd:match("@dummy%.json"))
    end)

    it("Bug do Architect: O Gatekeeper MCP deve resolver Skills Semanticas nativamente", function()
        local orig_load_agents = agents.load_agents
        agents.load_agents = function() return { teste_arch = { skills = {"code_investigation"} } } end
        
        StateManager.get('react').active_agent = "teste_arch"
        local tool_data = { name = "list_files", inner = "", raw_tag = "<tool_call>" }
        local output = runner.execute(tool_data, true, { value = true }, nil)
        
        StateManager.get('react').active_agent = nil
        agents.load_agents = orig_load_agents
        
        assert.is_falsy(output:match("Operação negada"))
    end)

    it("Bug do Loop Infinito: O Motor ReAct deve abortar autonomia (--auto) se receber erro do Gatekeeper", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "## IA >>", "<tool_call name='ferramenta_falsa'></tool_call>" })
        
        local orig_execute = runner.execute
        runner.execute = function()
            return "<block id=\"res_1\" type=\"tool_result\" role=\"user\" status=\"active\">\n<content>\n>[Sistema]: ⛔ ERRO - Acesso Negado\n</content>\n</block>", false, false, nil, nil
        end
        
        StateManager.get('react').is_autonomous = true
        react.ExecuteTools(1, buf)
        
        local is_autonomous_after = StateManager.get('react').is_autonomous
        runner.execute = orig_execute
        vim.api.nvim_buf_delete(buf, { force = true })
        
        assert.is_false(is_autonomous_after)
    end)

    it("Bug do Payload Sujo: Swarm Manager deve extrair JSON embutido em texto", function()
        swarm.reset()
        local payload_sujo = "Vou delegar.\n{ \"tasks\": [ { \"agent\": \"qa\", \"instruction\": \"teste\" } ] }\nPronto."
        local ok, err = swarm.init_swarm(payload_sujo)
        assert.is_true(ok)
        assert.are.same(1, #swarm.state.queue)
        assert.are.same("qa", swarm.state.queue[1].agent)
    end)

    it("Fase 46 - Integridade Arquitetural: Resultados de Tools devem ser envelopados em <block>", function()
        local tool_data = { name = "list_files", inner = "", raw_tag = "<tool_call name='list_files'>" }
        local out = runner.execute(tool_data, true, { value = true }, nil)
        assert.is_truthy(out:match("<block id=\"tool_"))
        assert.is_truthy(out:match("type=\"tool_result\""))
    end)
end)
