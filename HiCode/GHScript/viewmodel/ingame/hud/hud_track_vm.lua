--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')

---@class TrackTargetType
local TrackTargetType =
{
    None = 0,
    TrackActor = 1,    -- 任务追踪
    TrackLocation = 2, -- 伤害追踪
    TreasureBox = 6,   -- 宝箱
    Badieta = 7,         -- 巴迪塔
    SpecialIcon = 8        -- 特殊icon，直接赋值
}

---@class BaseTrackTargetWrapper
local BaseTrackTargetWrapper = Class()

function BaseTrackTargetWrapper:IsValid()
    return true
end

function BaseTrackTargetWrapper:GetTrackInfo()
end

function BaseTrackTargetWrapper:RegisterDestroyCallback(Callback)
end

function BaseTrackTargetWrapper:UnregisterDestroyCallback(Callback)
end

function BaseTrackTargetWrapper:GetTrackType()
    return TrackTargetType.None
end

---@class ActorHurtTrackTargetWrapper
local ActorHurtTrackTargetWrapper = Class(BaseTrackTargetWrapper)

function ActorHurtTrackTargetWrapper:ctor(InActor)
    self.TrackedActor = InActor
    self.PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(InActor, 0)
    self.WrapperCallback = nil
    self.bIsExpired = false
end

function ActorHurtTrackTargetWrapper:IsValid()
    return self.TrackedActor:IsValid()
end

function ActorHurtTrackTargetWrapper:SetExpired()
    self.bIsExpired = true
end

function ActorHurtTrackTargetWrapper:GetTrackType()
    return TrackTargetType.TrackLocation
end

function ActorHurtTrackTargetWrapper:GetTrackInfo()
    -- self.PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(self.TrackedActor, 0)
    if not UE.UKismetSystemLibrary.IsValid(self.PlayerPawn) or not UE.UKismetSystemLibrary.IsValid(self.TrackedActor) then
        return
    end
    if self.PlayerPawn and self.TrackedActor then
        local PlayerLocation = self.PlayerPawn:K2_GetActorLocation()
        local ActorLocation
        local ActorTaskType = self:GetTrackType()
        if self.TrackedActor.GetHudWorldLocation then
            ActorLocation = self.TrackedActor:GetHudWorldLocation()
        else
            ActorLocation = self.TrackedActor:K2_GetActorLocation()
        end
        return ActorTaskType, ActorLocation, UE.UKismetMathLibrary.Vector_Distance(PlayerLocation, ActorLocation), self:IsBoss()
    end
end

---@return boolean
function ActorHurtTrackTargetWrapper:IsBoss()
    if self.TrackedActor and UE.UKismetSystemLibrary.IsValid(self.TrackedActor) then
        return self.TrackedActor.BP_MonsterHPWidget.isBoss
    end
end

function ActorHurtTrackTargetWrapper:RegisterDestroyCallback(Callback)
    self.WrapperCallback = function(Actor)
        if Actor == self.TrackedTarget then
            Callback(self)
        end
    end
    self.TrackedActor.OnDestroyed:Add(self.TrackedActor, self.WrapperCallback)
end

function ActorHurtTrackTargetWrapper:UnregisterDestroyCallback(Callback)
    self.TrackedActor.OnDestroyed:Remove(self.TrackedActor, self.WrapperCallback)
end

---@class ActorTrackTargetWrapper
local ActorTrackTargetWrapper = Class(BaseTrackTargetWrapper)

function ActorTrackTargetWrapper:ctor(InActor, MissionObject)
    self.TrackedActor = InActor
    self.PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(InActor, 0)
    self.MissionObj = MissionObject
    self.WrapperCallback = nil
end

function ActorTrackTargetWrapper:IsValid()
    return self.TrackedActor:IsValid()
end

function ActorTrackTargetWrapper:GetMissionObject()
    return self.MissionObject
end

function ActorTrackTargetWrapper:GetTrackType()
    return TrackTargetType.TrackActor
end

function ActorTrackTargetWrapper:GetTrackInfo()
    if self.PlayerPawn and self.TrackedActor then
        local PlayerLocation = self.PlayerPawn:K2_GetActorLocation()
        local ActorLocation
        local ActorTaskType = self:GetTrackType()
        if self.TrackedActor.GetHudWorldLocation then
            ActorLocation = self.TrackedActor:GetHudWorldLocation()
        else
            ActorLocation = self.TrackedActor:K2_GetActorLocation()
        end
        return ActorTaskType, ActorLocation, UE.UKismetMathLibrary.Vector_Distance(PlayerLocation, ActorLocation), self:GetMissionObject()
    end
