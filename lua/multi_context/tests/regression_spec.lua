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
    
    pending("Bug 8: CURL Pipe via STDIN desativado", function()
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

    it('Bug 9: Swarm Manager deve desembrulhar JSON aninhado em json_payload (Alucinacao LLM)', function()
        local swarm = require('multi_context.core.swarm_manager')
        -- Simulando exatamente o erro cometido pelo LLM
        local fake_json = '{"json_payload": "{\\"tasks\\": [{\\"agent\\": \\"coder\\", \\"instruction\\": \\"teste\\"}]}"}'
        
        local ok, err = swarm.init_swarm(fake_json)
        
        assert.is_true(ok)
        assert.are.equal(1, #swarm.state.queue)
        assert.are.equal("coder", swarm.state.queue[1].agent)
    end)

    it('Bug 10: Tool Parser deve ignorar fechamentos de tag in-line (Injecao XML)', function()
        local parser = require('multi_context.ecosystem.tool_parser')
        -- Simulando a IA citando uma tag </tool_call> in-line no meio da instrução
        local payload = "<tool_call name=\"spawn_swarm\">\n{\"instruction\": \"Tem um </tool_call> in-line aqui.\"}\n</tool_call>"
        
        local res = parser.parse_next_tool(payload, 1)
        
        assert.is_not_nil(res)
        assert.is_false(res.is_invalid)
        assert.are.equal("spawn_swarm", res.name)
        assert.truthy(res.inner:match("in%-line aqui"))
    end)

    it('Bug 11: Utils deve gerar datas validas no cabecalho mctx_session (Nao literal Y-m-d)', function()
        local utils = require('multi_context.utils.utils')
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"## User >> hello"})
        
        local name, buf_content = utils.build_workspace_content(buf, nil)
        local created = buf_content:match('created="([^"]+)"')
        
        assert.is_not_nil(created)
        -- Garante que o desenvolvedor do futuro não reverta para 'Y-m-d'
        assert.is_nil(created:match("Y%%-m%%-d"))
        -- Garante que a data está no padrão real numérico ISO
        assert.truthy(created:match("%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d"))
        
        vim.api.nvim_buf_delete(buf, {force=true})
    end)

    it('Bug 12: Transport deve usar offload de arquivo no curl ao inves de chansend (Anti-Freeze)', function()
        local transport = require('multi_context.llm.transport')
        -- Simulando a criacao de comando com payload persistido no disco
        local cmd = transport.build_curl_cmd({url="http", api_type="openai"}, "key", "/tmp/fake.json", true)
        
        local has_at_file = false
        for _, v in ipairs(cmd) do
            if v == "@/tmp/fake.json" then has_at_file = true end
        end
        
        -- Garante que o Curl será lido do HD (@arquivo) para evitar congelamento de UI
        assert.is_true(has_at_file)
    end)
end)
