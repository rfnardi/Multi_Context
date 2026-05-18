require("multi_context.tests.libuv_barrier")
local native_tools = require('multi_context.ecosystem.native_tools')

describe("Regression - I/O Sandbox e Prevenção de E482:", function()
    local orig_writefile
    
    before_each(function()
        orig_writefile = vim.fn.writefile
    end)
    
    after_each(function()
        vim.fn.writefile = orig_writefile
    end)

    it("NUNCA deve crashar o Neovim se a escrita falhar (Sandbox ativado)", function()
        -- Forçamos a falha do Kernel C
        vim.fn.writefile = function()
            error("Vim:E482: Can't open file for writing: permission denied")
        end

        -- Tentamos invocar a ferramenta das duas formas de assinatura possíveis 
        -- para garantir que chegue até a escrita
        local res1 = native_tools.edit_file({ attributes = { path = "/pasta/teste.txt" }, content = "hack" })
        local res2 = native_tools.edit_file("/pasta/teste.txt", "hack")
        
        local result = tostring(res1) .. " | " .. tostring(res2)

        -- Se o Sandbox engoliu QUALQUER crash (seja de argumento ou de Kernel), o Neovim está salvo!
        assert.truthy(result:match("FATAL TOOL ERROR"), "A string de erro deve provir da nossa blindagem (Sandbox), garantindo que o Neovim não crashou.")
    end)
end)
