#!/usr/bin/env bash
set -e

# ── transport.lua ──────────────────────────────────────────────────────────────
cat > lua/multi_context/transport.lua << 'EOF'
-- lua/multi_context/transport.lua
local M = {}

_G.MultiContextTempFiles = _G.MultiContextTempFiles or {}

local function decode_json_string(s)
    s = s:gsub("\\n", "\n"):gsub("\\t", "\t"):gsub("\\r", "\r"):gsub('\\"', '"')
    s = s:gsub("\\u(%x%x%x%x)", function(hex) return vim.fn.nr2char(tonumber(hex, 16)) end)
    return s:gsub("\\\\", "\\")
end

local function extract_text_chunks(buffer)
    local results = {}; local remaining = buffer
    while true do
        local pos_start, pos_end = remaining:find('"text"%s*:%s*"')
        if not pos_start then break end
        local str_start = pos_end + 1
        local str_end = nil; local i = str_start
        while i <= #remaining do
            local ch = remaining:sub(i, i)
            if ch == '\\' then i = i + 2
            elseif ch == '"' then str_end = i; break
            else i = i + 1 end
        end
        if not str_end then break end
        local inner_str = remaining:sub(str_start, str_end - 1)
        local ok, decoded = pcall(vim.fn.json_decode, '"' .. inner_str .. '"')
        if ok and type(decoded) == "string" then table.insert(results, decoded)
        else table.insert(results, decode_json_string(inner_str)) end
        remaining = remaining:sub(str_end + 1)
    end
    return results, remaining
end

local function build_curl_cmd(api_config, api_key, tmp_file, stream)
    local cmd = { "curl", "-s", "-L", "-X", "POST" }
    if stream then table.insert(cmd, "-N") end
    local url = api_config.url
    if api_config.api_type == "gemini" and stream then
        url = url:gsub(":generateContent", ":streamGenerateContent") .. "?key=" .. api_key
    end
    table.insert(cmd, url)
    for k, v in pairs(api_config.headers or {}) do
        table.insert(cmd, "-H")
        table.insert(cmd, k .. ": " .. v:gsub("{API_KEY}", api_key))
    end
    table.insert(cmd, "-d")
    table.insert(cmd, "@" .. tmp_file)
    return cmd
end

local function write_payload_to_tmp(payload)
    local tmp_file = os.tmpname()
    table.insert(_G.MultiContextTempFiles, tmp_file)
    local f = io.open(tmp_file, "w")
    if f then f:write(vim.fn.json_encode(payload)); f:close() end
    return tmp_file
end

M.run_http_stream = function(cmd, tmp_file, process_stdout, extract_error, callback)
    local full_response = ""
    local context = { buffer = "", metrics = nil }
    local job_id = vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            if not data then return end
            for _, line in ipairs(data) do full_response = full_response .. line .. "\n" end
            if process_stdout then process_stdout(data, context, callback) end
        end,
        on_exit = function()
            pcall(os.remove, tmp_file)
            local err_msg = extract_error(full_response, context, callback)
            if err_msg then callback("\n\n" .. err_msg .. "\n", nil, false) end
            callback(nil, nil, true, context.metrics)
        end
    })
    callback(nil, nil, false, nil, job_id)
end

M.extract_text_chunks = extract_text_chunks
M.write_payload_to_tmp = write_payload_to_tmp
M.build_curl_cmd = build_curl_cmd

return M
EOF

echo "✅ transport.lua reescrito com quebras de linha"

# ── api_handlers.lua ───────────────────────────────────────────────────────────
cat > lua/multi_context/api_handlers.lua << 'EOF'
-- lua/multi_context/api_handlers.lua
local M = {}
local transport = require('multi_context.transport')

M.gemini = {
    make_request = function(api_config, messages, api_keys, _, callback)
        local api_key = api_keys[api_config.name] or ""
        if api_key == "" then
            callback("\n[ERRO]: Chave não encontrada.", nil, false)
            callback(nil, nil, true)
            return
        end
        local contents = {}; local system_instruction = nil
        for _, msg in ipairs(messages) do
            if msg.role == "system" then
                system_instruction = { parts = { { text = msg.content } } }
            else
                table.insert(contents, {
                    role = (msg.role == "user") and "user" or "model",
                    parts = { { text = msg.content } }
                })
            end
        end
        local payload = { contents = contents }
        if system_instruction then payload.systemInstruction = system_instruction end
        local tmp_file = transport.write_payload_to_tmp(payload)
        local cmd = transport.build_curl_cmd(api_config, api_key, tmp_file, true)
        transport.run_http_stream(cmd, tmp_file,
            function(data, ctx, cb)
                ctx.buffer = ctx.buffer .. table.concat(data, "\n")
                local chunks, rest = transport.extract_text_chunks(ctx.buffer)
                for _, txt in ipairs(chunks) do cb(txt, nil, false) end
                ctx.buffer = rest
            end,
            function(full_res)
                if full_res:match('"error"') then
                    local ok, dec = pcall(vim.fn.json_decode, full_res)
                    if ok and dec.error and dec.error.message then
                        return "**[ERRO GEMINI]:** " .. dec.error.message
                    end
                end
            end,
            callback)
    end
}

