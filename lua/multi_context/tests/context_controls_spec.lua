local controls = require('multi_context.context_controls')
local config = require('multi_context.config')
local api = vim.api

describe("Fase 26 - Passo 1: Expansão do Motor Virtual e IAM", function()
    before_each(function()
        package.loaded['multi_context.context_controls'] = nil
        controls = require('multi_context.context_controls')
        package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); controls.reset_state()
        
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
        assert.truthy(#controls.state.sections >= 6, "Devem existir pelo menos 6 sessoes no painel agora")
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
            if line:match("%[%+%] tech_lead") then found_tech_lead = true end
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
            if line:match("├─ run_shell") and line:match("%[ ✓ %]") then found_run_shell = true end
        end
        
        assert.is_true(found_run_shell, "Ao expandir, deve listar as skills e marcar com um dot as que o agente possui")
    end)
end)

describe("Fase 26.1 - Interatividade e Mutação (Toggles e Edição)", function()
    local controls = require('multi_context.context_controls')

    before_each(function()
        package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); controls.reset_state()
        controls.init_state()
        
        -- Estado base simulado para o teste
        controls.state.agents = {
            coder = { skills = {"read_file"}, abstraction_level = "high" }
        }
        controls.state.all_skills = {
            read_file = { name = "read_file", is_native = true },
            run_shell = { name = "run_shell", is_native = true }
        }
    end)

    it("Deve ligar e desligar uma skill do agente ao usar o espaco (handle_space)", function()
        -- Simulando a renderizacao virtual em duas linhas do painel
        controls.line_map = {
            [1] = { type = "agent_skill_toggle", agent = "coder", skill = "run_shell" },
            [2] = { type = "agent_skill_toggle", agent = "coder", skill = "read_file" }
        }
        
        local orig_cursor = vim.api.nvim_win_get_cursor
        
        -- Mock: Usuário está na linha 1
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        controls.handle_space() -- Pressionou espaço!
        
        local has_run_shell = false
        for _, s in ipairs(controls.state.agents["coder"].skills) do
            if s == "run_shell" then has_run_shell = true end
        end
        assert.is_true(has_run_shell, "A skill run_shell deve ter sido adicionada a matriz de permissoes")
        
        -- Mock: Usuário está na linha 2 (A skill read_file ja existe pro coder)
        vim.api.nvim_win_get_cursor = function() return {2, 0} end
        controls.handle_space() -- Pressionou espaço!
        
        local has_read_file = false
        for _, s in ipairs(controls.state.agents["coder"].skills) do
            if s == "read_file" then has_read_file = true end
        end
        assert.is_false(has_read_file, "A skill read_file deve ter sido removida da matriz de permissoes")
        
        -- Cleanup
        vim.api.nvim_win_get_cursor = orig_cursor
    end)
    
    it("Deve alterar a Identidade e Limites com a tecla c (handle_edit)", function()
        controls.line_map = {[1] = { type = "limit_identity" },
            [2] = { type = "limit_loops" }
        }
        
        local orig_cursor = vim.api.nvim_win_get_cursor
        local orig_input = vim.ui.input
        
        -- Simulando o usuário editando a Identidade
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        vim.ui.input = function(opts, cb) cb("DevMaster") end
        
        controls.handle_edit()
        assert.are.same("DevMaster", controls.state.identity)
        
        -- Simulando o usuário editando o limite de loops ReAct
        vim.api.nvim_win_get_cursor = function() return {2, 0} end
        vim.ui.input = function(opts, cb) cb("42") end
        
        controls.handle_edit()
        assert.are.same(42, controls.state.max_loops)
        
        -- Cleanup
        vim.api.nvim_win_get_cursor = orig_cursor
        vim.ui.input = orig_input
    end)
end)

describe("Fase 26.2 - Modo de Criacao e Atalhos", function()
    local controls = require('multi_context.context_controls')

    before_each(function()
        package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); controls.reset_state()
        controls.init_state()
    end)

    it("Deve criar um novo agente via handle_cr no painel", function()
        controls.line_map = {
            [1] = { type = "create_agent" }
        }
        
        local orig_cursor = vim.api.nvim_win_get_cursor
        local orig_input = vim.ui.input
        local orig_save = controls.save_config
        
        -- Mocks
        vim.api.nvim_win_get_cursor = function() return {1, 0} end
        vim.ui.input = function(opts, cb) cb("arquiteto_teste") end
        controls.save_config = function() end -- Nao sobrescreve o json real durante o teste
        
        controls.handle_cr() -- Pressionou enter sobre a opcao [+ Criar Novo Agente]
        
        assert.is_not_nil(controls.state.agents["arquiteto_teste"], "A nova persona deve ser adicionada no estado em memoria")
        assert.are.same("high", controls.state.agents["arquiteto_teste"].abstraction_level, "O default deve ser high")
        
        -- Cleanup
        vim.api.nvim_win_get_cursor = orig_cursor
        vim.ui.input = orig_input
        controls.save_config = orig_save
    end)
