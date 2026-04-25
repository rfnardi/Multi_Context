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






