-- lua/multi_context/api_handlers.lua
local M = {}
local transport = require('multi_context.llm.transport')

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






