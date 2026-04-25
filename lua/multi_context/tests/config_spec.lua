 -- lua/multi_context/tests/config_spec.lua -- Nota: O require foi movido para dentro dos blocos para respeitar a ordem de inicialização do minimal_init.lua

describe("Config Module:", function()
  local config

  before_each(function()
    -- Limpa o cache para garantir que o setup() do minimal_init seja respeitado
    package.loaded['multi_context.config'] = nil
    config = require('multi_context.config')
  end)

  it("Deve carregar as opções default corretamente", function()
    -- O minimal_init.lua já chamou setup({ user_name = "Nardi" })
    -- Mas como limpamos o cache, vamos garantir que o setup rode com o valor esperado
    config.setup({ user_name = "Nardi" })
    assert.are.same("Nardi", config.options.user_name)
  end)

  it("Deve mesclar opções do usuário usando setup() sem perder os defaults", function()
    config.options = vim.deepcopy(config.defaults)
    config.setup({ user_name = "NovoUsuario", appearance = { width = 0.9 } })

    -- Alterou o que foi pedido
    assert.are.same("NovoUsuario", config.options.user_name)
    assert.are.same(0.9, config.options.appearance.width)
    -- Manteve o que NÃO foi pedido (Deep Merge)
    assert.are.same("rounded", config.options.appearance.border)
  end)
end)

describe("Config Module (Manipulacao de Arquivo JSON):", function()
  local config

  it("Deve ler e alterar APIs usando um JSON em disco", function()
    -- Garante reload limpo
    package.loaded['multi_context.config'] = nil
    config = require('multi_context.config')

    local tmp_json = os.tmpname()
    -- Simulando o arquivo JSON criado pelo usuario
    local mock_cfg = { default_api = "api_A", apis = { { name = "api_A" }, { name = "api_B" } } }
    local f = io.open(tmp_json, "w")
    f:write(vim.fn.json_encode(mock_cfg))
    f:close()

    -- Força o plugin a olhar para o nosso arquivo falso
    config.options.config_path = tmp_json

    -- Testa extração de nomes
    local names = config.get_api_names()
    assert.are.same({"api_A", "api_B"}, names)

    -- Testa buscar a default atual
    assert.are.same("api_A", config.get_current_api())

    -- Testa trocar a API via código
    config.set_selected_api("api_B")
    assert.are.same("api_B", config.get_current_api())

    os.remove(tmp_json)
  end)
end) 

describe("Fase 25 - Configurações do Guardião 2.0:", function()
  local config = require('multi_context.config')

  it("Deve carregar as opções default de Compressao e Modos", function()
    -- Garante reload limpo para pegar defaults
    package.loaded['multi_context.config'] = nil
    config = require('multi_context.config')
    config.options = vim.deepcopy(config.defaults)
    
    assert.is_not_nil(config.options.watchdog, "A tabela watchdog deve existir")
    assert.are.same("off", config.options.watchdog.mode, "O padrao deve ser off para nao assustar o usuario")
    assert.are.same("semantic", config.options.watchdog.strategy, "O padrao deve ser semantic")
    assert.are.same(0.3, config.options.watchdog.percent, "Percentual alvo padrao deve ser 30%")
    assert.are.same(1500, config.options.watchdog.fixed_target, "Alvo fixo padrao deve ser 1500 tokens")
  end)
end)






