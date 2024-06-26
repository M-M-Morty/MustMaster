

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local MultiBase = require('CP0032305_GH.Script.actors.common.TargetActor_GH_Multi')

---@type TargetActor_Snail_Skill_06_C
local TargetActor_Snail_Skill_06_C = Class(MultiBase)

function TargetActor_Snail_Skill_06_C:UserConstructionScript()
    --self.Overridden.UserConstructionScript(self)
    Super(TargetActor_Snail_Skill_06_C).UserConstructionScript(self)

    self.vOverlapingActorsMap = UE.TMap(UE.AActor, UE.FActiveGameplayEffectHandle)

    self.collision_base_radius = self.Collision:GetUnscaledSphereRadius()
    local radius = self.DURATION_RADIUS:GetFloatValue(0)
    self.Collision:SetSphereRadius(radius * self.collision_base_radius, true)
end
function TargetActor_Snail_Skill_06_C:ReceiveEndPlay(EndPlayReason)
    Super(TargetActor_Snail_Skill_06_C).ReceiveEndPlay(self, EndPlayReason)

    for k, v in pairs(self.vOverlapingActorsMap) do
        local actor = k
        local Handle = v
        if actor and Handle then
            self:RemoveGameplayEffect(actor, Handle)
        end
    end
    self.vOverlapingActorsMap:Clear()
end
function TargetActor_Snail_Skill_06_C:ReceiveTick(DeltaSeconds)
    Super(TargetActor_Snail_Skill_06_C).ReceiveTick(self, DeltaSeconds)

    if self.start_time and FunctionUtil:FloatNotZero(self.DURATION_SECOND) then
        local current = UE.UGameplayStatics.GetTimeSeconds(self)
        local radius = self.DURATION_RADIUS:GetFloatValue((current - self.start_time) / self.DURATION_SECOND)
        self.Collision:SetSphereRadius(radius * self.collision_base_radius, true)
    end
end

function TargetActor_Snail_Skill_06_C:OnStartTargeting(Ability)
    Super(TargetActor_Snail_Skill_06_C).OnStartTargeting(self, Ability)

    self.start_time = UE.UGameplayStatics.GetTimeSeconds(self)
end

function TargetActor_Snail_Skill_06_C:OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    --UnLua.LogWarn('TargetActor_GH_Multi:OnComponentBeginOverlap', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(OtherActor))

    Super(TargetActor_Snail_Skill_06_C).OnComponentBeginOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    
    if FunctionUtil:IsPlayer(OtherActor) then
        local Handle = self.vOverlapingActorsMap:Find(OtherActor)
        if not Handle then
            Handle = self:AddGameplayEffect(OtherActor)
            if Handle then
                self.vOverlapingActorsMap:Add(OtherActor, Handle)
            end
        end
    end
end
function TargetActor_Snail_Skill_06_C:OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    --UnLua.LogWarn('TargetActor_GH_Multi:OnComponentEndOverlap', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(OtherActor))

    Super(TargetActor_Snail_Skill_06_C).OnComponentEndOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)

    if FunctionUtil:IsPlayer(OtherActor) then
        local Handle = self.vOverlapingActorsMap:Find(OtherActor)
        if Handle then
            self:RemoveGameplayEffect(OtherActor, Handle)
            self.vOverlapingActorsMap:Remove(OtherActor)
        end
    end
end

function TargetActor_Snail_Skill_06_C:AddGameplayEffect(tarActor)
    local ASC = tarActor:GetAbilitySystemComponent()
    if ASC then
        local GE_SpecHandle = ASC:MakeOutgoingSpec(self.DURATION_GE, 1, UE.FGameplayEffectContextHandle())
        local GE_Handle = ASC:BP_ApplyGameplayEffectSpecToSelf(GE_SpecHandle)
        return GE_Handle
    end
end
function TargetActor_Snail_Skill_06_C:RemoveGameplayEffect(tarActor, Handle)
    local ASC = tarActor:GetAbilitySystemComponent()
    if ASC and Handle then
        ASC:RemoveActiveGameplayEffect(Handle, -1)
    end
end


return TargetActor_Snail_Skill_06_C

