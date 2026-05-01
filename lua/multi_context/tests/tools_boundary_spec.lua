local tools = require('multi_context.ecosystem.native_tools')
local tool_runner = require('multi_context.ecosystem.tool_runner')
local context_builders = require('multi_context.utils.context_builders')

describe("Fase 37 - TEMA 2: Boundary Testing (Limites de Ferramentas):", function()
    local tmp_file = os.tmpname()

    before_each(function()
        vim.fn.writefile({"Linha 1", "Linha 2", "Linha 3"}, tmp_file)
    end)

    after_each(function()
        os.remove(tmp_file)
    end)

    it("replace_lines: Deve suportar parâmetros fora dos limites (Out of Bounds) sem crashar", function()
        -- IA pede para substituir da linha 50 à 100 num arquivo de 3 linhas
        local res = tools.replace_lines(tmp_file, 50, 100, "Linha Extra")
        
        -- O comportamento correto é clamp: limitar aos limites reais e não estourar Index Error.
        assert.truthy(res:match("SUCESSO") or res:match("SUCCESS"))
        
        local final_lines = vim.fn.readfile(tmp_file)
        -- A linha extra deve ter sido apensada no final
        assert.are.same("Linha Extra", final_lines[#final_lines])
    end)

    it("native_tools: Não deve quebrar ao receber strings vazias ou nulas", function()
        assert.truthy(tools.run_shell(""):match("ERRO") or tools.run_shell(""):match("ERROR"))
        assert.truthy(tools.read_file(nil):match("ERRO") or tools.read_file(nil):match("ERROR"))
        assert.truthy(tools.search_code(""):match("ERRO") or tools.search_code(""):match("ERROR"))
    end)
    
    it("context_builders: Deve abortar silenciosamente a leitura de arquivos gigantes (>100KB)", function()
        local orig_stat = vim.loop.fs_stat
        
        -- Mockamos o Kernel para fingir que TODOS os arquivos tem 200 Megabytes
        vim.loop.fs_stat = function(path)
            local stat = orig_stat(path)
            if stat then stat.size = 200 * 1024 * 1024 end
            return stat
        end

        local folder_ctx = context_builders.get_folder_context()
        
        vim.loop.fs_stat = orig_stat -- Restaura
        
        assert.truthy(folder_ctx:match("AVISO: ARQUIVO IGNORADO"), "Arquivos massivos DEVEM ser barrados para não explodir o Neovim")
    end)
end)

describe("Fase 37 - TEMA 2: Gatekeeper (Comandos Destrutivos):", function()
    local orig_confirm

    before_each(function()
        orig_confirm = vim.fn.confirm
    end)

    after_each(function()
        vim.fn.confirm = orig_confirm
    end)

    it("O Tool Runner deve bloquear comandos perigosos em modo autonomo", function()
        -- Simula o usuário dizendo "NÃO" (opção 2) no popup de confirmação do Neovim
        vim.fn.confirm = function() return 2 end
        
        local tool_data = {
            name = "run_shell",
            inner = "rm -rf /pastas/importantes",
            raw_tag = "<tool_call>"
        }
        
        -- Executa no modo autônomo (onde a proteção entra em ação)
        local approve_ref = { value = false }
        local output = tool_runner.execute(tool_data, true, approve_ref, nil)
        
        assert.truthy(output:match("NEGADO") or output:match("DENIED"), "O Gatekeeper deve retornar Acesso Negado ao LLM")
        assert.is_false(approve_ref.value, "A autorização global não pode ter sido ativada")
    end)
end)
