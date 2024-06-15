local G = require("G")
local SubsystemUtils = require("common.utils.subsystem_utils")
local UIUtils = {}

--先把全局数据缓存在gamestate上，后面游戏流程全了后再根据情况看是不是要调整
function UIUtils.GetUIGlobalObject()
    local World = G.GameInstance:GetWorld()
    local UISys =  SubsystemUtils.GetUILogicSubsystem(World)
    if UISys then 
        return UISys:GetGlobalResource()
    else
       return nil 
    end
end

function UIUtils.CacheUIGlobalObject(CachedObject)
    local World = G.GameInstance:GetWorld()
    local UISys =  SubsystemUtils.GetUILogicSubsystem(World)
    if UISys and CachedObject then
        UISys:SetGlobalResource(CachedObject)
    end
end

return UIUtils
