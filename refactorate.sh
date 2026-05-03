#!/bin/bash

# Injeta chaves no i18n
python3 -c "
import re

file_path = 'lua/multi_context/i18n.lua'
with open(file_path, 'r') as f: content = f.read()

en_add = '''
        cc_semantic_skills_title = \"[6] SEMANTIC SKILLS\",
        cc_semantic_skills_desc = \"(Agent behaviors grouping multiple system tools)\",
        cc_system_tools_title = \"[7] SYSTEM TOOLS (MCP)\",
        cc_system_tools_desc = \"(Raw binary tools and scripts available in the system)\",
        cc_edit_skill_purpose = \"      ├─ [ Edit Skill Guardrails ]\",
        cc_delete_skill = \"      └─ [ Delete Skill ]\",
        cc_create_semantic_skill = \"    └─ [ + Create New Semantic Skill ]\",
        cc_create_semantic_skill_pmpt = \"New Semantic Skill name: \",
        cc_semantic_skill_created = \"Semantic Skill '%s' created!\",
        cc_system_tools_hint = \"    (Press 'e' on a tool to edit its code)\",
        cc_create_tool = \"    └─ [ + Create New System Tool ]\",
        cc_delete_skill_prompt = \"Do you want to DELETE skill '%s'?\",'''

pt_add = '''
        cc_semantic_skills_title = \"[6] SKILLS SEMÂNTICAS\",
        cc_semantic_skills_desc = \"(Comportamentos dos agentes agrupando múltiplas ferramentas do sistema)\",
        cc_system_tools_title = \"[7] FERRAMENTAS DO SISTEMA (MCP)\",
        cc_system_tools_desc = \"(Ferramentas binárias brutas e scripts disponíveis no sistema)\",
        cc_edit_skill_purpose = \"      ├─ [ Editar Guardrails da Skill ]\",
        cc_delete_skill = \"      └─ [ Deletar Skill ]\",
        cc_create_semantic_skill = \"    └─ [ + Criar Nova Skill Semântica ]\",
        cc_create_semantic_skill_pmpt = \"Nome da nova Skill Semântica: \",
        cc_semantic_skill_created = \"Skill Semântica '%s' criada!\",
        cc_system_tools_hint = \"    (Aperte 'e' sobre uma ferramenta para editar seu código)\",
        cc_create_tool = \"    └─ [ + Criar Nova Ferramenta de Sistema ]\",
        cc_delete_skill_prompt = \"Deseja DELETAR a skill '%s'?\",'''

content = re.sub(r'(cc_gatekeeper_desc = \"\(Fine-grained control of agent capabilities\)\",)', r'\1' + en_add, content, count=1)
content = re.sub(r'(cc_gatekeeper_desc = \"\(Controle fino de permissões e capacidades por agente\)\",)', r'\1' + pt_add, content, count=1)

with open(file_path, 'w') as f: f.write(content)
"

# Reescreve o controls_view.lua inteiro com a nova arquitetura
cat << 'LUA_EOF' > lua/multi_context/ui/controls_view.lua
local config = require('multi_context.config')
local i18n = require('multi_context.i18n')
local api = vim.api

local M = {}

M.state = {
    sections = {},
    apis = {}, default_api = "", fallback_mode = true,
    watchdog = {}, horizon = 4000, tolerance = 1.0,
    identity = "User", max_loops = 15,
    agents = {}, expanded_agents = {},
    semantic_skills = {}, expanded_semantic_skills = {},
    all_tools = {}, all_injectors = {}, squads = {},
    appearance = {}, history_files = {},
    api_keys_status = {}, master_prompt = "",
    debug_mode = false, clipboard_api = nil
}

M.line_map = {}
M.buf = nil; M.win = nil

M.reset_state = function()
    if M.state and M.state.sections then
        for _, s in ipairs(M.state.sections) do s.expanded = false end
    end
    M.state.expanded_agents = {}
    M.state.expanded_semantic_skills = {}
end

