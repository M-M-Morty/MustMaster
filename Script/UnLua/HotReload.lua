--[[
    module热更新思路: 更新逻辑，保留状态
      逻辑指的是function，状态包括全局变量和闭包中的upvalue
      用new_module的逻辑替换old_module，但保留old_module中的状态

    详细介绍可参考 - https://km.woa.com/articles/show/564220

    Unlua自带的HotReload有如下缺点：
    1.new module中新增的函数热更无法生效
    2.对funtion的的替换不够彻底，比如table中引用的function不会被更新

    另外Unlua的HotReolad的部分细节实现的不是很合理，比如
    1.用new module中的upvalue替换old module，这会导致运行时的状态丢失
    2.new module中删除了某个函数，但不会体现在old module中

    基于如上原因，另外实现了这版HotReload，解决了以上问题，也方便后续的定制化
    有疑问随时联系: johnyou@tencent.com
]]
local M = {}

local origin_require = require
local script_root_path = UE.UUnLuaFunctionLibrary.GetScriptRootPath()
local ignore_modules = {}
local in_hotreload = false

local loaded_module_times = {}

local function get_last_modified_time(module_name)
    local filename = script_root_path .. module_name:gsub("%.", "/") .. ".lua"
    return UE.UUnLuaFunctionLibrary.GetFileLastModifiedTimestamp(filename)
end

local module_name_check_exclude = {
    ["common.component"] = true,
}

local function load_path_file(path, module_name, ...)

    local full_file_path = path .. module_name:gsub("%.", "/") .. ".lua"
    local file_handler, _, _ = io.open(full_file_path)
    if file_handler ~= nil then
        local chunk, error_msg = loadfile(full_file_path)
        assert(chunk ~= nil, string.format("load file.%s error: %s", tostring(module_name), tostring(error_msg)))
        file_handler:close()
        return chunk()
    end

    -- 原生的require无法加载luac文件，要用loadfile来加载
    full_file_path = path .. module_name:gsub("%.", "/") .. ".luac"
    local file_handlerc, _, _ = io.open(full_file_path)
    if file_handlerc ~= nil then
        local chunk, error_msg = loadfile(full_file_path)
        assert(chunk ~= nil, string.format("load file.%s error: %s", tostring(module_name), tostring(error_msg)))
        file_handlerc:close()
        return chunk()
    end
end

local function load_file(module_name, ...)
    local ret = nil

    -- 内部path
    ret = load_path_file(script_root_path, module_name, ...)
    if ret ~= nil then
        return ret
    end

    -- 外包path
    ret = load_path_file(script_root_path.."../", module_name, ...)
    if ret ~= nil then
        return ret
    end

    -- 数据表path
    ret = load_path_file(script_root_path.."../Data/", module_name, ...)
    if ret ~= nil then
        return ret
    end
end

local function require(module_name, ...)
    if package.loaded[module_name] ~= nil then
        return package.loaded[module_name], nil
    end

    --[[
    local ret = load_file(module_name, ...)
    if ret == nil then
        ret = origin_require(module_name, ...)
    end
    --]]

    local ret = origin_require(module_name, ...)

    if module_name_check_exclude[module_name] == nil and type(ret) ~= "table" then
        assert(false, string.format("module.%s must return table", module_name))
    end

    loaded_module_times[module_name] = get_last_modified_time(module_name)

    -- 兼容一个文件被加载出多个module的情况
    if package.loaded[module_name] == nil then
        package.loaded[module_name] = ret
    else
        print(string.format("%s already loaded", module_name))
    end

    return package.loaded[module_name], nil
end

local function require_ignore_global(module_name, new_global_vars, ...)
    if package.loaded[module_name] then
        return package.loaded[module_name]
    end

    -- new_global_vars用来cache module中定义的全局变量
    local env = setmetatable({}, { __index = _G, __newindex = function(t, k, v)
        if in_hotreload then
            new_global_vars[k] = v
        else
            _G[k] = v
        end
     end })

    local path = script_root_path .. module_name:gsub("%.", "/") .. ".lua"
    local chunk, error_msg = loadfile(path, nil, env)
    assert(chunk, error_msg)

    local ret = chunk()
    if module_name_check_exclude[module_name] == nil and type(ret) ~= "table" then
        assert(false, string.format("module.%s must return table", module_name))
    end
    loaded_module_times[module_name] = get_last_modified_time(module_name)
    package.loaded[module_name] = ret

    return ret
end

