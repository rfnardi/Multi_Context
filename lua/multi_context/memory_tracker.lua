local M = {}
M.state = { ema = 0, count = 0 }

M.reset = function() M.state.ema = 0; M.state.count = 0 end

M.add_turn = function(tokens)
    if M.state.count == 0 then M.state.ema = tokens
    else M.state.ema = math.floor((tokens * 0.3) + (M.state.ema * 0.7)) end
    M.state.count = M.state.count + 1
end

M.get_ema = function() return M.state.ema end

M.predict_next_total = function(current_tokens, prompt_tokens)
    return current_tokens + prompt_tokens + M.state.ema
end

return M
