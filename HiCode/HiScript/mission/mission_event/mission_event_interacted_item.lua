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
local BPConst = require("common.const.blueprint_const")

---@type BP_MissionEventInteractedItem_C
local MissionEventInteractedItem = Class(MissionEventOnActorBase)

function MissionEventInteractedItem:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventInteractedItem:OnEvent(EventParamStr)
    Super(MissionEventInteractedItem).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventInteractedItem:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventInteractedItem).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    Actor.Sphere.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap)
    Actor.Sphere.OnComponentEndOverlap:Add(self, self.OnEndOverlap)
end

function MissionEventInteractedItem:UnregisterOnTarget(Actor)
    Super(MissionEventInteractedItem).UnregisterOnTarget(self, Actor)
    Actor.Sphere.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap)
    Actor.Sphere.OnComponentEndOverlap:Remove(self, self.OnEndOverlap)
    for i = 1, self.OverlappedControllers:Length() do
        local Controller = self.OverlappedControllers:Get(i)
        if Controller and Controller:IsValid() then
            Controller.BP_MissionComponent.ItemInteracted:Remove(self, self.OnItemInteracted)
        end
    end
    self.OverlappedControllers:Clear()
end

function MissionEventInteractedItem:OnBeginOverlap(OverlappedComp, Other, OtherComp, OtherBodyIndex, bFromSweep,
    SweepResult)
    G.log:debug("xaelpeng", "MissionEventInteractedItem:OnBeginOverlap %s", Other:GetName())
    local BPACharacterBaseClass = BPConst.GetBPACharacterBaseClass()
    local Character = Other:Cast(BPACharacterBaseClass)
    if Character ~= nil then
        local Controller = Character:GetController()
        local BPPlayerControllerClass = BPConst.GetBPPlayerControllerClass()
        local BPPlayerController = Controller:Cast(BPPlayerControllerClass)
        if BPPlayerController ~= nil then
            BPPlayerController.BP_MissionComponent.ItemInteracted:Add(self, self.OnItemInteracted)
            self.OverlappedControllers:AddUnique(BPPlayerController)
            BPPlayerController.BP_MissionComponent:BeginItemInteracted()
        else
            G.log:error("xaelpeng", "MissionEventInteractedItem:OnBeginOverlap Controller is not BPPlayerController")
        end
    else
        G.log:error("xaelpeng", "MissionEventInteractedItem:OnBeginOverlap Character is not BPACharacterBase")
    end
end

function MissionEventInteractedItem:OnEndOverlap(OverlappedComp, Other, OtherComp, OtherBodyIndex)
    G.log:debug("xaelpeng", "MissionEventInteractedItem:OnEndOverlap %s", Other:GetName())
    local BPACharacterBaseClass = BPConst.GetBPACharacterBaseClass()
    local Character = Other:Cast(BPACharacterBaseClass)
    if Character ~= nil then
        local Controller = Character:GetController()
        local BPPlayerControllerClass = BPConst.GetBPPlayerControllerClass()
        local BPPlayerController = Controller:Cast(BPPlayerControllerClass)
        if BPPlayerController ~= nil then
            BPPlayerController.BP_MissionComponent.ItemInteracted:Remove(self, self.OnItemInteracted)
            self.OverlappedControllers:Remove(BPPlayerController)
            BPPlayerController.BP_MissionComponent:CancelItemInteracted()
        else
            G.log:error("xaelpeng", "MissionEventInteractedItem:OnEndOverlap Controller is not BPPlayerController")
        end
    else
        G.log:error("xaelpeng", "MissionEventInteractedItem:OnEndOverlap Character is not BPACharacterBase")
    end
end

function MissionEventInteractedItem:OnItemInteracted()
    self:DispatchEvent(self:GenerateEventParam())
end

function MissionEventInteractedItem:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end

return MissionEventInteractedItem
