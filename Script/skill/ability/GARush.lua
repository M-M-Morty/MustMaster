-- Rush GA.
local G = require("G")
local GASkillBase = require("skill.ability.GAPlayerBase")

local GARush = Class(GASkillBase)

function GARush:HandleActivateAbility()
    G.log:debug(self.__TAG__, "%s K2_ActivateAbility, IsServer: %s", G.GetDisplayName(self), self:IsServer())
    self.Projectiles = {}
    self.ApplyToSelfMap = {}
    self.AttachActors:Clear()

    self:HandleMovementAndStateWhenActivate()

    -- Handle combo tail.
    self:HandleComboTail()

    -- Handle for exec calculation.
    self:HandleCalc()

    -- Handle apply ge to self calc event.
    self:HandleApplyToSelfCalc()

    -- Handle apply ge to target calc event.
    self:HandleApplyToTargetCalc()

    self:PlayBeginMontage()
end

function GARush:PlayBeginMontage()
    if self.StartMontage then
        G.log:debug(self.__TAG__, "Play start montage: %s, IsServer: %s", G.GetDisplayName(self.StartMontage), self:IsServer())
        local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, "", self.StartMontage, 1.0, nil, true, 1.0)
        PlayTask.OnCompleted:Add(self, self.OnStartMontageCompleted)
        PlayTask.OnBlendOut:Add(self, self.OnStartMontageBlendOut)
        PlayTask.OnInterrupted:Add(self, self.OnStartMontageInterrupted)
        PlayTask.OnCancelled:Add(self, self.OnStartMontageCancelled)
        PlayTask:ReadyForActivation()
        self:AddTaskRefer(PlayTask)
    else
        G.log:warn(self.__TAG__, "%s no StartMontage configured, end ability.", G.GetDisplayName(self))
        self:K2_EndAbility()
    end
end

function GARush:OnStartMontageCompleted()
    self:PlayLoopMontage()
end

function GARush:OnStartMontageBlendOut()
    self:PlayLoopMontage()
end

function GARush:OnStartMontageInterrupted()
    self:K2_EndAbility()
end

function GARush:OnStartMontageCancelled()
    self:K2_EndAbility()
end

function GARush:PlayLoopMontage()

    if self.LoopMontage then
        G.log:debug(self.__TAG__, "Play loop montage: %s, IsServer: %s", G.GetDisplayName(self.LoopMontage), self:IsServer())
        local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, "", self.LoopMontage, 1.0, nil, true, 1.0)
        PlayTask.OnBlendOut:Add(self, self.OnLoopMontageBlendOut)
        PlayTask.OnInterrupted:Add(self, self.OnLoopMontageInterrupted)
        PlayTask.OnCancelled:Add(self, self.OnLoopMontageCancelled)
        PlayTask:ReadyForActivation()
        self:AddTaskRefer(PlayTask)

        -- 冲刺由服务器发起
        if self:K2_HasAuthority() then
            self:BeginRush()
        end
    else
        G.log:warn(self.__TAG__, "%s no LoopMontage configured, end ability.", G.GetDisplayName(self))
        self:K2_EndAbility()
    end
end

function GARush:OnHitTarget(ObjectType, Hit, ApplicationTag)
    local HitActor = Hit.Component:GetOwner()
    if self.bHitAttach and HitActor and HitActor.InteractionComponent then
        G.log:debug(self.__TAG__, "%s IsServer: %s, ApplicationTag: %s OnHitTarget objectType: %d, actor: %s",
                G.GetObjectName(self), self:IsServer(), GetTagName(ApplicationTag), ObjectType, G.GetObjectName(HitActor))
        if self.AttachActors:Find(HitActor) == 0 then
            self.AttachActors:AddUnique(HitActor)
            HitActor.InteractionComponent:OnRushAttach(self.OwnerActor)
        end
    end
end

function GARush:OnLoopMontageCompleted()
    self:PlayEndMontage()
end

function GARush:OnLoopMontageBlendOut()
    self:PlayEndMontage()
end

function GARush:OnLoopMontageInterrupted()
    self:PlayEndMontage()
end

function GARush:OnLoopMontageCancelled()
    self:K2_EndAbility()
end

function GARush:BeginRush()
    local UserData = self:GetCurrentUserData()
    local TargetActor = UserData.SkillTarget
    local TargetComponent = UserData.SkillTargetComponent
    local SkillID = UserData.SkillID

    local OwnerActor = self:GetAvatarActorFromActorInfo()
    if TargetComponent then
        OwnerActor:SendMessage("BeginRush", SkillID, nil, TargetComponent, false)
    elseif TargetActor then
        OwnerActor:SendMessage("BeginRush", SkillID, TargetActor, nil, false)
    else
        OwnerActor:SendMessage("BeginRush", SkillID, nil, nil, false)
    end
end

function GARush:PlayEndMontage()
    if self.bEnd then
        return
    end

    -- TODO 临时解决下技能落地时，客户端和服务器没有 OnLand 回调问题。后面得有个统一的处理方法。
    if self.OwnerActor:IsOnFloor() then
        self.OwnerActor:SendMessage("OnLand")
    end

    for Ind = 1, self.AttachActors:Length() do
        local HitActor = self.AttachActors:Get(Ind)
        if HitActor and HitActor.InteractionComponent then
            HitActor.InteractionComponent:OnEndRushAttach(self.OwnerActor)
        end
    end

    if self.EndMontage then
        G.log:debug(self.__TAG__, "Play end montage: %s, IsServer: %s", G.GetDisplayName(self.EndMontage), self:IsServer())
        local PlayEndTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, "", self.EndMontage, 1.0, nil, true, 1.0, 0)
        PlayEndTask.OnCompleted:Add(self, self.OnRushEndMontageCompleted)
        PlayEndTask.OnBlendOut:Add(self, self.OnRushEndMontageCompleted)
        PlayEndTask.OnInterrupted:Add(self, self.OnRushEndMontageInterrupted)
        PlayEndTask.OnCancelled:Add(self, self.OnRushEndMontageInterrupted)
        PlayEndTask:ReadyForActivation()
        self:AddTaskRefer(PlayEndTask)
    else
        G.log:warn(self.__TAG__, "%s no EndMontage configured, end ability.", G.GetDisplayName(self))
        self:K2_EndAbility()
    end
end

function GARush:OnRushEndMontageCompleted()
    G.log:debug(self.__TAG__, "OnRushEndMontageCompleted")
    self:K2_EndAbility()
end

function GARush:OnRushEndMontageInterrupted()
    G.log:debug(self.__TAG__, "OnRushEndMontageInterrupted")
    self:K2_EndAbility(true)
end

function GARush:HandleEndAbility(bWasCancelled)
    Super(GARush).HandleEndAbility(self, bWasCancelled)
    self.OwnerActor:SendMessage("EndRush")
end

return GARush
