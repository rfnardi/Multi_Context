#!/bin/bash

TEST_FILE="lua/multi_context/tests/tdd_fixes_spec.lua"

mkdir -p "lua/multi_context/tests"

cat << 'EOF' > "$TEST_FILE"
local transport = require('multi_context.llm.transport')
local swarm = require('multi_context.core.swarm_manager')
local tools = require('multi_context.ecosystem.native_tools')
local chat_view = require('multi_context.ui.chat_view')
local api_client = require('multi_context.llm.api_client')

describe("Fixes TDD - Bugs Críticos e Performance (1.1, 1.3, 2.1, 2.2):", function()

    it("1.1: Transport - Deve fechar o canal de stdin do curl apenas UMA vez", function()
        local chansend_count = 0
        local chanclose_count = 0
        local orig_chansend = vim.fn.chansend
        local orig_chanclose = vim.fn.chanclose
        
        vim.fn.chansend = function(job, data) chansend_count = chansend_count + 1 end
        vim.fn.chanclose = function(job, stream) chanclose_count = chanclose_count + 1 end
        
        local tmp = os.tmpname()
        local f = io.open(tmp, "w")
        f:write('{"dummy":"data"}')
        f:close()
        
        table.insert(_G.MultiContextTempFiles, tmp)
        
        transport.run_http_stream({"echo"}, tmp, function() end, function() end, function() end)
        
        assert.are.same(1, chansend_count, "chansend foi chamado mais de uma vez (Duplicação)")
        assert.are.same(1, chanclose_count, "chanclose foi chamado mais de uma vez (Duplicação)")
        
        vim.fn.chansend = orig_chansend
        vim.fn.chanclose = orig_chanclose
    end)

    it("1.3: Swarm - Nao deve dar starvation no worker se a API falhar silenciosamente (Throw Error)", function()
        swarm.reset()
        swarm.state.queue = { { agent = "coder", instruction = "teste" } }
        swarm.state.workers = {
            { api = { name = "mock_api" }, busy = false, current_task = nil }
        }
        
        local orig_execute = api_client.execute
        api_client.execute = function()
            error("FALHA CATASTROFICA SILENCIOSA (ex: timeout de rede no backend lua)")
        end
        
        swarm.dispatch_next()
        
        -- O Worker TEM que ser liberado, não pode ficar "busy = true" pendurado eternamente
        assert.is_false(swarm.state.workers[1].busy, "O worker sofreu starvation e continuou ocupado após a falha!")
        
        api_client.execute = orig_execute
    end)

    it("2.1: Native Tools - run_shell e apply_diff DEVEM rodar de forma Assíncrona (Evitar UI Freeze)", function()
        local orig_system = vim.fn.system
        local orig_jobstart = vim.fn.jobstart
        
        local system_called = false
        vim.fn.system = function(cmd)
            -- Apenas permite 'git rev-parse' que é usado silenciosamente para achar a pasta
            if type(cmd) == "string" and cmd:match("git rev%-parse") then
                return orig_system(cmd)
            end
            system_called = true
            return ""
        end
        
        local jobstart_called = false
        vim.fn.jobstart = function(cmd, opts)
            jobstart_called = true
            if opts.on_exit then opts.on_exit(1, 0) end
            return 1
        end
        
        tools.run_shell("echo 1")
        
        assert.is_false(system_called, "A ferramenta executou vim.fn.system síncrono (Isso congela a UI!)")
        assert.is_true(jobstart_called, "A ferramenta deveria ter usado vim.fn.jobstart + vim.wait")
        
        vim.fn.system = orig_system
        vim.fn.jobstart = orig_jobstart
    end)

    it("2.2: Chat View - create_folds DEVE recuperar todas as linhas em batch (Gargalo FFI)", function()
        local orig_get_lines = vim.api.nvim_buf_get_lines
        local get_lines_count = 0
        
        vim.api.nvim_buf_get_lines = function(buf, start, end_, strict)
            get_lines_count = get_lines_count + 1
            return orig_get_lines(buf, start, end_, strict)
        end
        
        local buf = vim.api.nvim_create_buf(false, true)
        local lines = {}
        for i=1, 100 do table.insert(lines, "Linha " .. i) end
        
        orig_get_lines(buf, 0, -1, false) -- dry run inicial
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        
        local win = vim.api.nvim_open_win(buf, true, {relative='editor', width=10, height=10, row=0, col=0})
        
        get_lines_count = 0 -- Reseta contagem
        chat_view.create_folds(buf)
        
        -- Garante execução do vim.schedule da UI
        vim.wait(100, function() return false end)
        
        -- Ele precisa buscar as 100 linhas de uma vez só (chamada única ou poucas do core)
        -- e não 100 vezes iterativamente.
        assert.is_true(get_lines_count < 5, "nvim_buf_get_lines foi chamado 1 vez por linha (" .. get_lines_count .. "x). Isso gera gargalo absurdo de FFI C->Lua!")
        
        pcall(vim.api.nvim_win_close, win, true)
        vim.api.nvim_buf_get_lines = orig_get_lines
    end)
end)
EOF

echo "✅ [Passo 1] Testes TDD gerados em $TEST_FILE."
echo "💡 Execute ':!make test' e comprove que esses 4 novos testes irão FALHAR (Red Phase)."
