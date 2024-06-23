------------------------------------------
--- IRPC Client/Server管理
--- 1: 提供Lua IRPC Client/Server的管理
--- 2：Lua层IRPC Client/Server和IRPCCore(C++)层对接
--- 3：提供基于lua层的协程、回调等异步能力
------------------------------------------
---@class IRPCLite

local IRPCCore = require "irpc_core"

local IRPCLog = {}

IRPCLog.LogLevel = {
	ELogTrace = 0,
	ELogDebug = 1,
	ELogInfo = 2,
	ELogWarn = 3,
	ELogError = 4,
	ELogFatal = 5,
}

local ELogTrace = IRPCLog.LogLevel.ELogTrace
local ELogDebug = IRPCLog.LogLevel.ELogDebug
local ELogInfo = IRPCLog.LogLevel.ELogInfo
local ELogWarn = IRPCLog.LogLevel.ELogWarn
local ELogError = IRPCLog.LogLevel.ELogError
local ELogFatal = IRPCLog.LogLevel.ELogFatal
local LogLevel = ELogDebug

--- @param newloglevel string @设置日志等级
function IRPCLog.SetLogLevel(newloglevel)
	local leveltype = type(newloglevel)
	if("number" ~= leveltype) then
		IRPCLog.LogError("SetLogLevel, error newloglevel", newloglevel)
	end
	LogLevel = newloglevel
end

local StackDeep = 0

local function LogInner(loglevel, ...)
	-- Log**Format 会多一层调用 getinfo 参数需要加1
	local info = debug.getinfo(3 + StackDeep, "nSl")
	local file = info.short_src
	if ( file:find("%[string") ) then
		file = string.sub(file, 10, -3)
	end
	local line = info.currentline
	local func_name = info.name or ""
	IRPCCore.Print(loglevel, file, line, func_name, ...)
end

function IRPCLog.LogTrace(...)
	if(LogLevel <= ELogTrace) then
		LogInner(IRPCLog.LogLevel.ELogTrace , ...)
	end
end

function IRPCLog.LogDebug(...)
	if(LogLevel <= ELogDebug) then
		LogInner(IRPCLog.LogLevel.ELogDebug , ...)
	end
end

function IRPCLog.LogInfo(...)
	if(LogLevel <= ELogInfo) then
		LogInner(IRPCLog.LogLevel.ELogInfo , ...)
	end
end

function IRPCLog.LogWarn(...)
	if(LogLevel <= ELogWarn) then
		LogInner(IRPCLog.LogLevel.ELogWarn , ...)
	end
end

function IRPCLog.LogError(...)
	if(LogLevel <= ELogError) then
		LogInner(IRPCLog.LogLevel.ELogError , ...)
	end
end

function IRPCLog.LogFatal(...)
	if(LogLevel <= ELogFatal) then
		LogInner(IRPCLog.LogLevel.ELogFatal , debug.traceback("", 2), ...)
	end
end

function IRPCLog.LogTraceFormat(format, ...)
	StackDeep = StackDeep + 1
	IRPCLog.LogTrace(string.format(format, ...));
	StackDeep = StackDeep - 1
end

function IRPCLog.LogDebugFormat(format, ...)
	StackDeep = StackDeep + 1
	IRPCLog.LogDebug(string.format(format, ...));
	StackDeep = StackDeep - 1
end

function IRPCLog.LogInfoFormat(format, ...)
	StackDeep = StackDeep + 1
	IRPCLog.LogInfo(string.format(format, ...));
	StackDeep = StackDeep - 1
end

function IRPCLog.LogWarnFormat(format, ...)
	StackDeep = StackDeep + 1
	IRPCLog.LogWarn(string.format(format, ...));
	StackDeep = StackDeep - 1
end

function IRPCLog.LogErrorFormat(format, ...)
	StackDeep = StackDeep + 1
	IRPCLog.LogError(string.format(format, ...));
	StackDeep = StackDeep - 1
end

function IRPCLog.LogFatalFormat(format, ...)
	StackDeep = StackDeep + 1
	IRPCLog.LogFatal(string.format(format, ...));
	StackDeep = StackDeep - 1
end

return IRPCLog
