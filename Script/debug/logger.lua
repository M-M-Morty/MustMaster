
--
-- DESCRIPTION
-- local logger  = require ("debug.logger").Logger
-- logger:info("hycoldrain", "hi game %s", 666)



local _M = {}


require "UnLua"

local WHITE_LIST = require("debug.logger_config").WHITE_LIST
_M.FILTER_MSG_LIST = require("debug.logger_config").FILTER_MSG_LIST
local FORCE_SHOW_LEVEL = require("debug.logger_config").FORCE_SHOW_LEVEL
local LOG_METHOD = require("debug.logger_config").LOG_METHOD
local Visible = require("debug.logger_config").VISIBLE


---@class Logger
local Logger = Class()

function Logger:filter_msg(obj, tag, level, format, ...)
    if not tag then
        tag = "default"
    end

    if not WHITE_LIST[tag] and not FORCE_SHOW_LEVEL[level] then
        return 
    end    
    local msg
    if select("#", ...) > 0 then
        msg = string.format(format, ...)
    else
        msg = format
    end    
    if FORCE_SHOW_LEVEL[level] == nil and #_M.FILTER_MSG_LIST > 0 then
        local found  = false
        for i, m in ipairs(_M.FILTER_MSG_LIST) do
            if string.find(msg, m) then
                found = true
                break
            end                        
        end
        if not found then
            return
        end
    end    
    local t = os.time()
    local time = os.date("%Y-%m-%d %H:%M:%S", t)
    local FrameCount = G.GetFrameCount()
    local f_msg = time.." "..level.."["..tostring(FrameCount).."]".."["..tag.."]:"..tostring(msg)
    if #f_msg > 0 and f_msg[#f_msg] ~= "\n" then
        f_msg = f_msg.."\n"
    end

    local log_method = LOG_METHOD[level] or print
    if FORCE_SHOW_LEVEL[level] then
        if obj then
            local prefix = UE.UHiBlueprintFunctionLibrary.GetPIEWorldNetDescription(obj)
            if #prefix > 0 then
                log_method (prefix, f_msg)
            else
                log_method (f_msg)
            end
        else
            log_method (f_msg)
        end
    end
end


--
function Logger:info(tag, format, ...)
    self:filter_msg(nil, tag, "INFO", format, ...)
end

function Logger:debug(tag, format, ...)
    self:filter_msg(nil, tag, "DEBUG", format, ...)
end

function Logger:warn(tag, format, ...)
    self:filter_msg(nil, tag, "WARN", format, ...)
end

function Logger:error(tag, format, ...)
    self:filter_msg(nil, tag, "ERROR", format, ...)
end

function Logger:info_obj(obj, tag, format, ...)
    self:filter_msg(obj, tag, "INFO", format, ...)
end

function Logger:debug_obj(obj, tag, format, ...)
    self:filter_msg(obj, tag, "DEBUG", format, ...)
end

function Logger:warn_obj(obj, tag, format, ...)
    self:filter_msg(obj, tag, "WARN", format, ...)
end

function Logger:error_obj(obj, tag, format, ...)
    self:filter_msg(obj, tag, "ERROR", format, ...)
end

local DummyLogger = Class()
function DummyLogger:info(...)end
function DummyLogger:info_obj(...)end
function DummyLogger:debug(...)end
function DummyLogger:debug_obj(...)end
function DummyLogger:warn(...)end
function DummyLogger:warn_obj(...)end
function DummyLogger:error(...)end
function DummyLogger:error_obj(...)end

if Visible then
    _M.Logger = Logger
else
    _M.Logger = DummyLogger
end

return _M