M.init_state = function()
    M.reset_state()
    M.state.sections = {
        { id = "apis", title = i18n.t("cc_apis_title"), desc = i18n.t("cc_apis_desc"), expanded = false },
        { id = "swarm", title = i18n.t("cc_swarm_title"), desc = i18n.t("cc_swarm_desc"), expanded = false },
        { id = "watchdog", title = i18n.t("cc_watchdog_title"), desc = i18n.t("cc_watchdog_desc"), expanded = false },
        { id = "limits", title = i18n.t("cc_limits_title"), desc = i18n.t("cc_limits_desc"), expanded = false },
        { id = "gatekeeper", title = i18n.t("cc_gatekeeper_title"), desc = i18n.t("cc_gatekeeper_desc"), expanded = false },
        { id = "semantic_skills", title = i18n.t("cc_semantic_skills_title"), desc = i18n.t("cc_semantic_skills_desc"), expanded = false },
        { id = "system_tools", title = i18n.t("cc_system_tools_title"), desc = i18n.t("cc_system_tools_desc"), expanded = false },
        { id = "injectors", title = i18n.t("cc_injectors_title"), desc = i18n.t("cc_injectors_desc"), expanded = false },
        { id = "squads", title = i18n.t("cc_squads_title"), desc = i18n.t("cc_squads_desc"), expanded = false },
        { id = "appearance", title = i18n.t("cc_app_title"), desc = i18n.t("cc_app_desc"), expanded = false },
        { id = "history", title = i18n.t("cc_history_title"), desc = i18n.t("cc_history_desc"), expanded = false },
        { id = "vault", title = i18n.t("cc_vault_title"), desc = i18n.t("cc_vault_desc"), expanded = false },
        { id = "telemetry", title = i18n.t("cc_telemetry_title"), desc = i18n.t("cc_telemetry_desc"), expanded = false }
    }
    
    local cfg = config.load_api_config() or { apis = {} }
    M.state.apis = vim.deepcopy(cfg.apis)
    M.state.default_api = cfg.default_api or ""
    M.state.fallback_mode = cfg.fallback_mode ~= false

    M.state.watchdog = vim.deepcopy(config.options.watchdog or {})
    M.state.horizon = config.options.cognitive_horizon or 4000
    M.state.tolerance = config.options.user_tolerance or 1.0
    M.state.identity = config.options.user_name or "User"
    M.state.max_loops = 15
    M.state.appearance = vim.deepcopy(config.options.appearance or { width = 0.8, height = 0.8, border = "rounded" })
    M.state.debug_mode = config.options.debug_mode == true

    local agents = require('multi_context.agents')
    M.state.agents = agents.load_agents() or {}
    
    local ontology = require('multi_context.ecosystem.skills_ontology')
    pcall(function() M.state.semantic_skills = ontology.load_semantic_skills() or {} end)

    local skills_mgr = require('multi_context.ecosystem.skills_manager')
    pcall(skills_mgr.load_skills)
    M.state.all_tools = skills_mgr.get_skills() or {}
    
    local native_tools = {"list_files", "read_file", "search_code", "edit_file", "run_shell", "replace_lines", "apply_diff", "rewrite_chat_buffer", "get_diagnostics", "spawn_swarm", "switch_agent", "lsp_definition", "lsp_references", "lsp_document_symbols", "git_status", "git_branch", "git_commit"}
    for _, t in ipairs(native_tools) do M.state.all_tools[t] = { name = t, is_native = true } end
    
    local injectors_mgr = require('multi_context.ecosystem.injectors')
    M.state.all_injectors = injectors_mgr.get_all_injectors() or {}
    for _, inj in ipairs(injectors_mgr.get_native_injectors()) do
        if M.state.all_injectors[inj.name] then M.state.all_injectors[inj.name].is_native = true end
    end
    
    local squads_mgr = require('multi_context.ecosystem.squads')
    pcall(function() M.state.squads = squads_mgr.load_squads() or {} end)
    
    local root = vim.fn.system("git rev-parse --show-toplevel")
    if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
    local chat_dir = root .. "/.mctx_chats"
    M.state.history_files = {}
    if vim.fn.isdirectory(chat_dir) == 1 then
        local files = vim.fn.split(vim.fn.system("ls -1t " .. vim.fn.shellescape(chat_dir)), "\n")
        for i, f in ipairs(files) do
            if i > 10 then break end
            if f:match("%.mctx$") then table.insert(M.state.history_files, f) end
        end
    end

    M.state.api_keys_status = {}
    local keys = config.load_api_keys() or {}
    for _, api_cfg in ipairs(M.state.apis) do
        local k = keys[api_cfg.name]
        if k and k ~= "" and not k:match("^sk%-%.%.%.") and not k:match("^AIzaSy%.%.%.") and not k:match("^sk%-ant%-%.%.%.") then
            M.state.api_keys_status[api_cfg.name] = i18n.t("cc_configured")
        else
            M.state.api_keys_status[api_cfg.name] = i18n.t("cc_missing")
        end
    end
    M.state.master_prompt = cfg.master_prompt or config.options.master_prompt or "Você é um Engenheiro de Software Autônomo no Neovim."
end

M.toggle_section = function(idx)
    if M.state.sections[idx] then M.state.sections[idx].expanded = not M.state.sections[idx].expanded end
end

M.get_footer_hint = function(action)
    if not action then return i18n.t("cc_hint_default") end
    local t = action.type
    if t == "section" or t == "agent_expand" or t == "semantic_skill_expand" then return i18n.t("cc_hint_expand") end
    if t == "toggle_fallback" or t == "api_spawn" or t == "agent_skill_toggle" or t == "semantic_skill_tool_toggle" or t == "api_select" or t == "wd_mode" or t == "wd_strategy" or t == "toggle_debug" or t == "api_level_swarm" or t == "app_border" then
        return i18n.t("cc_hint_toggle")
    end
    if t == "wd_horizon" or t == "wd_tolerance" or t == "wd_percent" or t == "wd_fixed" or t == "limit_identity" or t == "limit_loops" or t == "agent_level" or t == "app_width" or t == "app_height" or t == "edit_master_prompt" then
        return i18n.t("cc_hint_edit_val")
    end
    if t == "edit_tool" or t == "edit_injector" or t == "edit_squad" or t == "edit_vault" then 
        return i18n.t("cc_hint_edit_src") 
    end
    if t == "create_agent" or t == "create_tool" or t == "create_semantic_skill" or t == "create_injector" or t == "create_squad" or t == "load_history" or t == "edit_agent_prompt" or t == "delete_agent" or t == "edit_semantic_skill_prompt" or t == "delete_semantic_skill" then 
        return i18n.t("cc_hint_cr") 
    end
    return i18n.t("cc_hint_default")
