describe("Config Module:", function()
  local config

  before_each(function()
    package.loaded['multi_context.config'] = nil
    config = require('multi_context.config')
  end)

  it("Deve carregar as opções default corretamente", function()
    config.setup({ user_name = "Nardi" })
    assert.are.same("Nardi", config.options.user_name)
  end)

  it("Deve mesclar opções do usuário usando setup() sem perder os defaults", function()
    -- Passando o path falso PARA DENTRO do setup isola a leitura do disco real
    config.setup({ 
      user_name = "NovoUsuario", 
      appearance = { width = 0.9 },
      config_path = "/tmp/fake_mctx_config_nao_existe.json"
    })

    assert.are.same("NovoUsuario", config.options.user_name)
    assert.are.same(0.9, config.options.appearance.width)
    assert.are.same("rounded", config.options.appearance.border)
  end)
end)

describe("Config Module (Manipulacao de Arquivo JSON):", function()
  local config
  it("Deve ler e alterar APIs usando um JSON em disco", function()
    package.loaded['multi_context.config'] = nil; config = require('multi_context.config')
    local tmp_json = os.tmpname()
    local mock_cfg = { default_api = "api_A", apis = { { name = "api_A" }, { name = "api_B" } } }
    local f = io.open(tmp_json, "w")
    f:write(vim.fn.json_encode(mock_cfg)); f:close()

    config.options.config_path = tmp_json
    assert.are.same({"api_A", "api_B"}, config.get_api_names())
    assert.are.same("api_A", config.get_current_api())
    config.set_selected_api("api_B")
    assert.are.same("api_B", config.get_current_api())
    os.remove(tmp_json)
  end)
end)

describe("Fase 25 - Configurações do Guardião 2.0:", function()
  local config = require('multi_context.config')
  it("Deve carregar as opções default de Compressao e Modos", function()
    package.loaded['multi_context.config'] = nil; config = require('multi_context.config')
    config.options = vim.deepcopy(config.defaults)
    assert.is_not_nil(config.options.watchdog)
    assert.are.same("off", config.options.watchdog.mode)
    assert.are.same("semantic", config.options.watchdog.strategy)
  end)
end)
