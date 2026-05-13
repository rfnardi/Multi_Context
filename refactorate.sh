#!/bin/bash

echo "🚀 Corrigindo a Árvore Sintática do Busted (Removendo Testes Flutuantes)..."

# 1. Fechando os testes dentro do describe em native_tools_spec.lua
cat << 'EOF' > lua/multi_context/tests/native_tools_spec.lua
local tools = require('multi_context.ecosystem.native_tools')

describe("Tools Module (Agentes Autônomos):", function()
    local tmp_file = os.tmpname()

    after_each(function()
        os.remove(tmp_file) -- Limpa lixo após os testes
    end)

    it("Deve criar e sobrescrever um arquivo (edit_file)", function()
        local res = tools.edit_file(tmp_file, "ola mundo\nteste")
        assert.truthy(res:match("SUCESSO"))
        
        local lines = vim.fn.readfile(tmp_file)
        assert.are.same({"ola mundo", "teste"}, lines)
    end)

    it("Deve editar cirurgicamente um arquivo mantendo as pontas (replace_lines)", function()
        -- Preparando arquivo inicial
        tools.edit_file(tmp_file, "Linha 1\nLinha 2\nLinha 3\nLinha 4")
        
        -- Substituindo as linhas 2 e 3
        local res = tools.replace_lines(tmp_file, 2, 3, "NOVA 2\nNOVA 3")
        assert.truthy(res:match("SUCESSO"))
        
        local lines = vim.fn.readfile(tmp_file)
        assert.are.same({"Linha 1", "NOVA 2", "NOVA 3", "Linha 4"}, lines)
    end)

    it("Deve limpar Markdown intruso do código fonte ao salvar arquivos", function()
        -- Simula a IA enviando ```lua\n...\n```
        local payload_sujo = "```lua\nlocal a = 1\n```"
        tools.edit_file(tmp_file, payload_sujo)
        
        local lines = vim.fn.readfile(tmp_file)
        -- O parser da ferramenta deve ter removido as crases
        assert.are.same({"local a = 1"}, lines)
    end)

    it("Deve retornar erro amigavel ao ler arquivo que nao existe (read_file)", function()
        local res = tools.read_file("caminho_inexistente_alucinacao.txt")
        assert.truthy(res:match("ERRO: Arquivo não encontrado"))
    end)

    it("Deve retornar erro se a IA nao enviar o path", function()
        local res = tools.read_file(nil)
        assert.truthy(res:match("ERRO"))
        
        local res2 = tools.read_file("")
        assert.truthy(res2:match("ERRO"))
    end)

    it("Deve proteger replace_lines contra parametros invalidos", function()
        local res = tools.replace_lines("arquivo.txt", "nao_sou_numero", 15, "conteudo")
        assert.truthy(res:match("ERRO: 'start' e 'end' devem ser números"))
    end)
end)

describe("Tools Module (Execucao de Shell):", function()
    local tools = require('multi_context.ecosystem.native_tools')

    it("Deve executar run_shell e retornar SUCESSO com a saida do terminal", function()
        local res = tools.run_shell("echo 'Testando_Terminal_123'")
        assert.truthy(res:match("SUCESSO"))
        assert.truthy(res:match("Testando_Terminal_123"))
    end)

    it("Deve retornar status de FALHA se o comando shell nao existir", function()
        local res = tools.run_shell("comando_bizarro_que_nao_existe_123")
        assert.truthy(res:match("FALHA"))
    end)
end)

describe("Fase 30 - Passo 1: Motor de Busca Ultrarrápido (Ripgrep)", function()
    local tools = require('multi_context.ecosystem.native_tools')
    local orig_executable
    local orig_system

    before_each(function()
        orig_executable = vim.fn.executable
        orig_system = vim.fn.system
        vim.fn.system("true")
    end)

    after_each(function()
        vim.fn.executable = orig_executable
        vim.fn.system = orig_system
    end)

    it("Deve usar ripgrep se 'rg' estiver disponivel no sistema", function()
        local captured_cmd = ""
        vim.fn.executable = function(cmd)
            if cmd == "rg" then return 1 end
            return orig_executable(cmd)
        end
        vim.fn.system = function(cmd)
            if type(cmd) == "string" and cmd:match("^rg ") then
                captured_cmd = cmd
                return "mocked_rg_result\n"
            end
            if type(cmd) == "string" and cmd:match("git rev%-parse") then
                return "/mock/repo/root\n"
            end
            return orig_system(cmd)
        end

        local res = tools.search_code("frete")
        assert.truthy(captured_cmd:match("rg %-n %-i"))
        assert.truthy(res:match("mocked_rg_result"))
    end)

    it("Deve usar git grep como fallback se 'rg' nao existir", function()
        local captured_cmd = ""
        vim.fn.executable = function(cmd)
            if cmd == "rg" then return 0 end
            return orig_executable(cmd)
        end
        vim.fn.system = function(cmd)
            if type(cmd) == "string" and cmd:match("git %-C.*grep") then
                captured_cmd = cmd
                return "mocked_git_grep_result\n"
            end
            if type(cmd) == "string" and cmd:match("git rev%-parse") then
                return "/mock/repo/root\n"
            end
            return orig_system(cmd)
        end

        local res = tools.search_code("login")
        assert.truthy(captured_cmd:match("git %-C.*grep"))
        assert.truthy(res:match("mocked_git_grep_result"))
    end)
end)