end)

describe("Fase A - Refatoracao Visual UX e Footer", function()
    local controls = require('multi_context.context_controls')

    before_each(function()
        package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); controls.reset_state()
        controls.init_state()
        
        -- Adicionamos uma propriedade de descrição nas seções simuladas
        controls.state.sections[1].desc = "(Gerencie chaves, modelos de IA e fallback)"
        controls.state.sections[1].expanded = false -- Seção 1 fechada
        controls.state.sections[2].expanded = true  -- Seção 2 aberta
        
        controls.state.fallback_mode = true
    end)

    it("Deve renderizar [+] e a descricao para secoes ocultas, e [-] sem descricao para abertas", function()
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        -- Seção fechada
        assert.truthy(str_lines:match("%[%+%] %[1%] PROVEDORES"), "Deve ter [+] na secao fechada")
        assert.truthy(str_lines:match("%(Gerencie chaves"), "Deve exibir a descricao quando a secao esta fechada")
        
        -- Seção aberta
        assert.truthy(str_lines:match("%[%-%] %[2%] ORQUESTRAÇÃO"), "Deve ter [-] na secao aberta")
    end)

    it("Deve utilizar os novos checkmarks [ ON ] e [ ✓ ]", function()
        controls.state.sections[1].expanded = true
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        assert.truthy(str_lines:match("%[%s*ON%s*%]"), "O toggle de fallback deve usar [ ON ]")
        assert.truthy(str_lines:match("%[%s*✓%s*%]"), "A seleção de API atual deve usar checkmark ao invés de bolinha")
    end)
    
    it("Deve gerar a dica de rodape correta com base na acao (Footer Dinâmico)", function()
        local hint_edit = controls.get_footer_hint({ type = "edit_skill" })
        assert.truthy(hint_edit:match("e"), "Dica de edicao deve mencionar a tecla 'e'")
        
        local hint_toggle = controls.get_footer_hint({ type = "toggle_fallback" })
        assert.truthy(hint_toggle:match("<Space>"), "Dica de toggle deve mencionar '<Space>'")
        
        local hint_input = controls.get_footer_hint({ type = "wd_horizon" })
        assert.truthy(hint_input:match("c"), "Dica de edicao numerica/texto deve mencionar 'c'")
    end)
end)

describe("Fase B - Injetores e Macros no Painel", function()
    local controls = require('multi_context.context_controls')

    before_each(function()
        package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); controls.reset_state()
        
        -- Mocking injectors
        local orig_req = require
        _G.require = function(mod)
            if mod == 'multi_context.injectors' then
                return {
                    get_all_injectors = function()
                        return {
                            buffers = { name = "buffers" },
                            meu_injetor = { name = "meu_injetor" }
                        }
                    end,
                    get_native_injectors = function()
                        return {
                            { name = "buffers" }
                        }
                    end
                }
            end
            return orig_req(mod)
        end
        
        controls.init_state()
        _G.require = orig_req
    end)

    it("Deve inicializar a secao de Injetores na memoria", function()
        assert.truthy(#controls.state.sections >= 7, "Deve existir a 7a secao (Injetores)")
        assert.is_not_nil(controls.state.all_injectors["buffers"])
        assert.is_not_nil(controls.state.all_injectors["meu_injetor"])
    end)

    it("Deve renderizar os injetores nativos e customizados quando expandido", function()
        -- Força a expansão da seção 7 para o teste
        controls.state.sections[7] = controls.state.sections[7] or { expanded = true }
        controls.state.sections[7].expanded = true
        
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        assert.truthy(str_lines:match("buffers"), "Deve renderizar o injetor nativo")
        assert.truthy(str_lines:match("%[ Nativo %]"), "Deve marcar como nativo")
        assert.truthy(str_lines:match("meu_injetor"), "Deve renderizar o injetor customizado")
        assert.truthy(str_lines:match("%[ Custom %]"), "Deve marcar como customizado")
        assert.truthy(str_lines:match("%+ Criar Novo Injetor"), "Deve renderizar botao de criar")
    end)
    
    it("A dica de rodape deve instruir sobre a edicao e criacao de injetores", function()
        local hint_edit = controls.get_footer_hint({ type = "edit_injector" })
        assert.truthy(hint_edit:match("e"), "Deve mencionar 'e' para editar")
        
        local hint_create = controls.get_footer_hint({ type = "create_injector" })
        assert.truthy(hint_create:match("<CR>"), "Deve mencionar '<CR>' para criar")
    end)
end)

