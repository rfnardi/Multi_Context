local M = {}
local tools = require('multi_context.ecosystem.tools')
local StateManager = require('multi_context.core.state_manager')
local i18n = require('multi_context.i18n')

local valid_tools = {
    list_files = true, read_file = true, search_code = true,
    edit_file = true, run_shell = true, replace_lines = true, apply_diff = true,
    rewrite_chat_buffer = true, get_diagnostics = true, spawn_swarm = true, switch_agent = true,
    lsp_definition = true, lsp_references = true, lsp_document_symbols = true, git_status = true, git_branch = true, git_commit = true
}

local dangerous_commands = {"rm%s+-rf", "mkfs", "sudo ", ">%s*/dev", "chmod ", "chown "}
local function is_dangerous(cmd)
    if not cmd then return false end
    for _, pat in ipairs(dangerous_commands) do if cmd:match(pat) then return true end end
    return false
end

M.execute = function(tool_data, is_autonomous, approve_all_ref, buf)
    local name = tool_data.name
    local clean_inner = tool_data.inner

    -- ==========================================
    -- HARD BLOCK: Segurança Git (Gatekeeper Autônomo)
    -- ==========================================
    if name == "git_push" or name == "git_reset" or name == "git_rebase" or
       (name == "run_shell" and (clean_inner:match("git push") or clean_inner:match("git reset") or clean_inner:match("git rebase"))) then
        local err_msg = i18n.t("err_git_destructive")
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>\n\n>[Sistema]: ⛔ ERRO - %s', tostring(name), clean_inner, err_msg)
        return out, false, false, nil, nil
    end

    local skills_manager = require('multi_context.ecosystem.skills_manager')
    local custom_skills = skills_manager.get_skills()
    local is_custom_skill = custom_skills[name] ~= nil

    if not valid_tools[name] and not is_custom_skill then
        local err_msg = i18n.t("tool_not_found", tostring(name))
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>\n\n>[Sistema]: ERRO - %s', tostring(name), clean_inner, err_msg)
        return out, false, false, nil, nil
    end

    local agents = require('multi_context.agents').load_agents()
    local active_agent = StateManager.get('react').active_agent
    local is_authorized = false

    if active_agent and agents[active_agent] and agents[active_agent].skills then
        for _, skill in ipairs(agents[active_agent].skills) do
            if skill == name then is_authorized = true; break end
        end
    else
        is_authorized = true 
    end

    if not is_authorized then
        local err_msg = i18n.t("op_denied", tostring(active_agent), tostring(name))
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>\n\n>[Sistema]: ⛔ ERRO - %s', tostring(name), clean_inner, err_msg)
        return out, false, false, nil, nil
    end

    local choice = 1
    if not approve_all_ref.value then
        if is_autonomous then
            if name == "run_shell" and is_dangerous(clean_inner) then
                vim.notify(i18n.t("danger_cmd"), vim.log.levels.ERROR)
                choice = vim.fn.confirm(i18n.t("allow_danger") .. clean_inner, i18n.t("confirm_opts"), 2)
            elseif name == "rewrite_chat_buffer" then
                choice = vim.fn.confirm(i18n.t("allow_rewrite"), i18n.t("confirm_opts"), 1)
            else choice = 3; approve_all_ref.value = true end
        else
            choice = vim.fn.confirm(i18n.t("allow_tool", tostring(name)), i18n.t("confirm_opts"), 1)
        end
    end

    if choice == 3 then approve_all_ref.value = true; choice = 1 end
    if choice == 4 or choice == 0 then
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>', tostring(tool_data.raw_tag), clean_inner)
        return out, true, false, nil, nil
    end

    local result = ""
    local should_continue_loop = false
    local pending_rewrite_content = nil
    local backup_made = nil

    if choice == 2 then
        result = i18n.t("denied_user")
        local out = string.format('<tool_call name="%s">\n%s\n</tool_call>\n\n>[Sistema]: ERRO - %s', tostring(name), clean_inner, result)
        return out, false, false, nil, nil
    end

    if is_custom_skill then
        local args = {}
        if clean_inner then
            for p_name, p_val in clean_inner:gmatch("<([%w_]+)[^>]*>(.-)</%1>") do
                args[p_name] = vim.trim(p_val)
            end
        end
        local ok, skill_res = pcall(custom_skills[name].execute, args)
        if ok then
            result = tostring(skill_res)
            should_continue_loop = true
        else
            result = i18n.t("skill_err") .. tostring(skill_res)
        end
    elseif name == "rewrite_chat_buffer" then
        backup_made = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local backup_file = vim.fn.stdpath("data") .. "/mctx_backup_" .. os.date("%Y%m%d_%H%M%S") .. ".mctx"
        vim.fn.writefile(backup_made, backup_file)
        pending_rewrite_content = clean_inner
        result = i18n.t("buf_rewritten")
    elseif name == "list_files" then 
        should_continue_loop = true; result = tools.list_files()
    elseif name == "read_file" then 
        should_continue_loop = true; result = tools.read_file(tool_data.path)
    elseif name == "search_code" then 
        should_continue_loop = true; result = tools.search_code(tool_data.query)
    elseif name == "edit_file" then 
        result = tools.edit_file(tool_data.path, clean_inner)
        if is_autonomous and result:match("SUCESSO") or result:match("SUCCESS") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "run_shell" then 
        result = tools.run_shell(clean_inner)
    elseif name == "replace_lines" then 
        result = tools.replace_lines(tool_data.path, tool_data.start_line, tool_data.end_line, clean_inner)
        if is_autonomous and result:match("SUCESSO") or result:match("SUCCESS") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "apply_diff" then
        result = tools.apply_diff(tool_data.path, clean_inner)
        if is_autonomous and result:match("SUCESSO") or result:match("SUCCESS") then result = result .. "\n\n[Auto-LSP]:\n" .. tools.get_diagnostics(tool_data.path) end
    elseif name == "git_status" then
        should_continue_loop = true; result = tools.git_status()
    elseif name == "git_branch" then
        local new_branch = (tool_data.inner and tool_data.inner:match("<create_new>true</create_new>")) and true or false
        local branch_name = tool_data.inner and tool_data.inner:match("<branch_name>(.-)</branch_name>") or clean_inner
        should_continue_loop = true; result = tools.git_branch(branch_name, new_branch)
    elseif name == "git_commit" then
        local files_str = tool_data.inner and tool_data.inner:match("<files>(.-)</files>") or ""
        local msg = tool_data.inner and tool_data.inner:match("<message>(.-)</message>") or clean_inner
        should_continue_loop = true; result = tools.git_commit(files_str, msg)
    elseif name == "lsp_definition" then
        should_continue_loop = true; result = require('multi_context.ecosystem.lsp_utils').get_definition(tool_data.path, tool_data.start_line, clean_inner)
    elseif name == "lsp_references" then
        should_continue_loop = true; result = require('multi_context.ecosystem.lsp_utils').get_references(tool_data.path, tool_data.start_line, clean_inner)
    elseif name == "lsp_document_symbols" then
        should_continue_loop = true; result = require('multi_context.ecosystem.lsp_utils').get_document_symbols(tool_data.path)
    elseif name == "get_diagnostics" then 
        should_continue_loop = true; result = tools.get_diagnostics(tool_data.path)
    elseif name == "spawn_swarm" then
        local swarm = require('multi_context.core.swarm_manager')
        if swarm.init_swarm(clean_inner) then
            swarm.on_swarm_complete = require('multi_context').OnSwarmComplete
            vim.defer_fn(function() swarm.dispatch_next() end, 100)
            result = i18n.t("swarm_started")
            should_continue_loop = false
        else
            result = i18n.t("swarm_err_json")
        end
    elseif name == "switch_agent" then
        local target = clean_inner:match("<target_agent>(.-)</target_agent>")
        if not target then target = clean_inner:match("([%w_]+)") end
        if target then target = vim.trim(target) else target = "" end
        result = "SWITCH_AGENT_REQUEST:" .. target
        should_continue_loop = true
    end

    local output = ""
    if not pending_rewrite_content then
        output = string.format('<tool_call name="%s" path="%s">\n%s\n</tool_call>\n\n>[Sistema]: Resultado:\n```text\n%s\n```', tostring(name), tostring(tool_data.path or ""), clean_inner, result)
    end

    return output, false, should_continue_loop, pending_rewrite_content, backup_made
end

return M