end

M.update_footer = function(cursor_line)
    if not M.win or not api.nvim_win_is_valid(M.win) then return end
    local action = M.line_map[cursor_line]
    local hint = M.get_footer_hint(action)
    
    if vim.fn.has("nvim-0.10") == 1 then
        pcall(api.nvim_win_set_config, M.win, { footer = " " .. vim.trim(hint) .. " ", footer_pos = "center" })
    else
        vim.bo[M.buf].modifiable = true
        local last = api.nvim_buf_line_count(M.buf)
        api.nvim_buf_set_lines(M.buf, last - 1, last, false, { hint })
        vim.bo[M.buf].modifiable = false
    end
end

local function format_row(label, value, total_width)
    local label_len = vim.fn.strdisplaywidth(label)
    local value_len = vim.fn.strdisplaywidth(value)
    local dots_len = total_width - label_len - value_len - 2
    if dots_len < 1 then dots_len = 1 end
    return label .. " " .. string.rep("·", dots_len) .. " " .. value
end

local function add_line(lines, text, action) table.insert(lines, text); if action then M.line_map[#lines] = action end end

M.render = function()
    M.line_map = {}
    local lines = {}
    local w = 62

    add_line(lines, "", nil)

    for s_idx, sec in ipairs(M.state.sections) do
        local prefix = sec.expanded and "[-] " or "[+] "
        add_line(lines, prefix .. (sec.title or ""), { type = "section", idx = s_idx })
        
        if not sec.expanded and sec.desc then
            add_line(lines, "    " .. sec.desc, nil)
            add_line(lines, "", nil)
        elseif sec.expanded then
            if sec.id == "apis" then
                add_line(lines, format_row(i18n.t("cc_fallback_motor"), M.state.fallback_mode and "[ ON ]" or "[ OFF ]", w), { type = "toggle_fallback" })
                add_line(lines, i18n.t("cc_providers_list"), nil)
                for i, a in ipairs(M.state.apis) do
                    local mark = (a.name == M.state.default_api) and "[ ✓ ]" or "[   ]"
                    add_line(lines, format_row("    ├─ " .. a.name, mark, w), { type = "api_select", name = a.name, idx = i })
                end
            elseif sec.id == "swarm" then
                add_line(lines, i18n.t("cc_swarm_perm"), nil)
                for i, a in ipairs(M.state.apis) do
                    local mark = a.allow_spawn and "[ ON ]" or "[ OFF ]"
                    add_line(lines, format_row("    " .. i .. ". " .. a.name, mark, w), { type = "api_spawn", idx = i })
                    add_line(lines, format_row("      └─ Abstraction Level", "[ " .. (a.abstraction_level or "medium") .. " ]", w), { type = "api_level_swarm", idx = i })
                end
            elseif sec.id == "watchdog" then
                local wd = M.state.watchdog
                local m_disp = wd.mode and (wd.mode:sub(1,1):upper() .. wd.mode:sub(2)) or "Off"
                add_line(lines, format_row(i18n.t("cc_wd_status"), "[ " .. m_disp .. " ]", w), { type = "wd_mode" })
                add_line(lines, format_row(i18n.t("cc_wd_trigger"), M.state.horizon .. " tokens", w), { type = "wd_horizon" })
                add_line(lines, format_row(i18n.t("cc_wd_tolerance"), tostring(M.state.tolerance), w), { type = "wd_tolerance" })
                add_line(lines, "", nil)
                local strat = "Semântico"
                if wd.strategy == "percent" then strat = "Percentual" elseif wd.strategy == "fixed" then strat = "Fixo" end
                add_line(lines, format_row(i18n.t("cc_wd_strategy"), "[ " .. strat .. " ]", w), { type = "wd_strategy" })
                if wd.strategy == "percent" then
                    add_line(lines, format_row(i18n.t("cc_wd_percent"), math.floor((wd.percent or 0.3) * 100) .. "%", w), { type = "wd_percent" })
                elseif wd.strategy == "fixed" then
                    add_line(lines, format_row(i18n.t("cc_wd_fixed"), (wd.fixed_target or 1500) .. " tokens", w), { type = "wd_fixed" })
                end
            elseif sec.id == "limits" then
                add_line(lines, format_row(i18n.t("cc_limit_id"), "[ " .. M.state.identity .. " ]", w), { type = "limit_identity" })
                add_line(lines, format_row(i18n.t("cc_limit_loops"), M.state.max_loops, w), { type = "limit_loops" })
            elseif sec.id == "gatekeeper" then
                add_line(lines, i18n.t("cc_gk_hint"), nil)
                local agent_names = {}
                for n, _ in pairs(M.state.agents) do table.insert(agent_names, n) end
                table.sort(agent_names)

                local sem_skills_keys = {}
                for sk, _ in pairs(M.state.semantic_skills) do table.insert(sem_skills_keys, sk) end
                table.sort(sem_skills_keys)

                for _, ag_name in ipairs(agent_names) do
                    local is_exp = M.state.expanded_agents[ag_name]
                    add_line(lines, "    " .. (is_exp and "[-] " or "[+] ") .. ag_name, { type = "agent_expand", name = ag_name })
                    if is_exp then
                        local ag_data = M.state.agents[ag_name]
                        local ag_skills = ag_data.skills or {}
                        
                        for _, sn in ipairs(sem_skills_keys) do
                            local has_skill = vim.tbl_contains(ag_skills, sn)
                            add_line(lines, format_row("      ├─ " .. sn, has_skill and "[ ✓ ]" or "[   ]", w), { type = "agent_skill_toggle", agent = ag_name, skill = sn })
                        end
                        add_line(lines, format_row("      ├─ Abstraction Level", "[ " .. (ag_data.abstraction_level or "high") .. " ]", w), { type = "agent_level", name = ag_name })
                        add_line(lines, i18n.t("cc_edit_sys_prompt"), { type = "edit_agent_prompt", name = ag_name })
                        add_line(lines, i18n.t("cc_delete_agent"), { type = "delete_agent", name = ag_name })
                    end
                end
                add_line(lines, i18n.t("cc_create_agent"), { type = "create_agent" })
            
            elseif sec.id == "semantic_skills" then
                local sem_skills_keys = {}
                for sk, _ in pairs(M.state.semantic_skills) do table.insert(sem_skills_keys, sk) end
                table.sort(sem_skills_keys)

                local tool_names = {}
                for tn, _ in pairs(M.state.all_tools) do table.insert(tool_names, tn) end
                table.sort(tool_names)

                for _, sn in ipairs(sem_skills_keys) do
                    local is_exp = M.state.expanded_semantic_skills[sn]
                    add_line(lines, "    " .. (is_exp and "[-] " or "[+] ") .. sn, { type = "semantic_skill_expand", name = sn })
                    if is_exp then
                        local sk_data = M.state.semantic_skills[sn]
                        local purpose = sk_data.purpose or ""
                        local trunc_purpose = purpose:sub(1, 40):gsub("\n", " ") .. "..."
                        add_line(lines, format_row("      ├─ Purpose", trunc_purpose, w), nil)
                        add_line(lines, i18n.t("cc_edit_skill_purpose"), { type = "edit_semantic_skill_prompt", name = sn })
                        add_line(lines, i18n.t("cc_delete_skill"), { type = "delete_semantic_skill", name = sn })
                        add_line(lines, "      ├─ Tools:", nil)
                        
                        for _, tn in ipairs(tool_names) do
                            local has_tool = vim.tbl_contains(sk_data.tools or {}, tn)
                            add_line(lines, format_row("        ├─ " .. tn, has_tool and "[ ✓ ]" or "[   ]", w), { type = "semantic_skill_tool_toggle", skill = sn, tool = tn })
                        end
                    end
                end
                add_line(lines, i18n.t("cc_create_semantic_skill"), { type = "create_semantic_skill" })
                
            elseif sec.id == "system_tools" then
                add_line(lines, i18n.t("cc_system_tools_hint"), nil)
                local tool_names = {}
                for tn, _ in pairs(M.state.all_tools) do table.insert(tool_names, tn) end
                table.sort(tool_names)
                
                for _, tn in ipairs(tool_names) do
                    local tl = M.state.all_tools[tn]
                    add_line(lines, format_row("    ├─ " .. tn, tl.is_native and "[ " .. i18n.t("cc_native_f") .. " ]" or "[ " .. i18n.t("cc_custom") .. " ]", w), { type = "edit_tool", name = tn })
                end
                add_line(lines, i18n.t("cc_create_tool"), { type = "create_tool" })

            elseif sec.id == "injectors" then
                add_line(lines, i18n.t("cc_inj_hint"), nil)
                local inj_names = {}
                for iname, _ in pairs(M.state.all_injectors) do table.insert(inj_names, iname) end
                table.sort(inj_names)
                
                for _, iname in ipairs(inj_names) do
                    local inj = M.state.all_injectors[iname]
                    add_line(lines, format_row("    ├─ " .. iname, inj.is_native and "[ " .. i18n.t("cc_native_m") .. " ]" or "[ " .. i18n.t("cc_custom") .. " ]", w), { type = "edit_injector", name = iname })
                end
                add_line(lines, i18n.t("cc_create_inj"), { type = "create_injector" })
            elseif sec.id == "squads" then
                add_line(lines, i18n.t("cc_sq_hint"), nil)
                local sq_names = {}
                for sn, _ in pairs(M.state.squads) do table.insert(sq_names, sn) end
                table.sort(sq_names)
                
                for _, sn in ipairs(sq_names) do
                    local sq = M.state.squads[sn]
                    add_line(lines, format_row("    ├─ @" .. sn, "[ " .. i18n.t("cc_squad") .. " ]", w), { type = "edit_squad", name = sn })
                    if sq.tasks then
                        for _, t in ipairs(sq.tasks) do
                            local chain_str = t.agent or "tech_lead"
                            if type(t.chain) == "table" and #t.chain > 0 then chain_str = chain_str .. " ➔ " .. table.concat(t.chain, " ➔ ") end
                            add_line(lines, "      └─ " .. chain_str, nil)
                        end
                    end
                end
                add_line(lines, i18n.t("cc_create_squad"), { type = "create_squad" })
            elseif sec.id == "appearance" then
                local app = M.state.appearance
                add_line(lines, format_row(i18n.t("cc_app_width"), tostring(app.width), w), { type = "app_width" })
                add_line(lines, format_row(i18n.t("cc_app_height"), tostring(app.height), w), { type = "app_height" })
                add_line(lines, format_row(i18n.t("cc_app_border"), "[ " .. (app.border or "rounded") .. " ]", w), { type = "app_border" })
            elseif sec.id == "history" then
                add_line(lines, i18n.t("cc_hist_hint"), nil)
                if #M.state.history_files == 0 then
                    add_line(lines, i18n.t("cc_hist_none"), nil)
                else
                    for _, f in ipairs(M.state.history_files) do
                        add_line(lines, format_row("    ├─ " .. f, "[ " .. i18n.t("cc_load") .. " ]", w), { type = "load_history", file = f })
                    end
                end
            elseif sec.id == "vault" then
                add_line(lines, i18n.t("cc_vault_hint"), nil)
                for _, a in ipairs(M.state.apis) do
                    local st = M.state.api_keys_status[a.name] or i18n.t("cc_missing")
                    add_line(lines, format_row("    ├─ " .. a.name, "[ " .. st .. " ]", w), { type = "edit_vault" })
                end
                add_line(lines, "", nil)
                add_line(lines, format_row(i18n.t("cc_master_prompt"), "[ " .. i18n.t("cc_edit") .. " ]", w), { type = "edit_master_prompt" })
            elseif sec.id == "telemetry" then
                add_line(lines, format_row(i18n.t("cc_telemetry_log"), M.state.debug_mode and "[ ON ]" or "[ OFF ]", w), { type = "toggle_debug" })
            end
            add_line(lines, "", nil)
        end
    end

    while #lines < 22 do table.insert(lines, "") end
    if vim.fn.has("nvim-0.10") == 0 then
        table.insert(lines, string.rep("─", w + 2))
        table.insert(lines, " ")
    end
    return lines
end

M.update_buffer = function()
    if not M.buf or not api.nvim_buf_is_valid(M.buf) then return end
    vim.bo[M.buf].modifiable = true
    api.nvim_buf_set_lines(M.buf, 0, -1, false, M.render())
    vim.bo[M.buf].modifiable = false
    vim.bo[M.buf].modified = false
    pcall(function() require('multi_context.ui.highlights').apply_controls(M.buf) end)
    pcall(function() M.update_footer(api.nvim_win_get_cursor(M.win)[1]) end)
end

M._edit_agent_prompt = function(name)
    local ag = M.state.agents[name]
    if not ag then return end
    local tmp_path = vim.fn.stdpath("data") .. "/mctx_agent_" .. name .. "_" .. os.date("%H%M%S") .. ".md"
    vim.fn.writefile(vim.split(ag.system_prompt or "", "\n"), tmp_path)
    
    pcall(api.nvim_win_close, M.win, true)
    vim.cmd("edit " .. tmp_path)
    
    api.nvim_create_autocmd("BufWritePost", {
        buffer = api.nvim_get_current_buf(),
        callback = function()
            local lines = vim.fn.readfile(tmp_path)
            local agents = require('multi_context.agents').load_agents()
            if agents[name] then
                agents[name].system_prompt = table.concat(lines, "\n")
                local agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"
                vim.fn.writefile({vim.fn.json_encode(agents)}, agents_file)
                vim.notify(i18n.t("cc_sys_prompt_updated", name), vim.log.levels.INFO)
            end
        end
    })
end

M._edit_skill_prompt = function(name)
    local sk = M.state.semantic_skills[name]
    if not sk then return end
    local tmp_path = vim.fn.stdpath("data") .. "/mctx_skill_" .. name .. "_" .. os.date("%H%M%S") .. ".txt"
    vim.fn.writefile(vim.split(sk.purpose or "", "\n"), tmp_path)
    pcall(api.nvim_win_close, M.win, true)
    vim.cmd("edit " .. tmp_path)
    
    api.nvim_create_autocmd("BufWritePost", {
        buffer = api.nvim_get_current_buf(),
        callback = function()
            local lines = vim.fn.readfile(tmp_path)
            local ontology = require('multi_context.ecosystem.skills_ontology')
            local skills_v2 = ontology.load_semantic_skills()
            if skills_v2[name] then
                skills_v2[name].purpose = table.concat(lines, "\n")
                local skills_file = vim.fn.stdpath("config") .. "/mctx_skills_v2.json"
                vim.fn.writefile({vim.fn.json_encode(skills_v2)}, skills_file)
                vim.notify(i18n.t("cc_sys_prompt_updated", name), vim.log.levels.INFO)
            end
        end
    })
end

M.handle_cr = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end
    
    if action.type == "section" then 
        M.toggle_section(action.idx); M.update_buffer()
    elseif action.type == "agent_expand" then 
        M.state.expanded_agents[action.name] = not M.state.expanded_agents[action.name]; M.update_buffer()
    elseif action.type == "semantic_skill_expand" then 
        M.state.expanded_semantic_skills[action.name] = not M.state.expanded_semantic_skills[action.name]; M.update_buffer()
    elseif action.type == "delete_agent" then
        local choice = vim.fn.confirm(i18n.t("cc_delete_agent_prompt", action.name), i18n.t("cc_yes") .. "\n" .. i18n.t("cc_no"), 2)
        if choice == 1 then
            M.state.agents[action.name] = nil; M.state.expanded_agents[action.name] = nil
            M.save_config(); vim.notify(i18n.t("cc_deleted"), vim.log.levels.INFO); M.update_buffer()
        end
    elseif action.type == "delete_semantic_skill" then
        local choice = vim.fn.confirm(i18n.t("cc_delete_skill_prompt", action.name), i18n.t("cc_yes") .. "\n" .. i18n.t("cc_no"), 2)
        if choice == 1 then
            M.state.semantic_skills[action.name] = nil; M.state.expanded_semantic_skills[action.name] = nil
            M.save_config(); vim.notify(i18n.t("cc_deleted"), vim.log.levels.INFO); M.update_buffer()
        end
    elseif action.type == "edit_agent_prompt" then
        M._edit_agent_prompt(action.name)
    elseif action.type == "edit_semantic_skill_prompt" then
        M._edit_skill_prompt(action.name)
    elseif action.type == "create_tool" then
        vim.ui.input({ prompt = i18n.t("cc_create_skill_pmpt") }, function(input)
            if not input or input == "" then return end
            input = input:gsub("%.lua$", "")
            local dir = vim.fn.stdpath("config") .. "/mctx_skills"
            if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
            local path = dir .. "/" .. input .. ".lua"
            
            local boilerplate = {
                "return {",
                "    name = '" .. input .. "',",
                "    description = '" .. i18n.t("cc_skill_desc_ph") .. "',",
                "    parameters = {",
                "        { name = 'arg1', type = 'string', required = true, desc = '" .. i18n.t("cc_skill_arg_ph") .. "' }",
                "    },",
                "    execute = function(args)",
                "        return '" .. i18n.t("cc_skill_res_ph") .. "'",
                "    end",
                "}"
            }
            vim.fn.writefile(boilerplate, path)
            pcall(api.nvim_win_close, M.win, true)
            vim.cmd("edit " .. path)
            vim.notify(i18n.t("cc_skill_created"), vim.log.levels.INFO)
        end)
    elseif action.type == "create_injector" then
        vim.ui.input({ prompt = i18n.t("cc_create_inj_pmpt") }, function(input)
            if not input or input == "" then return end
            input = input:gsub("%.lua$", "")
            local dir = vim.fn.stdpath("config") .. "/mctx_injectors"
            if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
            local path = dir .. "/" .. input .. ".lua"
            local boilerplate = {
                "return {", "    name = '" .. input .. "',", "    description = '" .. i18n.t("cc_inj_desc_ph") .. "',",
                "    execute = function()", "        return '" .. i18n.t("cc_inj_res_ph") .. "'", "    end", "}"
            }
            vim.fn.writefile(boilerplate, path)
            pcall(api.nvim_win_close, M.win, true)
            vim.cmd("edit " .. path)
            vim.notify(i18n.t("cc_inj_created"), vim.log.levels.INFO)
        end)
    elseif action.type == "create_agent" then
        vim.ui.input({ prompt = i18n.t("cc_create_agent_pmpt") }, function(input)
            if not input or input == "" then return end
            if not M.state.agents[input] then
                M.state.agents[input] = { system_prompt = i18n.t("cc_agent_sys_ph"), abstraction_level = "high", skills = {} }
                M.save_config(); vim.notify(i18n.t("cc_create_agent_notify", input), vim.log.levels.INFO); M.update_buffer()
            end
        end)
    elseif action.type == "create_semantic_skill" then
        vim.ui.input({ prompt = i18n.t("cc_create_semantic_skill_pmpt") }, function(input)
            if not input or input == "" then return end
            if not M.state.semantic_skills[input] then
                M.state.semantic_skills[input] = { purpose = "Nova Skill Semântica / New Semantic Skill", tools = {} }
                M.save_config(); vim.notify(string.format(i18n.t("cc_semantic_skill_created"), input), vim.log.levels.INFO); M.update_buffer()
            end
        end)
    elseif action.type == "create_squad" then
        vim.ui.input({ prompt = i18n.t("cc_create_squad_pmpt") }, function(input)
            if not input or input == "" then return end
            if not M.state.squads[input] then
                M.state.squads[input] = { description = "Novo esquadrão / New squad", tasks = { { agent = "tech_lead", instruction = "Instrução inicial", chain = {"coder"} } } }
                local squads_file = vim.fn.stdpath("config") .. "/mctx_squads.json"
                vim.fn.writefile({vim.fn.json_encode(M.state.squads)}, squads_file)
                vim.notify(i18n.t("cc_squad_created", input), vim.log.levels.INFO)
                M.update_buffer()
            end
        end)
    elseif action.type == "load_history" then
        local root = vim.fn.system("git rev-parse --show-toplevel")
        if vim.v.shell_error == 0 then root = root:gsub("\n", "") else root = vim.fn.getcwd() end
        local filepath = root .. "/.mctx_chats/" .. action.file
        if vim.fn.filereadable(filepath) == 1 then
            pcall(api.nvim_win_close, M.win, true)
            vim.cmd("edit " .. filepath)
            require('multi_context.utils.utils').load_workspace_state(api.nvim_get_current_buf())
            require('multi_context.ui.chat_view').create_popup(api.nvim_get_current_buf())
        end
    end
end

M.handle_space = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end

    if action.type == "api_select" then M.state.default_api = action.name
    elseif action.type == "toggle_fallback" then M.state.fallback_mode = not M.state.fallback_mode
    elseif action.type == "api_spawn" then M.state.apis[action.idx].allow_spawn = not M.state.apis[action.idx].allow_spawn
    elseif action.type == "api_level_swarm" then
        local cycles = { high = "medium", medium = "low", low = "high" }
        local ap = M.state.apis[action.idx]
        ap.abstraction_level = cycles[ap.abstraction_level or "medium"] or "medium"
    elseif action.type == "wd_mode" then
        local cycles = { off = "ask", ask = "auto", auto = "off" }
        M.state.watchdog.mode = cycles[M.state.watchdog.mode or "off"] or "off"
    elseif action.type == "wd_strategy" then
        local cycles = { semantic = "percent", percent = "fixed", fixed = "semantic" }
        M.state.watchdog.strategy = cycles[M.state.watchdog.strategy or "semantic"] or "semantic"
    elseif action.type == "agent_skill_toggle" then
        local ag = M.state.agents[action.agent]
        if not ag.skills then ag.skills = {} end
        local found_idx = nil
        for i, s in ipairs(ag.skills) do if s == action.skill then found_idx = i; break end end
        if found_idx then table.remove(ag.skills, found_idx) else table.insert(ag.skills, action.skill) end
    elseif action.type == "semantic_skill_tool_toggle" then
        local sk = M.state.semantic_skills[action.skill]
        if not sk.tools then sk.tools = {} end
        local found_idx = nil
        for i, t in ipairs(sk.tools) do if t == action.tool then found_idx = i; break end end
        if found_idx then table.remove(sk.tools, found_idx) else table.insert(sk.tools, action.tool) end
    elseif action.type == "app_border" then
        local borders = { rounded = "single", single = "double", double = "solid", solid = "shadow", shadow = "none", none = "rounded" }
        M.state.appearance.border = borders[M.state.appearance.border or "rounded"] or "rounded"
    elseif action.type == "toggle_debug" then
        M.state.debug_mode = not M.state.debug_mode
    end
    M.update_buffer()
end

M.handle_edit = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end

    local function prompt_str(msg, callback)
        vim.ui.input({ prompt = msg }, function(input) if input and input ~= "" then callback(input); M.update_buffer() end end)
    end
    local function prompt_num(msg, callback) prompt_str(msg, function(i) local n = tonumber(i); if n then callback(n) end end) end

    if action.type == "wd_horizon" then prompt_num(i18n.t("cc_prompt_wd_horizon"), function(n) M.state.horizon = n end)
    elseif action.type == "wd_tolerance" then prompt_num(i18n.t("cc_prompt_wd_tolerance"), function(n) M.state.tolerance = n end)
    elseif action.type == "wd_percent" then prompt_num(i18n.t("cc_prompt_wd_percent"), function(n) M.state.watchdog.percent = n / 100 end)
    elseif action.type == "wd_fixed" then prompt_num(i18n.t("cc_prompt_wd_fixed"), function(n) M.state.watchdog.fixed_target = n end)
    elseif action.type == "limit_identity" then prompt_str(i18n.t("cc_prompt_identity"), function(s) M.state.identity = s end)
    elseif action.type == "limit_loops" then prompt_num(i18n.t("cc_prompt_loops"), function(n) M.state.max_loops = n end)
    elseif action.type == "agent_level" then
        local cycles = { high = "medium", medium = "low", low = "high" }
        local ag = M.state.agents[action.name]
        ag.abstraction_level = cycles[ag.abstraction_level or "high"] or "high"
        M.update_buffer()
    elseif action.type == "app_width" then prompt_num(i18n.t("cc_prompt_width"), function(n) M.state.appearance.width = n end)
    elseif action.type == "app_height" then prompt_num(i18n.t("cc_prompt_height"), function(n) M.state.appearance.height = n end)
    elseif action.type == "edit_master_prompt" then prompt_str(i18n.t("cc_prompt_master"), function(s) M.state.master_prompt = s end)
    end
end

M.handle_open_file = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if not action then return end
    
    if action.type == "agent_expand" or action.type == "edit_agent_prompt" then
        M._edit_agent_prompt(action.name)
        return
    elseif action.type == "semantic_skill_expand" or action.type == "edit_semantic_skill_prompt" then
        M._edit_skill_prompt(action.name)
        return
    end

    local path = nil
    if action.type == "edit_tool" then
        if M.state.all_tools[action.name].is_native then
            vim.notify(i18n.t("cc_core_tool_warn"), vim.log.levels.WARN); return
        end
        path = vim.fn.stdpath("config") .. "/mctx_skills/" .. action.name .. ".lua"
    elseif action.type == "edit_injector" then
        if M.state.all_injectors[action.name].is_native then
            vim.notify(i18n.t("cc_core_inj_warn"), vim.log.levels.WARN); return
        end
        path = vim.fn.stdpath("config") .. "/mctx_injectors/" .. action.name .. ".lua"
    elseif action.type == "edit_squad" then
        path = vim.fn.stdpath("config") .. "/mctx_squads.json"
    elseif action.type == "edit_vault" then
        path = config.options.api_keys_path
    end
    
    if path and vim.fn.filereadable(path) == 1 then
        pcall(api.nvim_win_close, M.win, true)
        vim.cmd("edit " .. path)
    end
end

M.handle_dd = function()
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if action and (action.type == "api_select" or action.type == "api_spawn") then
        M.state.clipboard_api = table.remove(M.state.apis, action.idx); M.update_buffer()
    end
end

M.handle_p = function()
    if not M.state.clipboard_api then return end
    local action = M.line_map[api.nvim_win_get_cursor(0)[1]]
    local idx = #M.state.apis + 1
    if action and (action.type == "api_select" or action.type == "api_spawn") then idx = action.idx + 1 end
    table.insert(M.state.apis, idx, M.state.clipboard_api)
    M.state.clipboard_api = nil; M.update_buffer()
end

M.save_config = function()
    local cfg = config.load_api_config() or { apis = {} }
    cfg.apis = M.state.apis
    cfg.default_api = M.state.default_api
    cfg.fallback_mode = M.state.fallback_mode
    
    cfg.watchdog = vim.deepcopy(M.state.watchdog)
    cfg.cognitive_horizon = M.state.horizon
    cfg.user_tolerance = M.state.tolerance
    cfg.appearance = vim.deepcopy(M.state.appearance)
    cfg.master_prompt = M.state.master_prompt
    cfg.debug_mode = M.state.debug_mode
    config.save_api_config(cfg)
    
    config.options.user_name = M.state.identity
    config.options.appearance = vim.deepcopy(M.state.appearance)
    config.options.master_prompt = M.state.master_prompt
    config.options.debug_mode = M.state.debug_mode
    config.options.watchdog = vim.deepcopy(M.state.watchdog)
    config.options.cognitive_horizon = M.state.horizon
    config.options.user_tolerance = M.state.tolerance
    
    local agents_file = vim.fn.stdpath("config") .. "/mctx_agents.json"
    local raw_json = vim.fn.json_encode(M.state.agents)
    vim.fn.writefile({raw_json}, agents_file)
    pcall(function() vim.fn.system(string.format("echo %s | jq . > %s", vim.fn.shellescape(raw_json), agents_file)) end)

    local skills_file = vim.fn.stdpath("config") .. "/mctx_skills_v2.json"
    local raw_skills = vim.fn.json_encode(M.state.semantic_skills)
    vim.fn.writefile({raw_skills}, skills_file)
    pcall(function() vim.fn.system(string.format("echo %s | jq . > %s", vim.fn.shellescape(raw_skills), skills_file)) end)

    M._last_saved_cfg = cfg
    vim.notify(i18n.t("cc_saved"), vim.log.levels.INFO)
end

M.open_panel = function()
    M.init_state()
    for _, b in ipairs(api.nvim_list_bufs()) do if api.nvim_buf_get_name(b):match("MultiContext_Controls$") then pcall(api.nvim_buf_delete, b, { force = true }) end end
    M.buf = api.nvim_create_buf(false, true)
    vim.bo[M.buf].buftype = 'acwrite'
    vim.bo[M.buf].bufhidden = 'wipe'
    vim.bo[M.buf].swapfile = false
    api.nvim_buf_set_name(M.buf, "MultiContext_Controls")
    
    local w, h = 76, 28
    local win_opts = { relative = 'editor', width = w, height = h, row = math.floor((vim.o.lines - h) / 2), col = math.floor((vim.o.columns - w) / 2), border = 'rounded', style = 'minimal' }
    
    if vim.fn.has("nvim-0.9") == 1 then win_opts.title = " MultiContext AI 🤖[v1.4] "; win_opts.title_pos = "center" end
    
    M.win = api.nvim_open_win(M.buf, true, win_opts)
    vim.wo[M.win].cursorline = true; vim.wo[M.win].wrap = false; vim.wo[M.win].number = true; vim.wo[M.win].relativenumber = true
    M.update_buffer()
    
    local km = { noremap = true, silent = true }
    local function map(k, f) api.nvim_buf_set_keymap(M.buf, "n", k, "", { callback = f, noremap = true, silent = true }) end
    
    map("<CR>", M.handle_cr); map("<Space>", M.handle_space); map("c", M.handle_edit); map("e", M.handle_open_file); map("dd", M.handle_dd); map("p", M.handle_p)
    api.nvim_buf_set_keymap(M.buf, "n", "q", ":q!<CR>", km)
    
    api.nvim_create_autocmd("BufWriteCmd", { buffer = M.buf, callback = M.save_config })
    api.nvim_create_autocmd("CursorMoved", { buffer = M.buf, callback = function() if not api.nvim_buf_is_valid(M.buf) or not api.nvim_win_is_valid(M.win) then return end; M.update_footer(api.nvim_win_get_cursor(M.win)[1]) end })
end

return M
LUA_EOF

echo "✅ Interface semântica da Fase 41 injetada com sucesso!"