local upname_exclude = {
    _ENV = true,
    method_name = true,
    getmetatable = true,
    NotExist = true,
    rawget = true,
    rawset = true,
    type = true,
    new_class = true,
    GetUProperty = true,
    SetUProperty = true,
    Index = true,
    NewIndex = true,
    G = true,
    Avatar = true,
    t = true,
}

local function collect_upvalue(function_name, func, upvalues)
    local i = 1
    while true do
        local u_name, u_value = debug.getupvalue(func, i)
        if u_name == nil or u_name == "" then
            break
        end

        if not upname_exclude[u_name] then
            if upvalues[u_name] == nil then
                -- print(string.format("collect upvalue %s.%s", function_name, u_name))
                upvalues[u_name] = u_value
                if type(u_value) == "function" then
                    collect_upvalue(u_name, u_value, upvalues)
                end
            else
                -- assert(false, string.format("upvalue name %s.%s conflict", function_name, u_name))
                print(string.format("upvalue name %s.%s conflict", function_name, u_name))
            end
        end

        i = i + 1
    end
end

local function collect_upvalues(old_module, new_module)
    local all_old_upvalues = {}
    local all_new_upvalues = {}

    for ele_name, ele_value in pairs(old_module) do
        if type(ele_value) == "function" then
            collect_upvalue(ele_name, ele_value, all_old_upvalues)
        end
    end

    for ele_name, ele_value in pairs(new_module) do
        if type(ele_value) == "function" then
            collect_upvalue(ele_name, ele_value, all_new_upvalues)
        end
    end

    return all_old_upvalues, all_new_upvalues
end

local all_update_functions = {}
local function replace_functions_ref()
    local visited = {}
    local function f(t)
        if not t or visited[t] then
            return
        end

        visited[t] = true

        if type(t) == "function" then
            for i = 1, math.huge do
                local u_name, value = debug.getupvalue(t, i)
                if not u_name or u_name == "" then
                    break
                end

                f(value)
            end

        elseif type(t) == "table" then
            f(debug.getmetatable(t))
            pcall(function(t)
                for k, v in pairs(t) do
                    f(k)
                    f(v)

                    if type(k) == "function" then
                        if all_update_functions[k] ~= nil then
                            if all_update_functions[k] ~= "nil" then
                                t[all_update_functions[k]] = t[k]
                            end
                            t[k] = nil
                        end
                    end

                    if type(v) == "function" then
                        if all_update_functions[v] ~= nil then
                            if all_update_functions[v] ~= "nil" then
                                t[k] = all_update_functions[v]
                            else
                                t[k] = nil
                            end
                        end
                    end
                end
            end
            , t)
        end
    end

    f(_G)
    f(debug.getregistry())
end

