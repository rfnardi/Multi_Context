#!/bin/bash

echo "======================================================================"
echo "🛡️  Adicionando Novos Testes de Regressão (Proteção Anti-Bugs)"
echo "======================================================================"

cat << 'EOF' > add_tests.lua
local path = "lua/multi_context/tests/regression_spec.lua"
local f = io.open(path, "rb")
if not f then print("Erro: Arquivo não encontrado."); os.exit(1) end
local content = f:read("*a")
f:close()

local new_tests = [[

    it('Bug 9: Swarm Manager deve desembrulhar JSON aninhado em json_payload (Alucinacao LLM)', function()
        local swarm = require('multi_context.core.swarm_manager')
        -- Simulando exatamente o erro cometido pelo LLM
        local fake_json = '{"json_payload": "{\\"tasks\\": [{\\"agent\\": \\"coder\\", \\"instruction\\": \\"teste\\"}]}"}'
        
        local ok, err = swarm.init_swarm(fake_json)
        
        assert.is_true(ok)
        assert.are.equal(1, #swarm.state.queue)
        assert.are.equal("coder", swarm.state.queue[1].agent)
    end)

    it('Bug 10: Tool Parser deve ignorar fechamentos de tag in-line (Injecao XML)', function()
        local parser = require('multi_context.ecosystem.tool_parser')
        -- Simulando a IA citando uma tag </tool_call> in-line no meio da instrução
        local payload = "<tool_call name=\"spawn_swarm\">\n{\"instruction\": \"Tem um </tool_call> in-line aqui.\"}\n</tool_call>"
        
        local res = parser.parse_next_tool(payload, 1)
        
        assert.is_not_nil(res)
        assert.is_false(res.is_invalid)
        assert.are.equal("spawn_swarm", res.name)
        assert.truthy(res.inner:match("in%-line aqui"))
    end)

    it('Bug 11: Utils deve gerar datas validas no cabecalho mctx_session (Nao literal Y-m-d)', function()
        local utils = require('multi_context.utils.utils')
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"## User >> hello"})
        
        local name, buf_content = utils.build_workspace_content(buf, nil)
        local created = buf_content:match('created="([^"]+)"')
        
        assert.is_not_nil(created)
        -- Garante que o desenvolvedor do futuro não reverta para 'Y-m-d'
        assert.is_nil(created:match("Y%%-m%%-d"))
        -- Garante que a data está no padrão real numérico ISO
        assert.truthy(created:match("%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d"))
        
        vim.api.nvim_buf_delete(buf, {force=true})
    end)

    it('Bug 12: Transport deve usar offload de arquivo no curl ao inves de chansend (Anti-Freeze)', function()
        local transport = require('multi_context.llm.transport')
        -- Simulando a criacao de comando com payload persistido no disco
        local cmd = transport.build_curl_cmd({url="http", api_type="openai"}, "key", "/tmp/fake.json", true)
        
        local has_at_file = false
        for _, v in ipairs(cmd) do
            if v == "@/tmp/fake.json" then has_at_file = true end
        end
        
        -- Garante que o Curl será lido do HD (@arquivo) para evitar congelamento de UI
        assert.is_true(has_at_file)
    end)
]]

-- Procura a última ocorrência de 'end)' no arquivo de testes para injetar o código de forma limpa
local insert_pos = content:match(".*()%s*end%)%s*$")
if insert_pos then
    local before = content:sub(1, insert_pos - 1)
    local after = content:sub(insert_pos)
    
    local new_content = before .. new_tests .. after
    
    local out = io.open(path, "wb")
    out:write(new_content)
    out:close()
    print("✅ Os 4 testes de regressão foram injetados perfeitamente no regression_spec.lua!")
else
    print("❌ Não foi possível encontrar o ponto de injeção no final do arquivo.")
end
EOF

# Executa
nvim -l add_tests.lua
rm add_tests.lua

echo ""
echo "🚀 PRONTO! Você agora possui novos Guardiões Automatizados de Código."
echo "Rode o 'make test_agregate_results' e observe a contagem total de testes subir de 273 para 277!"
