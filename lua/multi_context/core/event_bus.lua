local M = {}

-- Estado interno do Bus: Dicionário onde a chave é o nome do evento
-- e o valor é uma lista de callbacks (funções).
local listeners = {}

M.on = function(event_name, callback)
    if type(callback) ~= "function" then return end
    if not listeners[event_name] then listeners[event_name] = {} end
    table.insert(listeners[event_name], callback)
end

M.once = function(event_name, callback)
    if type(callback) ~= "function" then return end
    local wrapper
    wrapper = function(payload)
        M.off(event_name, wrapper)
        callback(payload)
    end
    M.on(event_name, wrapper)
end

M.off = function(event_name, callback)
    if not listeners[event_name] then return end
    for i, cb in ipairs(listeners[event_name]) do
        if cb == callback then
            table.remove(listeners[event_name], i)
            break
        end
    end
end

M.emit = function(event_name, payload)
    if not listeners[event_name] then return end
    
    -- Criamos uma cópia local da lista de callbacks.
    -- Isso é crucial para evitar bugs caso um evento remova 
    -- a si mesmo (como no caso do 'once') durante a iteração.
    local cbs = {}
    for _, cb in ipairs(listeners[event_name]) do 
        table.insert(cbs, cb) 
    end
    
    for _, cb in ipairs(cbs) do
        -- Executa envolto em pcall para que um listener quebrado
        -- não trave toda a cadeia de execução do sistema.
        pcall(cb, payload)
    end
end

M.clear = function()
    listeners = {}
end

return M