end

function ActorTrackTargetWrapper:RegisterDestroyCallback(Callback)
    self.WrapperCallback = function(Actor)
        if Actor == self.TrackedTarget then
            Callback(self)
        end
    end
    self.TrackedActor.OnDestroyed:Add(self.TrackedActor, self.WrapperCallback)
end

function ActorTrackTargetWrapper:UnregisterDestroyCallback(Callback)
    self.TrackedActor.OnDestroyed:Remove(self.TrackedActor, self.WrapperCallback)
end

---@class LocationTrackTargetWrapper
local LocationTrackTargetWrapper = Class(BaseTrackTargetWrapper)

function LocationTrackTargetWrapper:ctor(InLocation, Duration, WorldContext)
    self.TrackedLocation = InLocation
    self.PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(WorldContext, 0)
    self.WrapperCallback = nil
    self.fDuration = Duration
    self.bIsExpired = false
end

function LocationTrackTargetWrapper:GetDuration()
    return self.fDuration
end

function LocationTrackTargetWrapper:IsValid()
    return not self.bIsExpired
end

function LocationTrackTargetWrapper:SetExpired()
    self.bIsExpired = true
end

function LocationTrackTargetWrapper:GetTrackType()
    return TrackTargetType.TrackLocation
end

function LocationTrackTargetWrapper:GetTrackInfo()
    if self.PlayerPawn and self.TrackedLocation then
        local PlayerLocation = self.PlayerPawn:K2_GetActorLocation()
        return self:GetTrackType(), self.TrackedLocation,
            UE.UKismetMathLibrary.Vector_Distance(PlayerLocation, self.TrackedLocation)
    end
end

---@class TreasureBoxTrackTargetWrapper
local TreasureBoxTrackTargetWrapper = Class(BaseTrackTargetWrapper)

function TreasureBoxTrackTargetWrapper:ctor(InActor)
    self.TrackedActor = InActor
    self.PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(InActor, 0)
    self.WrapperCallback = nil
end

function TreasureBoxTrackTargetWrapper:IsValid()
    return self.TrackedActor:IsValid()
end

function TreasureBoxTrackTargetWrapper:RegisterDestroyCallback(Callback)
    self.WrapperCallback = function(Actor)
        if Actor == self.TrackedTarget then
            Callback(self)
        end
    end
    self.TrackedActor.OnDestroyed:Add(self.TrackedActor, self.WrapperCallback)
end

function TreasureBoxTrackTargetWrapper:UnregisterDestroyCallback(Callback)
    self.TrackedActor.OnDestroyed:Remove(self.TrackedActor, self.WrapperCallback)
end

function TreasureBoxTrackTargetWrapper:GetTrackType()
    return TrackTargetType.TreasureBox
end

function TreasureBoxTrackTargetWrapper:GetTrackInfo()
    if self.PlayerPawn and self.TrackedActor then
        local PlayerLocation = self.PlayerPawn:K2_GetActorLocation()
        local ActorLocation
        if self.TrackedActor.GetHudWorldLocation then
            ActorLocation = self.TrackedActor:GetHudWorldLocation()
        else
            ActorLocation = self.TrackedActor:K2_GetActorLocation()
        end
        return self:GetTrackType(), ActorLocation, UE.UKismetMathLibrary.Vector_Distance(PlayerLocation, ActorLocation)
    end
end

---@class BadietaTrackTargetWrapper
local BadietaTrackTargetWrapper = Class(BaseTrackTargetWrapper)

function BadietaTrackTargetWrapper:ctor(InActor)
    self.TrackedActor = InActor
    self.PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(InActor, 0)
    self.WrapperCallback = nil
end

function BadietaTrackTargetWrapper:IsValid()
    return self.TrackedActor:IsValid()
end

function BadietaTrackTargetWrapper:RegisterDestroyCallback(Callback)
    self.WrapperCallback = function(Actor)
        if Actor == self.TrackedTarget then
            Callback(self)
        end
    end
    self.TrackedActor.OnDestroyed:Add(self.TrackedActor, self.WrapperCallback)
end

function BadietaTrackTargetWrapper:UnregisterDestroyCallback(Callback)
    self.TrackedActor.OnDestroyed:Remove(self.TrackedActor, self.WrapperCallback)
end

function BadietaTrackTargetWrapper:GetTrackType()
    return TrackTargetType.Badieta
end

