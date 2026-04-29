local tools = require('multi_context.ecosystem.tools')

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

describe("Tools Module (Execucao de Shell):", function()
    local tools = require('multi_context.ecosystem.tools')

    it("Deve executar run_shell e retornar SUCESSO com a saida do terminal", function()
        local res = tools.run_shell("echo 'Testando_Terminal_123'")
        assert.truthy(res:match("SUCESSO"))
        assert.truthy(res:match("Testando_Terminal_123"))
    end)

    it("Deve retornar status de FALHA se o comando shell nao existir", function()
        local res = tools.run_shell("comando_bizarro_que_nao_existe_123")
        assert.truthy(res:match("FALHA"))
        -- O erro exato do bash varia entre sistemas, mas a tag FALHA deve estar lá.
    end)
end)







describe("Fase 30 - Passo 1: Motor de Busca Ultrarrápido (Ripgrep)", function()
    local tools = require('multi_context.ecosystem.tools')
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
        assert.truthy(captured_cmd:match("rg %-n %-i"), "Deveria ter invocado o rg com flags -n -i")
        assert.truthy(res:match("mocked_rg_result"), "Deveria retornar o resultado do rg")
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
        assert.truthy(captured_cmd:match("git %-C.*grep"), "Deveria ter invocado o fallback do git grep")
        assert.truthy(res:match("mocked_git_grep_result"), "Deveria retornar o resultado do git grep")
    end)
end)
