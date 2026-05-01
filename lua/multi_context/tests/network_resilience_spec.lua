local transport = require('multi_context.llm.transport')
local api_client = require('multi_context.llm.api_client')
local config = require('multi_context.config')

describe("Fase 37 - TEMA 1: Resiliência de Rede (Transport & Chunking):", function()
    it("Deve extrair um chunk JSON perfeito", function()
        local stream = 'algum_lixo_antes "text":"Conteudo Extraido"} algum_lixo_depois'
        local chunks, rest = transport.extract_text_chunks(stream)
        assert.are.same(1, #chunks)
        assert.are.same("Conteudo Extraido", chunks[1])
        assert.are.same("} algum_lixo_depois", rest)
    end)

    it("Deve preservar chunks quebrados pela metade (Bufferização de Stream HTTP)", function()
        -- Simulando a internet lenta onde o pacote TCP corta o JSON no meio da palavra
        local stream_incompleto = '"text":"Conteudo Incom'
        local chunks, rest = transport.extract_text_chunks(stream_incompleto)
        
        -- Não deve quebrar tentando fazer o parse, deve retornar 0 chunks e salvar o resto
        assert.are.same(0, #chunks, "Nenhum chunk concluído deve ser emitido")
        assert.are.same(stream_incompleto, rest, "O fragmento deve ser mantido no buffer para a próxima iteração")
    end)

    it("Deve extrair multiplos chunks de uma vez e lidar com quebras de linha escapadas", function()
        local stream = '"text":"Linha 1\\nLinha 2"} lixo "text":"Linha 3"}'
        local chunks, rest = transport.extract_text_chunks(stream)
        
        assert.are.same(2, #chunks)
        assert.are.same("Linha 1\nLinha 2", chunks[1], "Deve resolver o scape character do JSON")
        assert.are.same("Linha 3", chunks[2])
    end)
end)

describe("Fase 37 - TEMA 1: Fallback e Roteamento (API Client):", function()
    local orig_handlers

    before_each(function()
        orig_handlers = vim.deepcopy(require('multi_context.llm.api_handlers'))
        config.options.config_path = "/tmp/mctx_fake_config.json"
        
        -- Simulando a configuração com 2 APIs
        config.load_api_config = function()
            return {
                fallback_mode = true,
                default_api = "api_quebrada",
                apis = {
                    { name = "api_quebrada", api_type = "openai" },
                    { name = "api_salvadora", api_type = "anthropic", ["include_in_fall-back_mode"] = true }
                }
            }
        end
    end)

    after_each(function()
        package.loaded['multi_context.llm.api_handlers'] = orig_handlers
    end)

    it("O Motor deve pular silenciosamente para a proxima API se a primeira falhar", function()
        local chamadas = {}
        
        -- Injetando Mocks diretamente nos Handlers
        local handlers = require('multi_context.llm.api_handlers')
        handlers.openai = {
            make_request = function(cfg, msgs, keys, _, cb)
                table.insert(chamadas, cfg.name)
                -- Simula falha catastrófica (Erro 500, Timeout, etc)
                cb(nil, "ERRO 500", true, nil, nil)
            end
        }
        handlers.anthropic = {
            make_request = function(cfg, msgs, keys, _, cb)
                table.insert(chamadas, cfg.name)
                -- Simula Sucesso
                cb("Resposta de Sucesso", nil, true, nil, nil)
            end
        }

        local resposta_final = nil
        api_client.execute({}, function() end, function(c) resposta_final = c end, function() end, function() end)
        
        -- Devido aos `vim.schedule` internos, executamos a fila de eventos do Neovim
        vim.wait(100, function() return resposta_final ~= nil end, 5)

        assert.are.same(2, #chamadas, "O sistema DEVE ter tentado as duas APIs")
        assert.are.same("api_quebrada", chamadas[1])
        assert.are.same("api_salvadora", chamadas[2], "O Fallback direcional deve ter sido acionado")
        assert.are.same("Resposta de Sucesso", resposta_final)
    end)
end)
