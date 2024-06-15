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
local ConstTextTable = require("common.data.const_text_data").data

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
end

function M:SetUpDownText(bDown)
    -- 触发电梯外开关，显示是往上还是往下移动
    --if bDown then
    --    self.sUIPick = "往下"
    --else
    --    self.sUIPick = "往上"
    --end
    self.sUIPick = ConstTextTable.ELEVATORSWITCH_CALL.Content
end

function M:GetSwitchInteractable()
    --self:LogInfo("zsf", "[elevator_switch] GetSwitchInteractable %s %s", self.Sphere:GetCollisionEnabled(), UE.ECollisionEnabled.NoCollision)
    --if self.eInteractedItemCollision == Enum.E_InteractedItemCollision.Sphere then
    --    return self.Sphere:GetCollisionEnabled() ~= UE.ECollisionEnabled.NoCollision
    --else
    --    return self.Box:GetCollisionEnabled() ~= UE.ECollisionEnabled.NoCollision
    --end
    return self.bInteractable
end

function M:SetSwitchInteractable(bInteractable)
    --if bInteractable then
    --    self.Box:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
    --    self.Sphere:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
    --else
    --    self.Box:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    --    self.Sphere:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    --end
    self.bInteractable = bInteractable
    self:LogInfo("zsf", "[elevator_switch] SetSWitchInteractable %s %s", G.GetDisplayName(self), self.bInteractable)
end

---@param InvokerActor AActor
---@param InteractLocation Vector
function M:DoClientInteractActionWithLocation(InvokerActor, Damage, InteractLocation)
    local Location = self:K2_GetActorLocation()
    Super(M).DoClientInteractActionWithLocation(self, InvokerActor, Damage, Location)
end

function M:Multicast_ReceiveDamage_RPC(PlayerActor, InteractLocation, bAttack)
    local MainActor = self:GetMainActor()
    if MainActor then
        MainActor:MakeCurSwitchActor(self)
        MainActor:MoveToSwitchActor(InteractLocation)
    end
end

---@param InvokerActor AActor
function M:DoClientInteractAction(InvokerActor)
    if self.bPlayerOnMove then
        local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
        if GameState then
            if not GameState:PlayerStartLockMode() then
                local MainActor = self:GetMainActor()
                if MainActor then
                    MainActor:ShowInteractedIUIWhenStop()
                end
                return
            end
        end
    end
    Super(M).DoClientInteractAction(self, InvokerActor)
end

function M:MoveToMiddle()
    self:LogInfo("zsf", "[elevator] MoveToCurSwitchActor222 %s %s %s %s %s", self, G.GetDisplayName(self), self.eSwitchStatus, Enum.E_ElevatorSwitchStatus.Up, Enum.E_ElevatorSwitchStatus.Down)
    if self.eSwitchStatus == Enum.E_ElevatorSwitchStatus.Up then
        self:Multicast_MoveSwitch(-1)
    elseif self.eSwitchStatus == Enum.E_ElevatorSwitchStatus.Down then
        self:Multicast_MoveSwitch(1)
    end
end

function M:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    local MainActor = self:GetMainActor()
    if MainActor then
        local CurSwitchActor = MainActor:GetCurSwitchActor()
        if CurSwitchActor then
            local Actors = MainActor:GetActorSwitches()
            local Len = #Actors
            local bCurFloor = false
            for ind=Len,1,-1 do
                local cActors = Actors[ind]
                local bOk = false
                for _,Actor in ipairs(cActors) do
                    if CurSwitchActor == Actor then
                        bOk = true
                        break
                    end
                end
                if bOk then
                    for _,Actor in ipairs(cActors) do
                        if self == Actor then
                            bCurFloor = true
                            break
                        end
                    end
                end
            end
            if bCurFloor then -- 当前楼层，自动门自动打开
            else
                --if MainActor:IsPlayerOn(OtherActor) then
                --    self:LogInfo("zsf", "[elevator_switch] MakeCurSwitchActor %s %s %s", self, G.GetDisplayName(self), G.GetDisplayName(OtherActor))
                --    MainActor:MakeCurSwitchActor(self)
                --end
                if not MainActor:IsMoving() then
                    self.ForceIndex = nil
                    self.bNotSort = false
                    Super(M).OnBeginOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
                end
            end
        end
    end
end

function M:GetUIShowActors()
    --local MainActor = self:GetMainActor()
    --if MainActor then
    --    local Actors = MainActor:GetActorSwitches()
    --    local found_index = -1
    --    for ind,Actor in ipairs(Actors) do
    --        if Actor == self then
    --            found_index = ind
    --            break
    --        end
    --    end
    --    local FoundActors = {}
    --    if found_index >= 1 and found_index < #Actors then
    --        local UpActor = Actors[found_index+1]
    --        UpActor:SetUpDownText(false)
    --        table.insert(FoundActors, UpActor)
    --    end
    --    if found_index > 1 then
    --        local DownActor = Actors[found_index-1]
    --        DownActor:SetUpDownText(true)
    --        table.insert(FoundActors, DownActor)
    --    end
    --    return FoundActors
    --end
    self.sUIIcon = self.UIIcon
    self.bUseable = true
    self.bPlayerOnMove = false
    self:SetUpDownText(false)
    return {self}
end

return M