local function update_function_upvalue(function_name, old_function, new_function, all_old_upvalues, all_new_upvalues)
    local old_function_upvalues = {}
    local new_function_upvalues = {}

    local function __collect(function_name, func, upvalues)
        if func == nil then
            return
        end

        local i = 1
        while true do
            local u_name, u_value = debug.getupvalue(func, i)
            if u_name == nil or u_name == "" then
                break
            end

            if not upname_exclude[u_name] then
                if upvalues[u_name] == nil then
                    upvalues[u_name] = {u_value, i}
                    -- print(string.format("collect upvalue.%s.%s idx.%s", function_name, u_name, i))
                end
            end

            i = i + 1
        end
    end

    __collect(function_name, old_function, old_function_upvalues)
    __collect(function_name, new_function, new_function_upvalues)

    -- print(string.format("update_function_upvalue.%s old.%s new.%s", function_name, #old_function_upvalues, #new_function_upvalues))

    for u_name, u_info in pairs(old_function_upvalues) do
        local old_upvalue = u_info[1]
        local old_upvalue_idx = u_info[2]

        local new_upvalue_info = new_function_upvalues[u_name]
        if new_upvalue_info ~= nil then
            -- upvalue同时存在于old function和new function中
            local new_upvalue = new_upvalue_info[1]
            local new_upvalue_idx = new_upvalue_info[2]

            if type(new_upvalue) ~= type(old_upvalue) then
                assert(false, "upvalue."..u_name.." type conflict "..type(new_upvalue).." ~= "..type(old_upvalue))
            end

            if type(new_upvalue) == "function" then
                -- 保留new_upvalue，但对function递归处理
                update_function_upvalue(u_name, old_upvalue, new_upvalue, all_old_upvalues, all_new_upvalues)
            else
                -- print(string.format("update_upvalue1.%s.%s idx.%s", function_name, u_name, new_upvalue_idx))
                debug.setupvalue(new_function, new_upvalue_idx, old_upvalue)
            end
        else
            -- 只存在于old function中，pass
        end
    end

    for u_name, u_info in pairs(new_function_upvalues) do
        local new_upvalue = u_info[1]
        local new_upvalue_idx = u_info[2]

        local old_upvalue_info = old_function_upvalues[u_name]
        if old_upvalue_info == nil then
            -- 只存在于new function中
            local old_upvalue = all_old_upvalues[u_name]
            if old_upvalue ~= nil then
                -- 是其它old_function的upvalue
                if type(new_upvalue) ~= type(old_upvalue) then
                    assert(false, "upvalue."..u_name.." type conflict "..type(new_upvalue).." ~= "..type(old_upvalue))
                end

                if type(new_upvalue) == "function" then
                    update_function_upvalue(u_name, old_upvalue, new_upvalue, all_old_upvalues, all_new_upvalues)
                else
                    -- print(string.format("update_upvalue2.%s.%s idx.%s", function_name, u_name, new_upvalue_idx))
                    debug.setupvalue(new_function, new_upvalue_idx, old_upvalue)
                end
            end
        end
    end

    if old_function ~= nil then
        if new_function ~= nil then
            all_update_functions[old_function] = new_function
        else
            all_update_functions[old_function] = "nil"
        end
    end
end

local function update_module_function(function_name, old_module, new_module, all_old_upvalues, all_new_upvalues)
    local old_function = rawget(old_module, function_name)
    local new_function = rawget(new_module, function_name)

    update_function_upvalue(function_name, old_function, new_function, all_old_upvalues, all_new_upvalues)

    -- print(string.format("update_module_function.%s old_function.%s new_function.%s", function_name, old_function, new_function))

    if new_function == nil then
        old_module[function_name] = nil
    else
        old_module[function_name] = new_function
    end
end

local function update_table(table_name, old_table, new_table, all_old_upvalues, all_new_upvalues, visited)
    if visited[old_table] ~= nil or visited[new_table] ~= nil then
        return
    end

    visited[old_table] = true
    visited[new_table] = true

    for k, v in pairs(old_table) do
        if not (type(k) == "function" or type(k) == "table") then
            -- 战略性忽略...
            if type(v) == "function" then
                update_function_upvalue(k, old_table[k], new_table[k], all_old_upvalues, all_new_upvalues)
                old_table[k] = new_table[k]
            end

            if type(v) == "table" and type(new_table[k]) == "table" then
                update_table(k, v, new_table[k], all_old_upvalues, all_new_upvalues, visited)
            end
        end
    end

    -- 处理new_table中新增的对象
    for k, v in pairs(new_table) do
        if type(v) == "function" and old_table[k] == nil then
            old_table[k] = v
        end
    end
end

local function update_module_table(table_name, old_module, new_module, all_old_upvalues, all_new_upvalues)
    local old_table = rawget(old_module, table_name)
    local new_table = rawget(new_module, table_name)

    if old_table == nil and new_table ~= nil then
        old_module[table_name] = new_table
    elseif old_table ~= nil and new_table ~= nil then
        update_table(table_name, old_table, new_table, all_old_upvalues, all_new_upvalues, {})
    end
end

local function update_module_value(value_name, old_module, new_module)
    local old_value = old_module[value_name]
    local new_value = new_module[value_name]
    if old_value == nil and new_value ~= nil then
        old_module[value_name] = new_value
    end
end

local function update_module(module_name, old_module, new_module, new_global_vars)
    if new_module == nil then
        return
    end

    if rawequal(old_module, new_module) then
        -- 部分文件用loadfile加载上来的new module地址可能和old module一样，但module里面的对象都替换了，原因暂未查明
        -- 对于这种未知的错误，还是重启吧，避免后续出现奇奇怪怪的问题
        assert(false, string.format("warn !!! %s reload failed(new address is same to old), PLEASE RESTART GAME !!!", module_name))
    end

    print(string.format("update_module %s old_module.%s new_module.%s", module_name, old_module, new_module))

    local all_old_upvalues, all_new_upvalues = collect_upvalues(old_module, new_module)

    for name, value in pairs(old_module) do
        local old_ele_type = type(value)
        local new_ele_type = type(new_module[name])

        -- 不兼容同名对象类型不一致的情况
        if old_ele_type ~= "nil" and new_ele_type ~= "nil" and old_ele_type ~= new_ele_type then
            assert(false, string.format("%s type conflict: old.%s new.%s raw old.%s", name, old_ele_type, new_ele_type, type(rawget(old_module, name))))
        end

        if old_ele_type == "function" then
            update_module_function(name, old_module, new_module, all_old_upvalues, all_new_upvalues)
        elseif old_ele_type == "table" then
            update_module_table(name, old_module, new_module, all_old_upvalues, all_new_upvalues)
        else
            update_module_value(name, old_module, new_module)
        end
    end

    -- 处理new_module中新增的对象
    for name, value in pairs(new_module) do
        local old_ele_type = type(old_module[name])
        local new_ele_type = type(value)

        if old_ele_type == "nil" then
            if new_ele_type == "function" then
                update_module_function(name, old_module, new_module, all_old_upvalues, all_new_upvalues)
            elseif new_ele_type == "table" then
                update_module_table(name, old_module, new_module, all_old_upvalues, all_new_upvalues)
            else
                update_module_value(name, old_module, new_module)
            end
        end
    end

    -- 处理new_module中定义的全局变量
    for k, v in pairs(new_global_vars) do
        if _G[k] == nil then
            _G[k] = v
        else
            if type(v) == "function" then
                update_function_upvalue(k, _G[k], v, all_old_upvalues, all_new_upvalues)
                _G[k] = v
            elseif type(v) == "table" then
                update_table(k, _G[k], v, all_old_upvalues, all_new_upvalues, {})
            else
                print(string.format("ignore global var %s.%s ", module_name, k))
            end
        end
    end

    replace_functions_ref()
end

local function _error_handler(err)
    local msg = err .. "\n" .. debug.traceback()
    UnLua.LogError(msg)
end

local function reload_modules(module_names)
    if not module_names or #module_names == 0 then
        return
    end

    all_update_functions = {}

    function get_real_module(origin_module)
        if origin_module.is_class == nil then
            return origin_module
        end

        -- Unlua Bind会将origin module浅拷贝一份出来放到全局注册表中，并将copy table作为实例的元表
        -- 所以这里要从全局注册表中找到copy table来进行hot reload
        local registry_table = debug.getregistry()
        local real_module = nil
        for k, v in pairs(registry_table) do
            if type(v) == "table" then
                -- print(string.format("find near same module.%s origin_module.%s ", rawget(v, "unique_id"), rawget(origin_module, "unique_id")))
                if rawget(v, "unique_id") == rawget(origin_module, "unique_id") then
                    real_module = v
                    break
                end
            end
        end

        if real_module ~= nil then
            -- print(string.format("find nearly same module.%s origin_module.%s max_same.%s", real_module, origin_module, max_same))
            return real_module
        else
            return origin_module
        end
    end

    for _, module_name in ipairs(module_names) do

        local old_module = package.loaded[module_name]
        package.loaded[module_name] = nil
        local real_old_module = get_real_module(old_module)
        if real_old_module ~= nil then
            local new_global_vars = {}
            -- local succ, new_module = xpcall(require_ignore_global, _error_handler, module_name, new_global_vars)
            local succ, new_module = xpcall(function () return require_ignore_global(module_name, new_global_vars) end, _error_handler)
            -- print(string.format("old_module.%s real_old_module.%s new_module.%s", old_module, real_old_module, new_module))
            update_module(module_name, real_old_module, new_module, new_global_vars)
            package.loaded[module_name] = old_module
        end
    end
end

local function _reload()
    local modified_modules = {}

    for module_name, last_modify_time in pairs(loaded_module_times) do
        -- print("reload "..module_name.." - "..last_modify_time)
        if not ignore_modules[module_name] then
            local current_time = get_last_modified_time(module_name)
            if last_modify_time < current_time then
                modified_modules[#modified_modules + 1] = module_name
                loaded_module_times[module_name] = current_time
            end
        end
    end

    local Start = G.GetNowTimestampMs()
    if #modified_modules > 0 then
        reload_modules(modified_modules)
    end
    local End = G.GetNowTimestampMs()

    print(string.format("reload.%s cost %sms", table.concat(modified_modules, ", "), End - Start))
end

local function reload()
    in_hotreload = true
    xpcall(_reload, _error_handler)
    in_hotreload = false
end


M.loaded_module_times = loaded_module_times
M.require = require
M.reload = reload
M.require_ignore_global = require_ignore_global
M.update_module = update_module

return M