function BadietaTrackTargetWrapper:GetTrackInfo()
    if self.PlayerPawn and self.TrackedActor then
        local PlayerLocation = self.PlayerPawn:K2_GetActorLocation()
        local ActorLocation
        if self.TrackedActor.GetHudWorldLocation then
            ActorLocation = self.TrackedActor:GetHudWorldLocation()
        else
            ActorLocation = self.TrackedActor:K2_GetActorLocation()
        end
        return self:GetTrackType(), ActorLocation, UE.UKismetMathLibrary.Vector_Distance(PlayerLocation, ActorLocation)
    end
end

---@class SpecialIconTrackTargetWrapper
local SpecialIconTrackTargetWrapper = Class(BaseTrackTargetWrapper)

function SpecialIconTrackTargetWrapper:ctor(InActor, Icon)
    self.TrackedActor = InActor
    self.PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(InActor, 0)
    self.WrapperCallback = nil
    self.Icon = Icon
end

function SpecialIconTrackTargetWrapper:IsValid()
    return self.TrackedActor:IsValid()
end

function SpecialIconTrackTargetWrapper:RegisterDestroyCallback(Callback)
    self.WrapperCallback = function(Actor)
        if Actor == self.TrackedTarget then
            Callback(self)
        end
    end
    self.TrackedActor.OnDestroyed:Add(self.TrackedActor, self.WrapperCallback)
end

function SpecialIconTrackTargetWrapper:UnregisterDestroyCallback(Callback)
    self.TrackedActor.OnDestroyed:Remove(self.TrackedActor, self.WrapperCallback)
end

function SpecialIconTrackTargetWrapper:GetTrackType()
    return TrackTargetType.SpecialIcon
end

function SpecialIconTrackTargetWrapper:GetTrackIcon()
    return self.Icon
end

function SpecialIconTrackTargetWrapper:GetTrackInfo()
    if self.PlayerPawn and self.TrackedActor then
        local PlayerLocation = self.PlayerPawn:K2_GetActorLocation()
        local ActorLocation
        if self.TrackedActor.GetHudWorldLocation then
            ActorLocation = self.TrackedActor:GetHudWorldLocation()
        else
            ActorLocation = self.TrackedActor:K2_GetActorLocation()
        end
        return self:GetTrackType(), ActorLocation, UE.UKismetMathLibrary.Vector_Distance(PlayerLocation, ActorLocation)
    end
end

---@class MissionTrackTargetWrapper
local MissionTrackTargetWrapper = Class(BaseTrackTargetWrapper)

function MissionTrackTargetWrapper:ctor(Component, TrackTargetIndex)
    self.Component = Component
    self.TrackTargetIndex = TrackTargetIndex
    self.DestroyCallback = nil
end

function MissionTrackTargetWrapper:IsValid()
    return true
end

function MissionTrackTargetWrapper:GetTrackType()
    return TrackTargetType.TrackActor
end

function MissionTrackTargetWrapper:GetTrackInfo()
    local Position, Distance = self.Component:GetTrackTargetPositionAndDistanceByIndex(self.TrackTargetIndex)
    local MissionObject = self.Component:GetTrackMissionObject()
    return self:GetTrackType(), Position, Distance, MissionObject
end

function MissionTrackTargetWrapper:RegisterDestroyCallback(Callback)
    self.DestroyCallback = Callback
end

function MissionTrackTargetWrapper:UnregisterDestroyCallback(Callback)
    if self.DestroyCallback == Callback then
        self.DestroyCallback = nil
    end
end

function MissionTrackTargetWrapper:Destroy()
    if self.DestroyCallback ~= nil then
        self.DestroyCallback(self)
        self.DestroyCallback = nil
    end
    self.Component = nil
end

---@class TrackActorNode
---@field TrackedTarget BaseTrackTargetWrapper
local TrackActorNodeClass = Class()

function TrackActorNodeClass:ctor(InTarget)
    self.TrackedTarget = InTarget
    -- self.PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(InTarget, 0)
end

function TrackActorNodeClass:GetObjTrackType()
    if self.TrackedTarget then
        return self.TrackedTarget:GetTrackType()
    end
end

function TrackActorNodeClass:GetObjTrackInfo()
    if self.TrackedTarget then
        return self.TrackedTarget:GetTrackInfo()
    end
    -- if self.PlayerPawn and self.TrackedActor then
    --     local PlayerLocation = self.PlayerPawn:K2_GetActorLocation()
    --     local ActorLocation
    --     if self.TrackedActor.GetHudWorldLocation then
    --         ActorLocation = self.TrackedActor:GetHudWorldLocation()
    --     else
    --         ActorLocation = self.TrackedActor:K2_GetActorLocation()
    --     end
    --     return ActorLocation, UE.UKismetMathLibrary.Vector_Distance(PlayerLocation, ActorLocation)
    -- end