describe("Fase C - Esquadrões e Meta-Agentes (Squads)", function()
    local controls = require('multi_context.context_controls')
    before_each(function()
        package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); controls.reset_state()
        local orig_req = require
        _G.require = function(mod)
            if mod == 'multi_context.squads' then
                return {
                    load_squads = function()
                        return {
                            squad_ux = {
                                tasks = {
                                    { agent = "tech_lead", chain = {"ux_designer"} }
                                }
                            }
                        }
                    end
                }
            end
            return orig_req(mod)
        end
        controls.init_state()
        _G.require = orig_req
    end)
    it("Deve inicializar a secao de Squads", function()
        assert.truthy(#controls.state.sections >= 8, "Deve existir a 8a secao (Squads)")
        assert.is_not_nil(controls.state.squads["squad_ux"])
    end)
    it("Deve renderizar os esquadrões e as esteiras (chain) ao expandir", function()
        -- Força a expansão da seção 8
        controls.state.sections[8] = controls.state.sections[8] or { expanded = true }
        controls.state.sections[8].expanded = true
        
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        assert.truthy(str_lines:match("squad_ux"), "Deve renderizar o squad")
        assert.truthy(str_lines:match("tech_lead"), "Deve mostrar o orquestrador")
        assert.truthy(str_lines:match("ux_designer"), "Deve mostrar a chain")
    end)
end)

describe("Fase D - Estilizacao e Aparencia", function()
    local controls = require('multi_context.context_controls')
    before_each(function()
        package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); controls.reset_state()
        local config = require('multi_context.config')
        config.options.appearance = { width = 0.8, height = 0.8, border = "rounded" }
        controls.init_state()
    end)
    
    it("Deve inicializar a secao de Aparencia na memoria", function()
        assert.truthy(#controls.state.sections >= 9, "Deve existir a 9a secao (Aparencia)")
        assert.is_not_nil(controls.state.appearance, "Deve puxar os dados de aparencia pro state")
    end)

    it("Deve renderizar width, height e border ao expandir a secao", function()
        controls.state.sections[9] = controls.state.sections[9] or { expanded = true }
        controls.state.sections[9].expanded = true
        
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        assert.truthy(str_lines:match("Largura %(Width%)"), "Deve renderizar a label de Width")
        assert.truthy(str_lines:match("0%.8"), "Deve mostrar o valor atual do Width")
        assert.truthy(str_lines:match("Tipo de Borda"), "Deve renderizar a label de Border")
        assert.truthy(str_lines:match("%[ rounded %]"), "Deve mostrar o tipo de borda atual")
    end)
end)