M.openai = {
    make_request = function(api_config, messages, api_keys, _, callback)
        local api_key = api_keys[api_config.name] or ""
        local payload = {
            model = api_config.model,
            messages = messages,
            stream = true,
            stream_options = { include_usage = true }
        }
        local tmp_file = transport.write_payload_to_tmp(payload)
        local cmd = transport.build_curl_cmd(api_config, api_key, tmp_file, true)
        transport.run_http_stream(cmd, tmp_file,
            function(data, ctx, cb)
                for _, line in ipairs(data) do
                    if line:match("^data: ") and not line:match("%[DONE%]") then
                        local ok, dec = pcall(vim.fn.json_decode, line:sub(7))
                        if ok then
                            if dec.choices and dec.choices[1] and dec.choices[1].delta
                                and type(dec.choices[1].delta.content) == "string" then
                                cb(dec.choices[1].delta.content, nil, false)
                            end
                            if type(dec.usage) == "table" then
                                ctx.metrics = ctx.metrics or {}
                                ctx.metrics.cache_read_input_tokens =
                                    (type(dec.usage.prompt_tokens_details) == "table"
                                        and dec.usage.prompt_tokens_details.cached_tokens)
                                    or dec.usage.prompt_cache_hit_tokens or 0
                            end
                        end
                    end
                end
            end,
            function(full_res)
                if full_res:match('"error"') and not full_res:match('"content"') then
                    local ok, dec = pcall(vim.fn.json_decode, full_res)
                    if ok and dec.error and dec.error.message then
                        return "**[ERRO OPENAI]:** " .. dec.error.message
                    end
                end
            end,
            callback)
    end
}

M.anthropic = {
    make_request = function(api_config, messages, api_keys, _, callback)
        local api_key = api_keys[api_config.name] or ""
        local system_text = ""; local anthropic_msgs = {}
        for _, msg in ipairs(messages) do
            if msg.role == "system" then
                system_text = system_text .. msg.content .. "\n"
            else
                table.insert(anthropic_msgs, { role = msg.role, content = msg.content })
            end
        end
        local payload = {
            model = api_config.model,
            messages = anthropic_msgs,
            system = { {
                type = "text",
                text = vim.trim(system_text),
                cache_control = { type = "ephemeral" }
            } },
            stream = true,
            max_tokens = 4096
        }
        local tmp_file = transport.write_payload_to_tmp(payload)
        local cmd = transport.build_curl_cmd(api_config, api_key, tmp_file, true)
        table.insert(cmd, "-H"); table.insert(cmd, "anthropic-version: 2023-06-01")
        table.insert(cmd, "-H"); table.insert(cmd, "anthropic-beta: prompt-caching-2024-07-31")
        transport.run_http_stream(cmd, tmp_file,
            function(data, ctx, cb)
                for _, line in ipairs(data) do
                    if line:match("^data: ") then
                        local ok, dec = pcall(vim.fn.json_decode, line:sub(7))
                        if ok then
                            if dec.type == "content_block_delta" and dec.delta and dec.delta.text then
                                cb(dec.delta.text, nil, false)
                            elseif dec.type == "message_start"
                                and type(dec.message) == "table"
                                and type(dec.message.usage) == "table" then
                                ctx.metrics = ctx.metrics or {}
                                ctx.metrics.cache_read_input_tokens =
                                    dec.message.usage.cache_read_input_tokens or 0
                            end
                        end
                    end
                end
            end,
            function(full_res)
                if full_res:match('"error"') and not full_res:match('"type": "message_start"') then
                    local ok, dec = pcall(vim.fn.json_decode, full_res)
                    if ok and dec.error and dec.error.message then
                        return "**[ERRO ANTHROPIC]:** " .. dec.error.message
                    end
                end
            end,
            callback)
    end
}

M.cloudflare = {
    make_request = function(api_config, messages, api_keys, _, callback)
        local api_key = api_keys[api_config.name] or ""
        local tmp_file = transport.write_payload_to_tmp({ messages = messages })
        if not api_config.headers then api_config.headers = {} end
        if not api_config.headers["Authorization"] then
            api_config.headers["Authorization"] = "Bearer {API_KEY}"
        end
        local cmd = transport.build_curl_cmd(api_config, api_key, tmp_file, false)
        transport.run_http_stream(cmd, tmp_file,
            function(data, ctx)
                ctx.buffer = ctx.buffer .. table.concat(data, "\n")
            end,
            function(full_res, ctx, cb)
                local ok, dec = pcall(vim.fn.json_decode, ctx.buffer)
                if ok and dec and dec.result and dec.result.response then
                    cb(dec.result.response, nil, false)
                elseif ctx.buffer:match('"errors"') then
                    return "**[ERRO CLOUDFLARE]:** Falha na API"
                end
            end,
            callback)
    end
}

return M
EOF

echo "✅ api_handlers.lua reescrito com quebras de linha"

# ── Verifica que os módulos agora carregam corretamente ────────────────────────
echo ""
echo "=== Verificando carregamento ==="
nvim --headless \
  -c "set runtimepath+=." \
  -c "lua require('multi_context.config').setup({user_name='test'})" \
  -c "lua local ok,r = pcall(require,'multi_context.transport');    print('transport    → ok:'..tostring(ok)..' type:'..type(r))" \
  -c "lua local ok,r = pcall(require,'multi_context.api_handlers'); print('api_handlers → ok:'..tostring(ok)..' type:'..type(r))" \
  -c "quit" 2>&1
