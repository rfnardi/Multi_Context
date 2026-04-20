local tool_parser = require('multi_context.tool_parser')
local config = require('multi_context.config')
local agents = require('multi_context.agents')

describe("Swarm Etapa 1 - Modelagem e Parser:", function()

    it("Deve extrair e decodificar corretamente o JSON rigoroso da tool spawn_swarm", function()
        local ticks = string.rep("`", 3)
        local payload = "Algum texto antes\n" ..
            "<tool_call name=\"spawn_swarm\">\n" ..
            ticks .. "json\n" ..
            [[
            {
              "tasks":[
                {
                  "agent": "coder",
                  "context":["src/login.lua"],
                  "instruction": "Implemente a rota"
                }
              ]
            }
            ]] .. "\n" .. ticks .. "\n" ..
            "</tool_call>\n" ..
            "Algum texto depois"

        local parsed = tool_parser.parse_next_tool(payload, 1)
        assert.is_not_nil(parsed)
        assert.are.same("spawn_swarm", parsed.name)
        
        local ok, decoded = pcall(vim.fn.json_decode, vim.trim(parsed.inner))
        assert.is_true(ok)
        assert.are.same("coder", decoded.tasks[1].agent)
    end)

    it("Deve identificar e retornar corretamente APIs disponíveis como workers", function()
        local mock_cfg = { 
            default_api = "api_principal", 
            apis = { 
                { name = "api_principal", url = "http..." },
                { name = "worker_1", url = "http...", allow_spawn = true },
                { name = "worker_2", url = "http...", allow_spawn = true }
            } 
        }
        
        local tmp_json = os.tmpname()
        local f = io.open(tmp_json, "w")
        f:write(vim.fn.json_encode(mock_cfg))
        f:close()

        config.options.config_path = tmp_json
        
        local spawn_workers = config.get_spawn_apis()
        assert.is_not_nil(spawn_workers)
        assert.are.same(2, #spawn_workers)
        assert.are.same("worker_1", spawn_workers[1].name)
        assert.are.same("worker_2", spawn_workers[2].name)
        
        os.remove(tmp_json)
    end)

    it("Deve garantir que a persona @tech_lead exista com a skill correta", function()
        local loaded_agents = agents.load_agents()
        assert.is_not_nil(loaded_agents["tech_lead"])
        
        local has_spawn_skill = false
        if loaded_agents["tech_lead"] and loaded_agents["tech_lead"].skills then
            for _, skill in ipairs(loaded_agents["tech_lead"].skills) do
                if skill == "spawn_swarm" then has_spawn_skill = true end
            end
        end
        assert.is_true(has_spawn_skill)
    end)
end)
