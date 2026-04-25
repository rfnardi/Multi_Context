local tools = require('multi_context.tools')

describe("Tools Module (Unified Diff):", function()
    local tmp_file = os.tmpname()

    after_each(function()
        os.remove(tmp_file)
        -- Limpa possíveis resíduos gerados pelo binário 'patch' (.rej ou .orig)
        os.remove(tmp_file .. ".orig")
        os.remove(tmp_file .. ".rej")
    end)

    it("Deve aplicar um Unified Diff a um arquivo (apply_diff)", function()
        tools.edit_file(tmp_file, "L1\nL2\nL3")
        
        -- Diff Unificado simulando alteração da L2 para L2_Nova
        local patch_content = [[
--- a/arquivo
+++ b/arquivo
@@ -1,3 +1,3 @@
 L1
-L2
+L2_Nova
 L3
]]
        
        local res = tools.apply_diff(tmp_file, patch_content)
        assert.truthy(res:match("SUCESSO"), "Deveria retornar SUCESSO ao aplicar diff válido")
        
        local lines = vim.fn.readfile(tmp_file)
        assert.are.same({"L1", "L2_Nova", "L3"}, lines)
    end)

    it("Deve lidar com falhas graciosamente (patch rejeitado)", function()
        tools.edit_file(tmp_file, "Arquivo totalmente diferente\nSem nada a ver")
        
        local patch_content = [[
--- a/arquivo
+++ b/arquivo
@@ -1,3 +1,3 @@
 L1
-L2
+L2_Nova
 L3
]]
        local res = tools.apply_diff(tmp_file, patch_content)
        assert.truthy(res:match("FALHA") or res:match("ERRO"), "Deveria retornar FALHA/ERRO se o patch for rejeitado por contexto inválido")
    end)
end)






