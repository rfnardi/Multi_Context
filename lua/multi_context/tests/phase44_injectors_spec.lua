local assert = require('luassert')
local stub = require('luassert.stub')
local injectors = require('multi_context.ecosystem.injectors')
local watchdog = require('multi_context.core.dynamic_watchdog')
local project_dump = require('examples.injectors.project_dump')

describe("Fase 44.3 e 44.4: Injectors Tabulares e Múltiplos Blocos", function()
    local snap_math_random

    before_each(function()
        snap_math_random = math.random
        math.random = function() return 1234 end
    end)

    after_each(function()
    if _G.AwaitForBackground then _G.AwaitForBackground() end
        math.random = snap_math_random
    end)

    describe("44.3: O Motor de Injectors processa Arrays de Blocos", function()
        it("deve transformar array de tabelas em string XML e disparar o watchdog", function()
            stub(watchdog, 'dispatch_parallel_jit_tasks')

            local content_returned = {
                { title = "src/main.lua", content = "print('hello')" },
                { title = "src/utils.lua", content = "return {}" }
            }

            local result = injectors.process_injection(content_returned, 99)

            -- Verifica a estrutura gerada (o Abstract provisório)
            assert.is_truthy(result:match("<abstract>"))
            assert.is_truthy(result:match("<summary>Indexando: src/main%.lua%.%.%.</summary>"))
            assert.is_truthy(result:match("<content>\nprint%('hello'%)"))

            -- Força uma pequena espera caso o watchdog.dispatch tenha sido envelopado num vim.schedule
            vim.wait(50, function() return watchdog.dispatch_parallel_jit_tasks.calls and #watchdog.dispatch_parallel_jit_tasks.calls > 0 end)

            assert.stub(watchdog.dispatch_parallel_jit_tasks).was_called(1)
            local args = watchdog.dispatch_parallel_jit_tasks.calls[1].refs
            assert.are.equal(99, args[1])
            assert.are.equal(2, #args[2])
            assert.are.equal("print('hello')", args[2][1].content)

            watchdog.dispatch_parallel_jit_tasks:revert()
        end)
        
        it("deve manter o comportamento antigo para strings puras (retrocompatibilidade)", function()
            local content_returned = "Apenas uma string"
            local result = injectors.process_injection(content_returned, 99)
            assert.are.equal("Apenas uma string", result)
        end)
    end)

    describe("44.4: Atualização do project_dump", function()
        it("deve retornar um array de tabelas para injeção", function()
            -- Reseta o shell_error nativo executando um comando real e bem-sucedido antes do mock
            vim.fn.system("echo 1")
            stub(vim.fn, 'system')
            stub(vim.fn, 'readfile')
            stub(vim.fn, 'split')

            vim.fn.system.on_call_with("git rev-parse --show-toplevel").returns("/home/fake")
            
            vim.fn.system.returns("tree_output")
            vim.fn.split.returns({"/home/fake/a.lua", "/home/fake/b.lua"})
            vim.fn.readfile.returns({"linha 1", "linha 2"})

            local result = project_dump.execute()

            assert.are.equal("table", type(result))
            
            -- O formato estrito deve respeitar a chave title e content
            assert.is_truthy(result[1].title)
            assert.is_truthy(result[1].content)

            vim.fn.system:revert()
            vim.fn.readfile:revert()
            vim.fn.split:revert()
        end)
    end)
end)
