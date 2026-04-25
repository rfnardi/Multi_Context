-- lua/multi_context/tests/api_handlers_spec.lua
-- transport.lua carrega normalmente em headless nvim.
-- O único mock necessário é vim.fn.jobstart, chamado em runtime.
local handlers = require('multi_context.api_handlers')

describe("API Handlers Module (Prompt Caching)", function()
    local original_jobstart
    local intercepted_cmd
    local intercepted_opts
    local payload_content

    before_each(function()
        intercepted_cmd  = nil
        intercepted_opts = nil
        payload_content  = nil

        original_jobstart = vim.fn.jobstart
        vim.fn.jobstart = function(cmd, opts)
            intercepted_cmd  = cmd
            intercepted_opts = opts
            for _, arg in ipairs(cmd) do
                if type(arg) == "string" and arg:match("^@") then
                    local f = io.open(arg:sub(2), "r")
                    if f then payload_content = f:read("*a"); f:close() end
                end
            end
            return 1
        end
    end)

    after_each(function()
        vim.fn.jobstart = original_jobstart
    end)

    it("Deve incluir stream_options e extrair metricas de cache (OpenAI / DeepSeek)", function()
        local callback_metrics
        local callback_done = false

        handlers.openai.make_request(
            { name = "ds", url = "http://ds", model = "deepseek-coder",
              headers = { ["Content-Type"] = "application/json" } },
            { { role = "user", content = "hello" } },
            { ds = "key123" },
            nil,
            function(chunk, err, done, metrics)
                if done then callback_done = true; callback_metrics = metrics end
            end
        )

        local parsed_payload = vim.fn.json_decode(payload_content)
        assert.is_not_nil(parsed_payload.stream_options)
        assert.is_true(parsed_payload.stream_options.include_usage)

        intercepted_opts.on_stdout(1, {
            'data: {"choices":[{"delta":{"content":""}}],"usage":{"prompt_cache_hit_tokens":1280}}'
        })
        intercepted_opts.on_exit(1, 0)

        assert.is_true(callback_done)
        assert.is_not_nil(callback_metrics)
        assert.are.same(1280, callback_metrics.cache_read_input_tokens)
    end)

    it("Deve estruturar o payload Anthropic com cache_control e capturar os metadados", function()
        local callback_metrics

        handlers.anthropic.make_request(
            { name = "claude", url = "http://claude", model = "claude-3.5",
              headers = { ["Content-Type"] = "application/json" } },
            {
                { role = "system", content = "Você é um assistente dev." },
                { role = "user",   content = "hello" },
            },
            { claude = "key123" },
            nil,
            function(chunk, err, done, metrics)
                if done then callback_metrics = metrics end
            end
        )

        local has_beta_header = false
        for _, v in ipairs(intercepted_cmd) do
            if type(v) == "string" and v:match("anthropic%-beta: prompt%-caching") then
                has_beta_header = true
            end
        end
        assert.is_true(has_beta_header)

        local parsed_payload = vim.fn.json_decode(payload_content)
        assert.is_not_nil(parsed_payload.system)
        assert.are.same("Você é um assistente dev.", parsed_payload.system[1].text)
        assert.are.same("ephemeral", parsed_payload.system[1].cache_control.type)

        intercepted_opts.on_stdout(1, {
            'data: {"type":"message_start","message":{"usage":{"cache_read_input_tokens":4048}}}'
        })
        intercepted_opts.on_exit(1, 0)

        assert.is_not_nil(callback_metrics)
        assert.are.same(4048, callback_metrics.cache_read_input_tokens)
    end)
end)






