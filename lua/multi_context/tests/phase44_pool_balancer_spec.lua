require("multi_context.tests.libuv_barrier")
local assert = require('luassert')
local stub = require('luassert.stub')
local config = require('multi_context.config')
local watchdog = require('multi_context.core.dynamic_watchdog')
local api_client = require('multi_context.llm.api_client')
local i18n = require('multi_context.i18n')

describe("Fase 44: Context Injectors com Indexação Semântica Ativa", function()
    local snap_config

    before_each(function()
        snap_config = vim.deepcopy(config.options)
        if not vim.notify then vim.notify = function() end end
        stub(vim, 'notify')
    end)

    after_each(function()
    if _G.AwaitForBackground then _G.AwaitForBackground() end
        config.options = snap_config
        if vim.notify.revert then vim.notify:revert() end
    end)

    describe("44.1: Configuração do Pool no IAM", function()
        it("deve possuir as traduções para a UI do pool de background", function()
            -- TDD: As chaves de tradução precisam ser reconhecidas.
            -- O retorno não deve ser a própria chave (o que acontece quando a tradução não existe).
            assert.is_not_equal("cc_bg_pool_title", i18n.t("cc_bg_pool_title"))
        end)
    end)

    describe("44.2: O Load Balancer (Round-Robin) no Watchdog", function()
        it("deve distribuir blocos paralelamente entre as APIs do pool (allow_background=true)", function()
            stub(config, 'load_api_config')
            config.load_api_config.returns({
                apis = {
                    { name = "haiku", allow_background = true },
                    { name = "gpt4o", allow_background = false },
                    { name = "flash", allow_background = true },
                }
            })
            stub(api_client, 'execute')

            local blocos = {
                { id = "file1", content = "código 1" },
                { id = "file2", content = "código 2" },
                { id = "file3", content = "código 3" },
            }

            -- O Dispatcher paralelo recebe o buffer e o array de blocos.
            watchdog.dispatch_parallel_jit_tasks(1, blocos)

            -- Deve ter disparado 3 chamadas assíncronas
            assert.stub(api_client.execute).was_called(3)

            -- Validação do Round-Robin
            -- Argumentos do execute: (messages, on_start, on_chunk, on_done, on_error, force_api_cfg)
            local args1 = api_client.execute.calls[1].refs
            assert.are.equal("haiku", args1[6].name)

            local args2 = api_client.execute.calls[2].refs
            assert.are.equal("flash", args2[6].name)

            local args3 = api_client.execute.calls[3].refs
            assert.are.equal("haiku", args3[6].name)

            config.load_api_config:revert()
            api_client.execute:revert()
        end)

        it("não deve invocar api_client se nenhuma API do pool estiver habilitada", function()
            stub(config, 'load_api_config')
            config.load_api_config.returns({
                apis = {
                    { name = "gpt4o", allow_background = false },
                }
            })
            stub(api_client, 'execute')

            local blocos = { { id = "file1", content = "código" } }
            watchdog.dispatch_parallel_jit_tasks(1, blocos)

            -- Não deve ocorrer injeção paralela se não houver pool ativo
            assert.stub(api_client.execute).was_not_called()

            config.load_api_config:revert()
            api_client.execute:revert()
        end)
    end)
end)
