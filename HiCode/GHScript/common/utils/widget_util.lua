local _M = {}

local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")

---@param WorldContextObject UObject
---@param softClassPtr TSoftClassPtr
---@return UUserWidget
function _M.CreateWidget(WorldContextObject, softClassPtr)
    local WidgetPath = PathUtil.getFullPathString(softClassPtr)
    local WidgetClass = LoadObject(WidgetPath)
    return UE.UWidgetBlueprintLibrary.Create(WorldContextObject, WidgetClass, nil)
end

return _M