describe("Config Module - Fallbacks e Erros", function()
    local config = require('multi_context.config')
    
    it("get_spawn_apis deve retornar vazio se não houver apis configuradas", function()
        local orig = config.load_api_config
        config.load_api_config = function() return nil end
        assert.are.same({}, config.get_spawn_apis())
        config.load_api_config = orig
    end)
    
    it("get_api_names deve retornar vazio se não houver config", function()
        local orig = config.load_api_config
        config.load_api_config = function() return nil end
        assert.are.same({}, config.get_api_names())
        config.load_api_config = orig
    end)
    
    it("get_current_api deve retornar string vazia se falhar", function()
        local orig = config.load_api_config
        config.load_api_config = function() return nil end
        assert.are.same("", config.get_current_api())
        config.load_api_config = orig
    end)

    it("set_selected_api deve retornar false se não houver config", function()
        local orig = config.load_api_config
        config.load_api_config = function() return nil end
        assert.is_false(config.set_selected_api("mock"))
        config.load_api_config = orig
    end)
    
    it("load_api_keys retorna tabela vazia se arquivo nao existir", function()
        local orig_path = config.options.api_keys_path
        config.options.api_keys_path = "/tmp/nao_existe_asdf.json"
        assert.are.same({}, config.load_api_keys())
        config.options.api_keys_path = orig_path
    end)
end)

describe("Utils Module - Boundary Tests", function()
    local utils = require('multi_context.utils.utils')
    
    it("split_lines deve retornar tabela vazia para string nil ou vazia", function()
        assert.are.same({}, utils.split_lines(nil))
        assert.are.same({}, utils.split_lines(""))
    end)
    
    it("estimate_tokens deve retornar 0 para buffer invalido", function()
        assert.are.same(0, utils.estimate_tokens(-1))
    end)
    
    it("copy_code_block avisa se nao houver bloco", function()
        local orig_notify = vim.notify
        local called = false
        vim.notify = function(msg) if msg:match("Nenhum") then called = true end end
        
        local b = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(b)
        vim.api.nvim_buf_set_lines(b, 0, -1, false, {"Line 1", "Line 2"})
        
        utils.copy_code_block()
        assert.is_true(called)
        
        vim.notify = orig_notify
    end)
end)

describe("Squads Module - Edge Cases", function()
    local squads = require('multi_context.ecosystem.squads')
    
    it("load_squads deve retornar tabela vazia se arquivo invalido", function()
        local f = io.open(squads.squads_file, "w")
        f:write("isso_nao_e_json")
        f:close()
        
        assert.are.same({}, squads.load_squads())
    end)
end)

describe("i18n Module - Edge Cases", function()
    local i18n = require('multi_context.i18n')
    
    it("t deve formatar strings com argumentos adicionais", function()
        local str = i18n.t("err_file_not_found", "teste.lua")
        assert.truthy(str:match("teste.lua"))
    end)
end)

describe("State Manager - Edge Cases", function()
    local state = require('multi_context.core.state_manager')
    
    it("patch deve ignorar se nao receber tabela", function()
        state.set("teste", { a = 1 })
        state.patch("teste", "nao_sou_tabela")
        assert.are.same(1, state.get("teste").a)
    end)
    
    it("patch deve criar tabela se a chave nao existir e for patcheada", function()
        state.reset()
        state.patch("nova_chave", { foo = "bar" })
        assert.are.same("bar", state.get("nova_chave").foo)
    end)
end)

describe("Event Bus - Edge Cases", function()
    local bus = require('multi_context.core.event_bus')
    
    it("on deve ignorar callbacks invalidos", function()
        assert.has_no.errors(function()
            bus.on("EVENTO", nil)
            bus.on("EVENTO", "string")
        end)
    end)
    
    it("once deve ignorar callbacks invalidos", function()
        assert.has_no.errors(function()
            bus.once("EVENTO", nil)
        end)
    end)
    
    it("off deve ignorar se evento nao existe", function()
        assert.has_no.errors(function()
            bus.off("EVENTO_INEXISTENTE", function() end)
        end)
    end)
end)

