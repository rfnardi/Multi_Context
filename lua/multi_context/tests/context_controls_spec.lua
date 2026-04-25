local controls = require('multi_context.context_controls')
local config = require('multi_context.config')
local api = vim.api

describe("Fase 25 - Passos 3 e 4: Engine Virtual e Interatividade", function()
    before_each(function()
        controls.reset_state()
        config.options.watchdog = { mode = "off", strategy = "semantic", percent = 0.3, fixed_target = 1500 }
        
        -- Mock for API config
        config.load_api_config = function()
            return {
                default_api = "api_A",
                apis = {
                    { name = "api_A", allow_spawn = false },
                    { name = "api_B", allow_spawn = true }
                }
            }
        end
        config.save_api_config = function(cfg) controls._last_saved_cfg = cfg; return true end
    end)

    it("Passo 3: Deve expandir a seção e adaptar a exibição de acordo com a estratégia", function()
        controls.init_state()
        controls.toggle_section(3) -- Watchdog
        local lines = controls.render()
        
        local expanded_found = false
        for _, line in ipairs(lines) do
            if line:match("▼ %[3%] GUARDIÃO DE CONTEXTO") then expanded_found = true end
        end
        assert.is_true(expanded_found, "Seção 3 deve mudar a seta para expandida")

        -- Teste Percentual
        controls.state.watchdog.strategy = "percent"
        controls.state.watchdog.percent = 0.4
        local lines_perc = controls.render()
        local found_perc = false
        for _, line in ipairs(lines_perc) do
            if line:match("Alvo Percentual:%s+40%%") then found_perc = true end
        end
        assert.is_true(found_perc)

        -- Teste Fixo
        controls.state.watchdog.strategy = "fixed"
        controls.state.watchdog.fixed_target = 1000
        local lines_fixed = controls.render()
        local found_fixed = false
        for _, line in ipairs(lines_fixed) do
            if line:match("Alvo %(Fixo%):%s+1000") then found_fixed = true end
        end
        assert.is_true(found_fixed)
    end)

    it("Passo 4: Deve alterar o modo e estratégia via barra de espaço e salvar o estado", function()
        controls.open_panel()
        
        -- Expand section 3
        local sec3_row = nil
        for r, action in pairs(controls.line_map) do
            if action.type == "section" and action.idx == 3 then sec3_row = r; break end
        end
        api.nvim_win_set_cursor(controls.win, { sec3_row, 0 })
        controls.handle_cr()

        -- Encontra a linha da Estratégia
        local strat_row = nil
        for r, action in pairs(controls.line_map) do
            if action.type == "wd_strategy" then strat_row = r; break end
        end
        
        api.nvim_win_set_cursor(controls.win, { strat_row, 0 })
        controls.handle_space() -- Semântico -> Percentual
        controls.handle_space() -- Percentual -> Fixo

        assert.are.same("fixed", controls.state.watchdog.strategy)
        
        -- Executa o salvamento
        controls.save_config()
        assert.are.same("fixed", config.options.watchdog.strategy, "Deve persistir a estratégia no config em memória")
        
        -- Limpeza
        api.nvim_win_close(controls.win, true)
    end)

    it("Passo 4: Deve manipular as APIs e Swarm com space, dd e p", function()
        controls.open_panel()
        
        -- Expande APIS (sec 1)
        local sec1_row = nil
        for r, action in pairs(controls.line_map) do
            if action.type == "section" and action.idx == 1 then sec1_row = r; break end
        end
        api.nvim_win_set_cursor(controls.win, { sec1_row, 0 })
        controls.handle_cr()

        -- Move a API_A (idx 1) para idx 2 usando dd e p
        local api_a_row = nil
        for r, action in pairs(controls.line_map) do
            if action.type == "api_select" and action.name == "api_A" then api_a_row = r; break end
        end
        
        api.nvim_win_set_cursor(controls.win, { api_a_row, 0 })
        controls.handle_dd() -- Remove api_A pro clipboard. api_B subiu pra índice 1.
        
        assert.are.same("api_B", controls.state.apis[1].name)
        assert.is_nil(controls.state.apis[2])

        -- Agora a api_B é a única na tela, colamos sobre ela
        local api_b_row = nil
        for r, action in pairs(controls.line_map) do
            if action.type == "api_select" and action.name == "api_B" then api_b_row = r; break end
        end
        
        api.nvim_win_set_cursor(controls.win, { api_b_row, 0 })
        controls.handle_p() -- Insere abaixo da api_B

        assert.are.same("api_B", controls.state.apis[1].name)
        assert.are.same("api_A", controls.state.apis[2].name, "A ordem deve ter sido invertida via Drag-and-Drop do estado.")

        controls.save_config()
        assert.is_not_nil(controls._last_saved_cfg)
        assert.are.same("api_B", controls._last_saved_cfg.apis[1].name)
        assert.are.same("api_A", controls._last_saved_cfg.apis[2].name)

        api.nvim_win_close(controls.win, true)
    end)
end)
