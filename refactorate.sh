#!/bin/bash
echo "⚙️ Removendo a leitura fantasma duplicada em transport.lua..."

cat << 'EOF' > patch6.lua
local file = "lua/multi_context/llm/transport.lua"
local f = io.open(file, "r")
if not f then return end
local content = f:read("*a")
f:close()

-- Procura e destrói o segundo bloco idêntico que está zumbizando o payload
local pattern = "pcall%(os%.remove, tmp_file%)\n%s*end\n%s*local payload_str = \"\"\n%s*if tmp_file and vim%.fn%.filereadable%(tmp_file%) == 1 then\n%s*payload_str = table%.concat%(vim%.fn%.readfile%(tmp_file%), \"\\n\"%)\n%s*pcall%(os%.remove, tmp_file%)\n%s*end"

local u1, count = content:gsub(pattern, "pcall(os.remove, tmp_file)\n    end")

if count > 0 then
    f = io.open(file, "w")
    f:write(u1)
    f:close()
    print("✅ Leitura fantasma destruída!")
else
    print("⚠️ Nenhuma duplicação encontrada. O arquivo já estava limpo?")
end
EOF

nvim -l patch6.lua
rm patch6.lua
echo "✅ Pronto! Pode rodar 'make test_agregate_results' para a vitória."
