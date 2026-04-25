local M = {}
M.state = { ema = 0, count = 0 }

M.reset = function() M.state.ema = 0; M.state.count = 0 end

M.add_turn = function(tokens)
    if M.state.count == 0 then M.state.ema = tokens
    else M.state.ema = math.floor((tokens * 0.3) + (M.state.ema * 0.7)) end
    M.state.count = M.state.count + 1
end

M.get_ema = function() return M.state.ema end

-- BUG 2 CORRIGIDO: Apenas buffer + ema. O prompt colado pelo user já está no buffer.
M.predict_next_total = function(current_tokens)
    return current_tokens + M.state.ema
end

-- BUG 1 CORRIGIDO: Imunidade do Primeiro Turno
M.is_immune = function()
    -- Se o tracker tem menos de 2 turnos gravados, estamos na aurora do chat. Bloqueio total.
    return M.state.count < 2
end

return M






