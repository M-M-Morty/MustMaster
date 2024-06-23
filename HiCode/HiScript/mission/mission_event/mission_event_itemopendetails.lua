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

---@type MissionEventItemOpenDetails_C
local MissionEventItemOpenDetails = Class(MissionEventOnActorBase)

function MissionEventItemOpenDetails:OnActive()
    Super(MissionEventItemOpenDetails).OnActive(self)
    self:RegisterEventOnActorByTag("HiGamePlayer", self:GenerateEventRegisterParam())
end

function MissionEventItemOpenDetails:OnInactive()
    self:UnregisterEventOnActorByTag("HiGamePlayer")
    Super(MissionEventItemOpenDetails).OnInactive(self)
end

function MissionEventItemOpenDetails:GenerateEventRegisterParam()
    local ItemDetailsOpenType = self.ItemDetailsOpen.ItemDetailsOpenType
    local ItemInfos = self.ItemDetailsOpen.ItemInfos
    local tItemInfos = {}
    for Ind=1,ItemInfos:Length() do
        local Node = ItemInfos:Get(Ind)
        table.insert(tItemInfos, {ItemID=Node.ItemID,ItemNum=Node.ItemNum})
    end
    local Param = {
        ItemDetailsOpenType = ItemDetailsOpenType,
        ItemsInfo = tItemInfos,
        -- E_ItemDetailsOpenType --
        ObjectInfoID = self.ItemDetailsOpen.ObjectInfoID,
        InText = self.ItemDetailsOpen.InText,
        ImagePath = self.ItemDetailsOpen.ImagePath,
        bShowTopTip = self.ItemDetailsOpen.bShowTopTip
        -- E_ItemDetailsOpenType --
    }
    return json.encode(Param)
end

function MissionEventItemOpenDetails:OnEvent(EventParamStr)
    Super(MissionEventItemOpenDetails).OnEvent(self, EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventItemOpenDetails:RegisterOnTarget(PlayerState, EventRegisterParamStr)
    Super(MissionEventItemOpenDetails).RegisterOnTarget(self, PlayerState, EventRegisterParamStr)
    local Param = self:ParseActionParam(EventRegisterParamStr)
    if Param.ItemDetailsOpenType == Enum.E_ItemDetailsOpenType.ItemsAdd then
        if PlayerState then
            local ItemManager = PlayerState.ItemManager
            if Param.ItemsInfo then
                for _,ItemNode in ipairs(Param.ItemsInfo) do
                    ItemManager:AddItemByExcelID(ItemNode.ItemID,ItemNode.ItemNum)
                end
            end
            self:DispatchEvent(EventRegisterParamStr)
        end
    elseif Param.ItemDetailsOpenType == Enum.E_ItemDetailsOpenType.OpenDetailsAndItemsAddWhenClose then -- PlayerState
        local PlayerController = PlayerState:GetPlayerController()
        local Pawn = PlayerController:K2_GetPawn()
        if Pawn and Pawn.EdRuntimeComponent then
            if Param.ItemsInfo then
                local tItemsInfo = {}
                for _,ItemNode in ipairs(Param.ItemsInfo) do
                    local ItemDetails = Pawn.EdRuntimeComponent.ItemDetails:Copy()
                    ItemDetails.ItemID = ItemNode.ItemID
                    ItemDetails.ItemNum = ItemNode.ItemNum
                    table.insert(tItemsInfo, ItemDetails)
                end
                Pawn.EdRuntimeComponent:Client_ItemOpenDetails(Param.ItemDetailsOpenType, tItemsInfo, {})
            end
        end
        self:DispatchEvent(EventRegisterParamStr)
    elseif Param.ItemDetailsOpenType == Enum.E_ItemDetailsOpenType.OpenInteractionEmitterAndItemsAddWhenClose then
        local PlayerController = PlayerState:GetPlayerController()
        local Pawn = PlayerController:K2_GetPawn()
        if Pawn and Pawn.EdRuntimeComponent then
            if Param.ItemsInfo then
                local tItemsInfo = {}
                for _,ItemNode in ipairs(Param.ItemsInfo) do
                    local ItemDetails = Pawn.EdRuntimeComponent.ItemDetails:Copy()
                    ItemDetails.ItemID = ItemNode.ItemID
                    ItemDetails.ItemNum = ItemNode.ItemNum
                    table.insert(tItemsInfo, ItemDetails)
                end
                local StrParams = {Param.ObjectInfoID, Param.InText, Param.ImagePath, tostring(Param.bShowTopTip)}
                Pawn.EdRuntimeComponent:Client_ItemOpenDetails(Param.ItemDetailsOpenType, tItemsInfo, StrParams)
            end
        end
        self:DispatchEvent(EventRegisterParamStr)
    end
end

function MissionEventItemOpenDetails:GenerateEventParam(Param)
    return json.encode(Param)
end

function MissionEventItemOpenDetails:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

function MissionEventItemOpenDetails:UnregisterOnTarget(Actor)
    Super(MissionEventItemOpenDetails).UnregisterOnTarget(self, Actor)
end

return MissionEventItemOpenDetails
