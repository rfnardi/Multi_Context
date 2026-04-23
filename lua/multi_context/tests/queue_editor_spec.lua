local queue_editor = require('multi_context.queue_editor')
local config = require('multi_context.config')

describe("Queue Editor Module:", function()
    local orig_load, orig_save, orig_notify
    local saved_cfg = nil

    before_each(function()
        orig_load = config.load_api_config
        orig_save = config.save_api_config
        orig_notify = vim.notify
        
        vim.notify = function() end

        -- Mock do arquivo de configuração JSON
        config.load_api_config = function()
            return {
                apis = {
                    { name = "api_principal", allow_spawn = false },
                    { name = "api_worker", allow_spawn = true }
                }
            }
        end
        
        -- Mock para interceptar o salvamento
        config.save_api_config = function(cfg)
            saved_cfg = cfg
            return true
        end
    end)

    after_each(function()
        config.load_api_config = orig_load
        config.save_api_config = orig_save
        vim.notify = orig_notify
        saved_cfg = nil
    end)

    it("Deve renderizar os marcadores allow_spawn, inverter os valores e salvar", function()
        -- Abre o editor (cria o buffer UI)
        queue_editor.open_editor()
        
        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        
        -- Verifica renderização inicial
        assert.truthy(lines[1]:match("%[ %] api_principal"), "API Principal deve nascer desmarcada para spawn")
        assert.truthy(lines[2]:match("%[x%] api_worker"), "API Worker deve nascer marcada para spawn")
        
        -- Simulamos a edição pelo usuário (invertendo as flags e mudando a ordem)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "[ ] api_worker",
            "[x] api_principal"
        })
        
        -- Disparamos o evento de salvamento (comando :w)
        vim.api.nvim_exec_autocmds("BufWriteCmd", { buffer = buf })
        
        -- Verificamos se o parser processou corretamente a UI de volta para a estrutura de dados
        assert.is_not_nil(saved_cfg)
        
        -- api_worker subiu e perdeu o spawn
        assert.are.same("api_worker", saved_cfg.apis[1].name)
        assert.is_false(saved_cfg.apis[1].allow_spawn)
        
        -- api_principal desceu e ganhou o spawn
        assert.are.same("api_principal", saved_cfg.apis[2].name)
        assert.is_true(saved_cfg.apis[2].allow_spawn)
    end)
end)
