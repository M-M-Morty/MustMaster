

require "UnLua"

local G = require("G")
local DataManager = require("common.DataManager")


--@class GameInstance
local GameInstance = Class()


function GameInstance:ReceiveInit()
    G.log:debug("xaelpeng", "GameInstance:ReceiveInit")
    self:init_Global()
end

function GameInstance:ReceiveShutdown()
    G.GameInstance = nil
    G.log:info("hycoldrain", "game instance shutdown")
end

function GameInstance:ReceiveNetworkError(FailureType, IsServer)
    G.log:error("hycoldrain", "network error, failure type : %d,  is server: %b", FailureType, IsServer)
end

function GameInstance:ReceiveTravelError(FailureType)
    G.log:error("hycoldrain", "travel error, failure type : %d", FailureType)
end

function GameInstance:initScene()
    --UE.UKismetSystemLibrary.ExecuteConsoleCommand(G.GameInstance, "wp.runtime.hlod 0")
    UE.UKismetSystemLibrary.ExecuteConsoleCommand(G.GameInstance, "grass.CullDistanceScale 0.8") -- 20230812 和guoxing 确认过距离效果
    UE.UHiUtilsFunctionLibrary.SEtGameQualityLevel(2)

end
-------------internal functions--------------------------------
function GameInstance:FindEnum(t, k, RawFindEnum)
    local ret = self.UEEnums:FindRef(k)
    if ret then
        return ret
    end
    ret = RawFindEnum(t, k)
    if ret ~= nil then
        self.UEEnums:Add(k, ret) -- lua table can't hold object reference of UE, this is UE Map property
        rawset(t, k, ret)
    end
    return ret
end

function GameInstance:FindStruct(t, k, RawFindStruct)
    local ret = self.UEStructs:FindRef(k)
    if ret then
        return ret
    end
    ret = RawFindStruct(t, k)
    if ret ~= nil then
        self.UEStructs:Add(k, ret) -- lua table can't hold object reference of UE, this is UE Map property
        rawset(t, k, ret)
    end
    return ret
end

function GameInstance:init_Global()
    G.GameInstance = self
    self:initScene()
    self:InitGlobalData()
end

function GameInstance:InitGlobalData()
    DataManager:Init()
end

return GameInstance
