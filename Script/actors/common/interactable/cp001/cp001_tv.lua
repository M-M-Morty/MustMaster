--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/05/26
--

---@BP_Elevator_C

require "UnLua"
local G = require("G")
local ActorBase = require("actors.common.interactable.base.interacted_item")
local EdUtils = require("common.utils.ed_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BPConst = require("common.const.blueprint_const")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:IsCP001TV()
    return true
end

function M:TriggerInteractedItem(PlayerActor, Damage, InteractLocation)
    Super(M).TriggerInteractedItem(self, PlayerActor, Damage, InteractLocation)
    self:LogInfo("zsf", "[cp001_tv] TriggerInteractedItem")
    self.bLock = false
end

function M:OnRep_bLock()
    self:LogInfo("zsf", "[cp001_tv] OnRep_bLock %s", self.bLock)
    if not self.bLock then
        self.LockEffect:SetActive(self.bLock, false)
        local MainActor = self:GetMainActor()
        if MainActor then
            MainActor:ChildTriggerMainActor(self)
        end
    end
end

function M:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if self.bLock then
        Super(M).OnBeginOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    end
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    self.LockEffect:SetActive(self.bLock, false)
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
end

return M