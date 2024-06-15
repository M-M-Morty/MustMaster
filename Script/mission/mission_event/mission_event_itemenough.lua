--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local json = require("thirdparty.json")
local MissionEventOnActorBase = require("mission.mission_event.mission_event_onactor_base")

---@type MissionEventItemEnough_C
local MissionEventItemEnough = Class(MissionEventOnActorBase)

function MissionEventItemEnough:OnActive()
    Super(MissionEventItemEnough).OnActive(self)
    self:RegisterEventOnActorByTag("HiGamePlayer", self:GenerateEventRegisterParam())
end

function MissionEventItemEnough:OnInactive()
    self:UnregisterEventOnActorByTag("HiGamePlayer")
    Super(MissionEventItemEnough).OnInactive(self)
end

function MissionEventItemEnough:GenerateEventRegisterParam()
    local Ids = {}
    for Ind=1,self.ItemIds:Length() do
        local ItemNode = self.ItemIds:Get(Ind)
        table.insert(Ids, {ItemID=ItemNode.ItemID,ItemNum=ItemNode.ItemNum})
    end
    local Param = {
        ItemIds = Ids
    }
    return json.encode(Param)
end

function MissionEventItemEnough:OnEvent(EventParamStr)
    Super(MissionEventItemEnough).OnEvent(self, EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventItemEnough:RegisterOnTarget(PlayerState, EventRegisterParamStr)
    Super(MissionEventItemEnough).RegisterOnTarget(self, PlayerState, EventRegisterParamStr)
    local Param = self:ParseActionParam(EventRegisterParamStr)
    local bEnough = true
    if Param.ItemIds and PlayerState then
        local ItemManager = PlayerState:GetPlayerController().ItemManager
        for _,ItemNode in ipairs(Param.ItemIds) do
            local ItemID = ItemNode.ItemID
            local ItemNum = ItemNode.ItemNum
            local PackageItemNum = ItemManager:GetItemCountByExcelID(ItemID)
            G.log:debug("zsf", "MissionEventItemEnough:RegisterOnTarget %s %s %s %s", ItemID, G.GetDisplayName(PlayerState), ItemNum, PackageItemNum)
            if PackageItemNum < ItemNum then
                bEnough = false
                break
            end
        end
    end
    self:DispatchEvent(self:GenerateEventParam(bEnough))
end

function MissionEventItemEnough:GenerateEventParam(bEnough)
    local Param = {
        bEnough=bEnough
    }
    return json.encode(Param)
end

function MissionEventItemEnough:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

function MissionEventItemEnough:UnregisterOnTarget(Actor)
    Super(MissionEventItemEnough).UnregisterOnTarget(self, Actor)
end

return MissionEventItemEnough