describe("Session Module - Edge Cases", function()
    local session = require('multi_context.core.session')
    
    it("add_message deve ignorar conteudo vazio", function()
        session.clear()
        session.add_message("user", "")
        session.add_message("user", nil)
        assert.are.same(0, #session.get_messages())
    end)
    
    it("sync_from_lines deve ignorar tabela de linhas nil ou vazia", function()
        assert.has_no.errors(function()
            session.sync_from_lines(nil)
            session.sync_from_lines({})
        end)
    end)
end)

describe("Intent Parser - Edge Cases", function()
    local parser = require('multi_context.core.intent_parser')
    
    it("parse deve retornar estrutura limpa se texto for vazio", function()
        local res = parser.parse("")
        assert.are.same("", res.clean_text)
        assert.is_false(res.flags.is_queue)
        
        local res2 = parser.parse(nil)
        assert.are.same("", res2.clean_text)
    end)
end)

describe("Tool Parser - Edge Cases", function()
    local parser = require('multi_context.ecosystem.tool_parser')
    
    it("clean_inner_content deve retornar o mesmo texto se nome da tool for nil", function()
        local res = parser.clean_inner_content("meu texto", nil)
        assert.are.same("meu texto", res)
    end)
    
    it("parse_next_tool deve retornar nil se não houver tag", function()
        local res = parser.parse_next_tool("apenas texto normal sem tag", 1)
        assert.is_nil(res)
    end)
end)

describe("Tool Runner - Edge Cases", function()
    local runner = require('multi_context.ecosystem.tool_runner')
    
    it("Deve bloquear comandos git reset via string direta ou run_shell", function()
        local tool = { name = "git_reset", inner = "", raw_tag = "<tool_call>" }
        local out = runner.execute(tool, true, {value=false}, nil)
        assert.truthy(out:match("ERRO") or out:match("ERROR"))
        
        local tool2 = { name = "run_shell", inner = "git rebase master", raw_tag = "<tool_call>" }
        local out2 = runner.execute(tool2, true, {value=false}, nil)
        assert.truthy(out2:match("ERRO") or out2:match("ERROR"))
    end)
    
    it("Deve negar se o usuario clicar em Nao no confirm", function()
        local orig_confirm = vim.fn.confirm
        vim.fn.confirm = function() return 2 end
        
        local tool = { name = "run_shell", inner = "ls", raw_tag = "<tool_call>" }
        local out = runner.execute(tool, false, {value=false}, nil)
        assert.truthy(out:match("ERRO") or out:match("ERROR"))
        
        vim.fn.confirm = orig_confirm
    end)
    
    it("Deve retornar string crua se usuario clicar em Cancelar", function()
        local orig_confirm = vim.fn.confirm
        vim.fn.confirm = function() return 4 end 
        
        local tool = { name = "run_shell", inner = "ls", raw_tag = "<tool_call>" }
        local out, abort = runner.execute(tool, false, {value=false}, nil)
        
        assert.is_true(abort)
        vim.fn.confirm = orig_confirm
    end)
end)

describe("Native Tools - Edge Cases", function()
    local tools = require('multi_context.ecosystem.native_tools')
    
    it("edit_file deve criar a pasta pai se ela não existir", function()
        local target = "/tmp/mctx_folder_not_exists/arquivo.lua"
        os.remove(target)
        pcall(vim.fn.delete, "/tmp/mctx_folder_not_exists", "rf")
        
        local res = tools.edit_file(target, "print('oi')")
        assert.truthy(res:match("SUCESSO") or res:match("SUCCESS"))
        assert.are.same(1, vim.fn.filereadable(target))
        
        pcall(vim.fn.delete, "/tmp/mctx_folder_not_exists", "rf")
    end)
    
    it("run_shell limpa o comando com trim", function()
        local res = tools.run_shell("   echo oi   ")
        assert.truthy(res:match("oi"))
    end)
    
    it("search_code trunca a saída se for muito grande", function()
        local orig_system = vim.fn.system
        vim.fn.system = function()
            return string.rep("x", 4000)
        end
        
        local res = tools.search_code("qqcoisa")
        assert.truthy(res:match("TRUNCAD") or res:match("TRUNCAT"))
        
        vim.fn.system = orig_system
    end)
end)

describe("Chat View - Edge Cases", function()
    local popup = require('multi_context.ui.chat_view')
    
    it("cycle_swarm_buffer ignora se houver menos de 2 buffers", function()
        popup.swarm_buffers = { { buf = 1, name = "A" } }
        popup.current_swarm_index = 1
        
        popup.cycle_swarm_buffer(1)
        assert.are.same(1, popup.current_swarm_index)
    end)
    
    it("update_title não quebra se a janela não for flutuante válida", function()
        popup.popup_win = vim.api.nvim_get_current_win()
        assert.has_no.errors(function()
            popup.update_title()
        end)
        popup.popup_win = nil
    end)
end)

describe("Skills Manager e Injectors - Edge Cases", function()
    local skills = require('multi_context.ecosystem.skills_manager')
    local injectors = require('multi_context.ecosystem.injectors')
    
    it("load_skills lida graciosamente com diretorio inexistente", function()
        assert.has_no.errors(function()
            skills.load_skills("/caminho/nao/existe/12345")
        end)
    end)

    it("get_custom_injectors lida graciosamente com lixo no diretorio", function()
        local orig = vim.fn.stdpath
        vim.fn.stdpath = function() return "/tmp" end
        vim.fn.mkdir("/tmp/mctx_injectors", "p")
        
        local f = io.open("/tmp/mctx_injectors/lixo.txt", "w")
        f:write("isso nao e lua nem bash")
        f:close()
        
        local custom = injectors.get_custom_injectors()
        assert.are.same(0, #custom)
        
        vim.fn.stdpath = orig
    end)
end)

describe("API Client - Edge Cases", function()
    local client = require('multi_context.llm.api_client')
    local config = require('multi_context.config')
    
    it("execute avisa e retorna se configuração não for encontrada", function()
        local orig = config.load_api_config
        config.load_api_config = function() return nil end
        
        local error_msg = nil
        client.execute({}, nil, nil, nil, function(err) error_msg = err end)
        
        assert.truthy(error_msg:match("Configuração"))
        
        config.load_api_config = orig
    end)
    
    it("execute falha graciosamente se a fila esvaziar por completo sem sucesso", function()
        local orig = config.load_api_config
        config.load_api_config = function() return {
            default_api = "inexistente",
            apis = { { name = "inexistente", api_type = "API_FANTASMA" } }
        } end
        
        local error_msg = nil
        client.execute({}, nil, nil, nil, function(err) error_msg = err end)
        
        assert.truthy(error_msg:match("todas as APIs"))
        
        config.load_api_config = orig
    end)
end)

describe("React Orchestrator - Edge Cases", function()
    local react = require('multi_context.core.react_orchestrator')
    local EventBus = require('multi_context.core.event_bus')
    
    it("ProcessTurn não faz nada se o buffer for inválido", function()
        local called = false
        EventBus.once("UI_APPEND_LINES", function() called = true end)
        
        react.ProcessTurn(-1)
        
        assert.is_false(called)
    end)
    
    it("ProcessTurn não faz nada se não achar o último prompt do usuário", function()
        local called = false
        EventBus.once("UI_APPEND_LINES", function() called = true end)
        
        local b = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(b, 0, -1, false, {"Linha qualquer sem tag de usuário"})
        
        react.ProcessTurn(b)
        assert.is_false(called)
    end)
end)