describe("Fase 38 - Situational Awareness Tools:", function()
    local tools = require('multi_context.ecosystem.native_tools')

    it("get_agents_info deve retornar os agentes e suas skills", function()
        local res = tools.get_agents_info()
        assert.truthy(res:match("tech_lead"))
        assert.truthy(res:match("coder"))
    end)

    it("get_project_stack deve retornar OS e detalhes do ambiente", function()
        local buf = vim.api.nvim_create_buf(false, true)
        local res = tools.get_project_stack(buf)
        assert.truthy(res:match("SO:") or res:match("Shell:"))
        assert.truthy(res:match("Indent"))
    end)

    it("get_git_env deve retornar branch atual ou falhar graciosamente fora de repo", function()
        local res = tools.get_git_env()
        assert.truthy(res:match("Branch atual") or res:match("Não é um repositório Git") or res:match("err_not_git"))
    end)
end)
EOF

# 2. Fechando o teste flutuante de Init no session_spec.lua
cat << 'EOF' > lua/multi_context/tests/session_spec.lua
local utils = require('multi_context.utils.utils')
local swarm = require('multi_context.core.swarm_manager')
local popup = require('multi_context.ui.chat_view')

describe("Fase 18.5 - Session & State Management:", function()
    before_each(function()
        swarm.reset()
        popup.swarm_buffers = {}
    end)

    it("Deve gerar tag de sessao e injetar o swarm_state", function()
        swarm.state.queue = { { agent = "qa", instruction = "teste unitario" } }
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"## User >>", "Oi, IA"})
        popup.popup_buf = buf
        
        local filename, exported_text = utils.build_workspace_content(buf, nil)
        
        assert.truthy(exported_text:match("<mctx_session id="), "Deve conter tag de sessao no topo")
        assert.truthy(exported_text:match("<swarm_state>"), "Deve conter tag de estado do enxame no final")
        assert.truthy(exported_text:match("qa"), "Deve conter os dados da fila exportados em JSON")
        assert.truthy(filename:match("%.mctx$"), "Deve gerar o nome do arquivo corretamente")
    end)
    
    it("Deve desserializar e reconstruir o enxame ao carregar o chat", function()
        local payload = [[
<mctx_session id="999" created="2026-04-21T00:00:00" updated="2026-04-21T00:00:00" />
## User >>
Teste
<swarm_state>
{"queue":[{"agent":"coder","instruction":"faz_algo"}], "buffers":[{"name":"coder","lines":["## IA >>","Codando..."]}]}
</swarm_state>
]]
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(payload, "\n", {plain=true}))
        
        popup.swarm_buffers = { { buf = buf, name = "Main" } }
        
        utils.load_workspace_state(buf)
        
        assert.are.same(1, #swarm.state.queue, "A fila devera ter voltado a vida")
        assert.are.same("coder", swarm.state.queue[1].agent)
        assert.truthy(#popup.swarm_buffers > 1, "Deve ter recriado o buffer do worker paralelo na memoria")
        assert.are.same("coder", popup.swarm_buffers[2].name)
    end)

    it("Deve orquestrar o load pelo comando ToggleWorkspaceView (init.lua)", function()
        local init = require('multi_context.init')
        local utils = require('multi_context.utils.utils')
        
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, "/caminho/falso/chat_123.mctx")
        vim.api.nvim_set_current_buf(buf)
        
        popup.popup_win = nil
        init.current_workspace_file = nil
        
        local payload = {
            '<mctx_session id="123" />',
            '## User >>',
            'Contexto'
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, payload)
        
        local orig_create_popup = popup.create_popup
        local was_popup_called = false
        popup.create_popup = function(b) 
            was_popup_called = true
            popup.popup_buf = b
        end
        
        init.ToggleWorkspaceView()
        
        assert.truthy(init.current_workspace_file:match("chat_123%.mctx"), "O arquivo de workspace atual não foi setado!")
        assert.is_true(was_popup_called, "A janela flutuante não foi invocada pelo init.lua!")
        
        popup.create_popup = orig_create_popup
    end)
end)
EOF

echo "✅ Testes realocados. O total de testes ficará finalmente cravado e determinístico!"
