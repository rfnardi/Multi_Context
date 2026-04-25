local controls = require('multi_context.context_controls')
local config = require('multi_context.config')
local api = vim.api

describe("Fase 26 - Passo 1: Expansão do Motor Virtual e IAM", function()
    before_each(function()
        package.loaded['multi_context.context_controls'] = nil
        controls = require('multi_context.context_controls')
        controls.reset_state()
        
        -- Mock for APIs and Agents
        config.load_api_config = function()
            return { fallback_mode = true, default_api = "api_A", apis = { { name = "api_A" } } }
        end
        package.loaded['multi_context.agents'] = {
            load_agents = function() return { tech_lead = { skills = {"run_shell"} } } end
        }
        package.loaded['multi_context.skills_manager'] = {
            load_skills = function() end,
            get_skills = function() return { minha_skill = {} } end
        }
    end)

    it("Deve inicializar as novas sessoes e carregar agentes e skills na memoria", function()
        controls.init_state()
        assert.are.same(6, #controls.state.sections, "Devem existir 6 sessoes no painel agora")
        assert.is_not_nil(controls.state.agents["tech_lead"], "Os agentes devem ser carregados no estado")
        assert.is_not_nil(controls.state.all_skills["minha_skill"], "Skills customizadas devem aparecer")
        assert.is_not_nil(controls.state.all_skills["apply_diff"], "Skills nativas injetadas devem aparecer")
    end)

    it("Deve renderizar os botoes de criar Agente e Skill ao expandir as seções", function()
        controls.init_state()
        
        controls.toggle_section(5) -- Gatekeeper
        controls.toggle_section(6) -- Skills
        
        local lines = controls.render()
        local found_new_agent = false
        local found_new_skill = false
        local found_tech_lead = false
        
        for _, line in ipairs(lines) do
            if line:match("%+ Criar Novo Agente") then found_new_agent = true end
            if line:match("%+ Criar Nova Skill") then found_new_skill = true end
            if line:match("▶ tech_lead") then found_tech_lead = true end
        end
        
        assert.is_true(found_new_agent, "O botão virtual de novo agente deve ser renderizado")
        assert.is_true(found_new_skill, "O botão virtual de nova skill deve ser renderizado")
        assert.is_true(found_tech_lead, "O agente existente deve aparecer listado")
    end)
    
    it("Deve permitir Drill-down (Expandir um Agente) revelando a arvore de skills", function()
        controls.init_state()
        controls.toggle_section(5)
        
        -- Simulando que o usuario apertou <CR> em cima do tech_lead
        controls.state.expanded_agents["tech_lead"] = true
        
        local lines = controls.render()
        local found_run_shell = false
        
        for _, line in ipairs(lines) do
            if line:match("├─ run_shell") and line:match("●") then found_run_shell = true end
        end
        
        assert.is_true(found_run_shell, "Ao expandir, deve listar as skills e marcar com um dot as que o agente possui")
    end)
end)
