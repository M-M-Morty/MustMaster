require "UnLua"

-- Custom target filter.
local G = require("G")
local SkillUtils = require("common.skill_utils")

local TargetFilter = Class()

function TargetFilter:ctor(SelfActor, FilterType, FilterIdentity)
    self.SelfActor = SelfActor
    self.FilterType = FilterType
    self.FilterIdentity = FilterIdentity or Enum.Enum_CharIdentity.All
end

function TargetFilter:FilterActor(ActorToBeFiltered, NeedLock)
    if not UE.UKismetSystemLibrary.IsValid(ActorToBeFiltered) then
        return false
    end

    local bPass = true
    if self.FilterType == Enum.Enum_CalcFilterType.All then
        bPass = true
    elseif self.FilterType == Enum.Enum_CalcFilterType.Self then
        bPass = ActorToBeFiltered == self.SelfActor
    elseif self.FilterType == Enum.Enum_CalcFilterType.NoSelf then
        bPass = ActorToBeFiltered ~= self.SelfActor

    elseif self.FilterType == Enum.Enum_CalcFilterType.AllEnemy then
        bPass = SkillUtils.IsEnemy(self.SelfActor, ActorToBeFiltered)
    elseif self.FilterType == Enum.Enum_CalcFilterType.AliveEnemy then
        bPass = SkillUtils.IsEnemy(self.SelfActor, ActorToBeFiltered)
        bPass = bPass and (not self:IsDead(ActorToBeFiltered))
    elseif self.FilterType == Enum.Enum_CalcFilterType.DeadEnemy then
        bPass = SkillUtils.IsEnemy(self.SelfActor, ActorToBeFiltered)
        bPass = bPass and self:IsDead(ActorToBeFiltered)

    elseif self.FilterType == Enum.Enum_CalcFilterType.AllAlly then
        bPass = SkillUtils.IsAlly(self.SelfActor, ActorToBeFiltered)
    elseif self.FilterType == Enum.Enum_CalcFilterType.AliveAlly then
        bPass = SkillUtils.IsAlly(self.SelfActor, ActorToBeFiltered)
        bPass = bPass and (not self:IsDead(ActorToBeFiltered))
    elseif self.FilterType == Enum.Enum_CalcFilterType.DeadAlly then
        bPass = SkillUtils.IsAlly(self.SelfActor, ActorToBeFiltered)
        bPass = bPass and self:IsDead(ActorToBeFiltered)

    elseif self.FilterType == Enum.Enum_CalcFilterType.AllNeutral then
        bPass = SkillUtils.IsNeutral(self.SelfActor, ActorToBeFiltered)
    elseif self.FilterType == Enum.Enum_CalcFilterType.AliveNeutral then
        bPass = SkillUtils.IsNeutral(self.SelfActor, ActorToBeFiltered)
        bPass = bPass and (not self:IsDead(ActorToBeFiltered))
    elseif self.FilterType == Enum.Enum_CalcFilterType.DeadNeutral then
        bPass = SkillUtils.IsNeutral(self.SelfActor, ActorToBeFiltered)
        bPass = bPass and self:IsDead(ActorToBeFiltered)

    else
        G.log:warn("santi", "TargetFilter not implement filter type: %s", self.FilterType)
    end

    -- G.log:error("yj", "FilterIdentity %s %s %s", bPass, self.FilterIdentity, ActorToBeFiltered.CharIdentity)
    if self.FilterIdentity ~= Enum.Enum_CharIdentity.All then
        bPass = bPass and self.FilterIdentity == ActorToBeFiltered.CharIdentity
    end

    if NeedLock == true and ActorToBeFiltered.bLockable == false then
        bPass = false
    end

    -- TODO RequiredActorClass check.

    if self.bReverseFilter then
        return not bPass
    end

    return bPass
end

function TargetFilter:IsDead(TargetActor)
    return TargetActor.IsDead and TargetActor:IsDead()
end

return TargetFilter