end

---@class HudTrackVM : ViewModelBase
local HudTrackVM = Class(ViewModelBaseClass)

function HudTrackVM:ctor()
    Super(HudTrackVM).ctor(self)

    self.OnTrackedActorDestroyed = function(InTarget)
        self:RemoveTrackActor(InTarget)
    end

    self.TrackActorArrayField = self:CreateVMArrayField({})
end

---@param InTarget BaseTrackTargetWrapper
function HudTrackVM:AddTrackActor(InTarget)
    if InTarget and InTarget:IsValid() then
        InTarget:RegisterDestroyCallback(self.OnTrackedActorDestroyed)
        -- InActor.OnDestroyed:Add(InActor, self.OnTrackedActorDestroyed)

        ---@type TrackActorNode
        local TrackActorNode = self.TrackActorArrayField:FindItemValueIf(function(TrackActorNode)
            if TrackActorNode.TrackedTarget == InTarget then
                return true
            end
        end)

        if not TrackActorNode then
            TrackActorNode = TrackActorNodeClass.new(InTarget)
            self.TrackActorArrayField:AddItem(TrackActorNode)
        end
    end
end

---@param InTarget BaseTrackTargetWrapper
function HudTrackVM:AddHurtTrackActor(actor)
    ---@type TrackActorNode
    local TrackActorNode = self.TrackActorArrayField:FindItemValueIf(function(TrackActorNode)
        if TrackActorNode.TrackedTarget.TrackedActor == actor then
            return true
        end
    end)

    if not TrackActorNode then
        local InTarget = self.ActorHurtTrackTargetWrapper.new(actor)

        InTarget:RegisterDestroyCallback(self.OnTrackedActorDestroyed)
        TrackActorNode = TrackActorNodeClass.new(InTarget)
        self.TrackActorArrayField:AddItem(TrackActorNode)
    end
end

---@param InTarget BaseTrackTargetWrapper
function HudTrackVM:RemoveHurtTrackActor(actor, NotBroadcast)
    if actor then
        local TrackActorNode = self.TrackActorArrayField:FindItemValueIf(function(TrackActorNode)
            if TrackActorNode.TrackedTarget.TrackedActor == actor then
                return true
            end
        end
        )
        TrackActorNode.TrackedTarget:UnregisterDestroyCallback(self.OnTrackedActorDestroyed)
        -- InActor.OnDestroyed:Remove(InActor, self.OnTrackedActorDestroyed)

        self.TrackActorArrayField:RemoveItemIf(function(NodeField)
            if NodeField:GetFieldValue().TrackedTarget.TrackedActor == actor then
                return true
            end
        end, NotBroadcast)
    end
end

---@param InTarget BaseTrackTargetWrapper
function HudTrackVM:RemoveTrackActor(InTarget, NotBroadcast)
    if InTarget then
        InTarget:UnregisterDestroyCallback(self.OnTrackedActorDestroyed)
        -- InActor.OnDestroyed:Remove(InActor, self.OnTrackedActorDestroyed)

        self.TrackActorArrayField:RemoveItemIf(function(NodeField)
            if NodeField:GetFieldValue().TrackedTarget == InTarget then
                return true
            end
        end, NotBroadcast)
    end
end

function HudTrackVM:OnTickVM()
    local tbInValid = {}
    for v in self.TrackActorArrayField:Items_Iterator() do
        if not v:GetFieldValue().TrackedTarget:IsValid() then
            table.insert(tbInValid, v:GetFieldValue().TrackedTarget)
        end
    end

    if #tbInValid > 0 then
        for _, TrackedTarget in pairs(tbInValid) do
            self:RemoveTrackActor(TrackedTarget)
        end
    end
end

HudTrackVM.TrackTargetType = TrackTargetType
HudTrackVM.BaseTrackTargetWrapper = BaseTrackTargetWrapper
HudTrackVM.ActorTrackTargetWrapper = ActorTrackTargetWrapper
HudTrackVM.LocationTrackTargetWrapper = LocationTrackTargetWrapper
HudTrackVM.TreasureBoxTrackTargetWrapper = TreasureBoxTrackTargetWrapper
HudTrackVM.BadietaTrackTargetWrapper = BadietaTrackTargetWrapper
HudTrackVM.SpecialIconTrackTargetWrapper = SpecialIconTrackTargetWrapper
HudTrackVM.MissionTrackTargetWrapper = MissionTrackTargetWrapper
HudTrackVM.ActorHurtTrackTargetWrapper = ActorHurtTrackTargetWrapper
return HudTrackVM
