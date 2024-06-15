
local _M = {}

_M.WHITE_LIST = {}

--add white list
--_M.WHITE_LIST[" any "] = 1

_M.FILTER_MSG_LIST = {}
_M.FORCE_SHOW_LEVEL = {INFO = 1, DEBUG = 2, WARN = 3, ERROR = 4}
_M.LOG_METHOD = {INFO = UnLua.Log, DEBUG = UnLua.Log, WARN = UnLua.LogWarn, ERROR = UnLua.LogError}
_M.VISIBLE = true

return _M