describe("Fase E - Historico e Gestao de Workspaces", function()
    local controls = require('multi_context.context_controls')
    local test_dir = "/tmp/mctx_history_test/.mctx_chats"

    before_each(function()
        package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); package.loaded["multi_context.context_controls"] = nil; controls = require("multi_context.context_controls"); controls.reset_state()
        
        -- Criando diretório e arquivos de chat mockados no disco
        vim.fn.mkdir(test_dir, "p")
        vim.fn.writefile({"## User >>", "Chat antigo"}, test_dir .. "/chat_20260421_120000.mctx")
        vim.fn.writefile({"## User >>", "Chat mais novo"}, test_dir .. "/chat_20260422_153000.mctx")
        
        -- Mockando git rev-parse para apontar para a nossa pasta fake
        local orig_sys = vim.fn.system
        _G.vim.fn.system = function(cmd)
            if cmd:match("git rev%-parse") then return "/tmp/mctx_history_test\n" end
            return orig_sys(cmd)
        end
        
        controls.init_state()
        _G.vim.fn.system = orig_sys
    end)
    
    after_each(function()
        vim.fn.delete("/tmp/mctx_history_test", "rf")
    end)
    
    it("Deve inicializar a secao de Histórico na memoria", function()
        assert.truthy(#controls.state.sections >= 10, "Deve existir a 10a secao (Workspaces)")
        assert.is_not_nil(controls.state.history_files, "Deve coletar os arquivos de historico")
        assert.truthy(#controls.state.history_files >= 2, "Deve listar no minimo 2 arquivos simulados")
    end)

    it("Deve renderizar os chats anteriores na secao", function()
        controls.state.sections[10] = controls.state.sections[10] or { expanded = true }
        controls.state.sections[10].expanded = true
        
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        assert.truthy(str_lines:match("chat_20260421_120000%.mctx"), "Deve listar o arquivo 1")
        assert.truthy(str_lines:match("chat_20260422_153000%.mctx"), "Deve listar o arquivo 2")
        assert.truthy(str_lines:match("%[ Load %]"), "Deve apresentar a acao de carregar (Load)")
    end)
end)

describe("Fase F - Cofre de Chaves e Diretriz Mestre", function()
    local controls = require('multi_context.context_controls')
    local config = require('multi_context.config')
    local orig_load_api_config
    local orig_readfile
    local orig_filereadable

    before_each(function()
        package.loaded["multi_context.context_controls"] = nil
        controls = require("multi_context.context_controls")
        controls.reset_state()
        
        orig_load_api_config = config.load_api_config
        config.load_api_config = function()
            return { apis = { {name = "openai"}, {name = "anthropic"} } }
        end
        
        orig_readfile = vim.fn.readfile
        orig_filereadable = vim.fn.filereadable
        
        _G.vim.fn.filereadable = function(f)
            if type(f) == "string" and f:match("api_keys%.json") then return 1 end
            return orig_filereadable(f)
        end
        _G.vim.fn.readfile = function(f)
            if type(f) == "string" and f:match("api_keys%.json") then return {'{"openai":"sk-123","anthropic":""}'} end
            return orig_readfile(f)
        end
        
        controls.init_state()
    end)
    
    after_each(function()
        config.load_api_config = orig_load_api_config
        _G.vim.fn.filereadable = orig_filereadable
        _G.vim.fn.readfile = orig_readfile
    end)
    
    it("Deve inicializar a secao do Cofre na memoria extraindo o status das chaves", function()
        assert.truthy(#controls.state.sections >= 11, "Deve existir a 11a secao (Cofre)")
        assert.is_not_nil(controls.state.api_keys_status, "Deve carregar o status das chaves")
        assert.are.same("Configurada", controls.state.api_keys_status["openai"])
        assert.are.same("Faltando", controls.state.api_keys_status["anthropic"])
    end)

    it("Deve renderizar os status na interface", function()
        controls.state.sections[11] = controls.state.sections[11] or { expanded = true }
        controls.state.sections[11].expanded = true
        
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        assert.truthy(str_lines:match("openai"), "Deve mostrar a openai")
        assert.truthy(str_lines:match("%[ Configurada %]"), "Deve marcar como Configurada")
        assert.truthy(str_lines:match("anthropic"), "Deve mostrar a anthropic")
        assert.truthy(str_lines:match("%[ Faltando %]"), "Deve marcar como Faltando")
        assert.truthy(str_lines:match("Diretriz Mestre"), "Deve exibir a opcao do System Prompt")
    end)
end)

describe("Fase G - Telemetria e Modo Debug", function()
    local controls = require('multi_context.context_controls')
    before_each(function()
        package.loaded["multi_context.context_controls"] = nil
        controls = require("multi_context.context_controls")
        controls.reset_state()
        controls.init_state()
    end)
    
    it("Deve inicializar a secao de Telemetria na memoria", function()
        assert.truthy(#controls.state.sections >= 12, "Deve existir a 12a secao (Telemetria)")
        assert.is_not_nil(controls.state.debug_mode ~= nil, "A flag de debug_mode deve ser mapeada pro state")
    end)

    it("Deve renderizar a opcao de Log de Rede na interface", function()
        controls.state.sections[12] = controls.state.sections[12] or { expanded = true }
        controls.state.sections[12].expanded = true
        
        local lines = controls.render()
        local str_lines = table.concat(lines, "\n")
        
        assert.truthy(str_lines:match("Log de Rede"), "Deve exibir a opcao de log de rede")
        assert.truthy(str_lines:match("%[%s*OFF%s*%]") or str_lines:match("%[%s*ON%s*%]"), "Deve possuir um toggle ON/OFF")
    end)
end)
