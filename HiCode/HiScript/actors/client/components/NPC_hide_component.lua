--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local GameConstData = require("common.data.game_const_data").data
local SubsystemUtils = require("common.utils.subsystem_utils")


---@type NPCHideComponent_C
local NPCHideComponent = Component(ComponentBase)
local decorator = NPCHideComponent.decorator


function NPCHideComponent:GetActor(ActorID)
    if self.actor:IsClient() then
        return SubsystemUtils.GetMutableActorSubSystem(self):GetClientMutableActor(ActorID)
    else
        return SubsystemUtils.GetMutableActorSubSystem(self):GetActor(ActorID)
    end
end


--隐藏当前交互的NPC
function NPCHideComponent:HideInteractNPC()
    local CurInteractNpc = self.actor:K2_GetPawn().PlayerUIInteractComponent.CurInteractNpc
    if CurInteractNpc ~= nil and CurInteractNpc.ActorId ~=nil then
        local InteractNpc=self:GetActor(CurInteractNpc.ActorId)
        if InteractNpc then
            InteractNpc:SetActorHiddenInGame(true)
            self.InteractNpcIDList:AddUnique(CurInteractNpc.ActorId)
        end
    end
end


--显示当前交互的NPC（由HideInteractNPC函数隐藏的）
function NPCHideComponent:ShowInteractNPC()
    for idx=1,self.InteractNpcIDList:Length() do
        local NpcID=self.InteractNpcIDList:Get(idx)
        local InteractNpc=self:GetActor(NpcID)
        if InteractNpc then
            InteractNpc:SetActorHiddenInGame(false)
        end
    end
    self.InteractNpcIDList:Clear()
end


--隐藏周围一定距离内的NPC，半径单位为m
function NPCHideComponent:HideNearbyNPC(HideRadius)
    
    --如果没有传入HideRadius,则使用游戏常量表中的常数,单位为m
    if HideRadius == nil then 
        HideRadius = GameConstData.NPC_HIDE_RANGE.FloatValue*100
    end
    local Location = self.actor:K2_GetPawn():K2_GetActorLocation()
    local OutHits = UE.TArray(UE.FHitResult)
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(self.actor)
    ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
    UE.UKismetSystemLibrary.SphereTraceMultiForObjects(
            self.actor:GetWorld(), Location, Location, HideRadius,ObjectTypes, false, ActorsToIgnore, UE.EDrawDebugTrace.None, OutHits, true)
    for idx = 1, OutHits:Length() do
        local HitActor = OutHits:Get(idx).Component:GetOwner()
        if HitActor.CharIdentity == Enum.Enum_CharIdentity.NPC then
            self.NearbyNpcIDList:AddUnique(HitActor:GetActorID())
        end
    end
    for idx=1,self.NearbyNpcIDList:Length() do
        local NpcID=self.NearbyNpcIDList:Get(idx)
        local InteractNpc=self:GetActor(NpcID)
        if InteractNpc then
            InteractNpc:SetActorHiddenInGame(true)
        end
    end
end


--显示周围一定距离内的NPC（由HideNearbyNPC函数隐藏的）
function NPCHideComponent:ShowNearbyNPC()
    for idx=1,self.NearbyNpcIDList:Length() do
        local NpcID=self.NearbyNpcIDList:Get(idx)
        local InteractNpc=self:GetActor(NpcID)
        if InteractNpc then
            InteractNpc:SetActorHiddenInGame(false)
        end
    end
    self.NearbyNpcIDList:Clear()
end


--显示所有被隐藏的NPC
function NPCHideComponent:ShowAllNPC()
    self:ShowInteractNPC()
    self:ShowNearbyNPC()
end


return NPCHideComponent
