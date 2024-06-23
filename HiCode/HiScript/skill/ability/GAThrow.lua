local G = require("G")
local GASkillBase = require("skill.ability.GASkillBase")
local TargetFilter = require("actors.common.TargetFilter")

local GAThrow = Class(GASkillBase)


function GAThrow:HandleActivateAbility()
    Super(GAThrow).HandleActivateAbility(self)
    self:HandleThrowEvent()
end

function GAThrow:HandleThrowEvent()
    local WaitATSCalcTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, self.ThrowPrefixTag, nil, false, false)
    WaitATSCalcTask.EventReceived:Add(self, self.OnThrowEvent)
    WaitATSCalcTask:ReadyForActivation()
    self:AddTaskRefer(WaitATSCalcTask)
end

function GAThrow:OnThrowEvent()
    if not self:CanCalc() then
        return
    end

    G.log:debug("GAThrow", "%s OnThrowEvent, IsServer: %s.", G.GetDisplayName(self), self:IsServer())

    local TargetLocation = self.OwnerActor.InteractionComponent:GetUpThrowTargetLocation()
    if UE.UKismetMathLibrary.Vector_IsZero(TargetLocation) then
        TargetLocation = self:GetThrowDefaultTargetLocation()
    end

    self.OwnerActor.InteractionComponent:ThrowTarget(TargetLocation, self.ThrowMoveSpeed, self.ThrowType ,self.ImpulseMag, self.ThrowRotateInfo)
end

function GAThrow:GetThrowTargetLocation()
    return self.OwnerActor.InteractionComponent.ThrowTargetLocation
end

 function GAThrow:GetThrowDefaultTargetLocation()
     local ActorsToIgnore = UE.TArray(UE.AActor)
     local Targets = UE.TArray(UE.AActor)
     -- TODO filter object types.
     local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
     ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
     ObjectTypes:Add(UE.EObjectTypeQuery.MountActor)
     ObjectTypes:Add(UE.EObjectTypeQuery.PhysicsBody)
     -- ObjectTypes:Add(UE.EObjectTypeQuery.Blast)
     UE.UHiCollisionLibrary.SphereOverlapActors(self.OwnerActor, ObjectTypes, self.OwnerActor:K2_GetActorLocation(),
             self.Range, self.Range, self.Range, nil, ActorsToIgnore, Targets)

     local Filter = TargetFilter.new(self.OwnerActor, Enum.Enum_CalcFilterType.AllEnemy)
     local FilteredTargets = UE.TArray(UE.AActor)
     for Ind = 1, Targets:Length() do
         local CurActor = Targets:Get(Ind)
         if Filter:FilterActor(CurActor) then
             FilteredTargets:AddUnique(CurActor)
         end
     end

     if FilteredTargets:Length() > 0 then
         return FilteredTargets:Get(1):K2_GetActorLocation()
     end

     local ForwardVector = self.OwnerActor:GetActorForwardVector()
     return self.OwnerActor:K2_GetActorLocation() + ForwardVector * self.Range
 end

function GAThrow:CanCalc()
    if self:K2_HasAuthority() then
        return true
    end

    return false
end

return GAThrow
