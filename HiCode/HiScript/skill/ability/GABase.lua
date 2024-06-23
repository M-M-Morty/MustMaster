local G = require("G")

local GABase = Class()
local decorator = GABase.decorator

-- 需要迁移的本地变量
GABase.__replicates = {
}

-- 迁移后，新的 GA 会调用这个接口。在这里写一些重新初始化的逻辑，迁移后的 GA 不会执行 K2_ActivateAbility.
function GABase:K2_PostTransfer()
    self.OwnerActor = self:GetAvatarActorFromActorInfo()
    if self.OwnerActor then
        self.Owner = self.OwnerActor.SkillComponent
    end
    self.__TAG__ = string.format("(%s, server: %s)", G.GetObjectName(self), self:IsServer())
end

function GABase:K2_OnGiveAbility()
    -- DDS 环境下 CDO 对象会调用到这里触发断言.
    self.OwnerActor = self:GetAvatarActorFromActorInfo()
    self.Owner = self.OwnerActor.SkillComponent
end

function GABase:K2_CommitAbility()
    if self.bDisabled then
        return false
    end

    return self.Overridden.K2_CommitAbility(self)
end

function GABase:K2_CanActivateAbility(ActorInfo, GASpecHandle, OutTags)
    G.log:info("GABase", "%s K2_CanActivateAbility bDisabled: %s", G.GetObjectName(self), self.bDisable)
    if self.bDisabled then
        return false
    end

    return true
end

function GABase:K2_GetCostGameplayEffect()
    -- 技能可选择性的关闭消耗
    if not self.bEnableCost then
        return nil
    end

    return self.Overridden.K2_GetCostGameplayEffect(self)
end

function GABase:EnableCost(bEnableCost)
    self.bEnableCost = bEnableCost
end

function GABase:OnActivateAbility()
    self.__TAG__ = string.format("(%s, server: %s)", G.GetObjectName(self), self:IsServer())
    G.log:debug(self.__TAG__, "OnActivateAbility")

    self.bEnd = false
    self.OwnerActor = self:GetAvatarActorFromActorInfo()
    self.Owner = self.OwnerActor.SkillComponent
    if self.bEnableTick then
        self.TickHandle = self.OwnerActor:RegisterTickCallback(self, self.TickCallback)
    end

    self.SkillID = self:GetSkillID()
end

-- Default implement of activate ability. Should override by sub class.
function GABase:HandleActivateAbility()
    self:HandlePlayMontage()
    self:HandleComboTail()
    self:HandleMovementAndStateWhenActivate()
end

function GABase:TickCallback(DeltaSeconds)
    if self.bEnd then
        return
    end

    self:Tick(DeltaSeconds)
end

function GABase:Tick(DeltaSeconds)

end

function GABase:HandlePlayMontage(Montage)
    if not Montage then
        Montage = self:GetMontageToPlay()
    end

    if Montage then
        G.log:debug(self.__TAG__, "HandlePlayMontage: %s", G.GetObjectName(Montage))
        local OffsetTime = self:GetStartOffsetTime()
        local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, "", Montage, 1.0, nil, true, 1.0, OffsetTime)
        PlayTask.OnCompleted:Add(self, self.OnCompleted)
        PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
        PlayTask.OnInterrupted:Add(self, self.OnInterrupted)
        PlayTask.OnCancelled:Add(self, self.OnCancelled)
        PlayTask:ReadyForActivation()
        self:AddTaskRefer(PlayTask)
    else
        G.log:debug(self.__TAG__, "MontageToPlay not config.")
    end
end

function GABase:HandleComboTail()
    local WaitComboTailTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, self.ComboTailTag, nil, false, false)
    WaitComboTailTask.EventReceived:Add(self, self.OnComboTailEvent)
    WaitComboTailTask:ReadyForActivation()
    self:AddTaskRefer(WaitComboTailTask)
end

function GABase:HandleMovementAndStateWhenActivate()
end

function GABase:PlayMontageWithCallback(Mesh, Montage, PlayRate, InterruptedCallback, CompletedCallback, BlendOutCallback)
    local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(Mesh, Montage, PlayRate)

    if InterruptedCallback then
        local InterruptedFunc = function(name)
            InterruptedCallback(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self, InterruptedFunc)
    end

    if CompletedCallback then
        local CompletedFunc = function(name)
            CompletedCallback(self, name)
        end
        PlayMontageCallbackProxy.OnCompleted:Add(self, CompletedFunc)
    end

    if BlendOutCallback then
        local BlendOutFunc = function(name)
            BlendOutCallback(self, name)
        end
        PlayMontageCallbackProxy.OnBlendOut:Add(self, BlendOutFunc)
    end

    self.ObjectReferList:Add(PlayMontageCallbackProxy)
end

decorator.dds_function()
function GABase:OnMontageCompleted(...)
    self:OnCompleted()
end

decorator.dds_function()
function GABase:OnMontageInterrupted(...)
    self:OnInterrupted()
end

decorator.dds_function()
function GABase:OnMontageBlendOut(...)
    self:OnBlendOut()
end

decorator.dds_function()
function GABase:OnCompleted()
    G.log:debug(self.__TAG__, "GABase %s OnCompleted, IsServer: %s.", G.GetDisplayName(self), self:IsServer())

    self:K2_EndAbility()
end

decorator.dds_function()
function GABase:OnBlendOut()
    G.log:debug(self.__TAG__, "GABase %s OnBlendOut, IsServer: %s.", G.GetDisplayName(self), self:IsServer())

    self:K2_EndAbility()
end

decorator.dds_function()
function GABase:OnInterrupted()
    G.log:debug(self.__TAG__, "GABase %s OnInterrupted, IsServer: %s.", G.GetDisplayName(self), self:IsServer())

    self:K2_EndAbility()
end

decorator.dds_function()
function GABase:OnCancelled()
    G.log:debug(self.__TAG__, "GABase %s OnCancelled, IsServer: %s.", G.GetDisplayName(self), self:IsServer())

    self:K2_EndAbility()
end

decorator.dds_function()
function GABase:OnComboTailEvent(Payload)
    -- TODO 迁移后的 GA 以及其中的 AbilityTasks 处于未处理状态，导致这里在 ServerSimulatedProxy 上也能收到回调，需要屏蔽.
    if self.OwnerActor:GetLocalRole() == UE.ENetRole.ROLE_ServerSimulatedProxy then
        return
    end

    G.log:debug(self.__TAG__, "OnComboTailEvent, Role: %d", self.OwnerActor:GetLocalRole())
    self:SetShouldBlockOtherAbilities(false)
    self:SetCanBeCanceled(true)

    self:HandleComboTailState(Payload)

    local SkillID = self:GetSkillID()
    self.OwnerActor:SendMessage("OnComboTail", SkillID)
end

-- Should override by subclass.
function GABase:HandleComboTailState(Payload)
end

---技能施加的 GE 将目标打成失衡状态的回调
function GABase:OnTargetEnterOutBalance()
    G.log:debug(self.__TAG__, "OnTargetEnterOutBalance")
end

function GABase:GetStartOffsetTime()
    local UserData = self:GetCurrentUserData()
    if not UserData then
        return 0
    end

    return UserData.StartOffsetTime
end

---return SkillTarget, SkillTargetTransform, bValidTransform, SkillTargetComponent
function GABase:GetSkillTarget()
    local UserData = self:GetCurrentUserData()
    if not UserData then
        return nil, nil, nil
    end

    return UserData.SkillTarget, UserData.SkillTargetTransform, UserData.bValidTransform, UserData.SkillTargetComponent
end

function GABase:GetSkillID()
    local UserData = self:GetCurrentUserData()
    if not UserData then
        return -1
    end

    return UserData.SkillID
end

function GABase:ResetUserData()
    local UserData = self:GetCurrentUserData()
    UserData.StartOffsetTime = 0
    UserData.SkillTarget = nil
    UserData.SkillTargetComponent = nil
    UserData.bValidTransform = false
    UserData.SkillTargetTransform = UE.UKismetMathLibrary.MakeTransform()
end

--[[
    End ability
    ]]
function GABase:K2_OnEndAbility(bWasCancelled)
    G.log:debug(self.__TAG__, "K2_OnEndAbility, bWasCancelled: %s", bWasCancelled)

    self.bEnd = true
    self:ClearTasks()
    self.ObjectReferList:Clear()
    self:SetOwnerBoneServerUpdate(false)
    self:HandleEndAbility(bWasCancelled)
end

-- Should override by subclass.
function GABase:HandleEndAbility(bWasCancelled)
    if self.TickHandle and self.TickHandle > 0 then
        self.OwnerActor:UnRegisterTickCallback(self.TickHandle)
    end

    self:ClearSpeed()
    local UserData = self:GetCurrentUserData()
    if UserData then
        -- Notify owner actor.
        -- TODO Attention if GiveAbility not with UserData, this will not invoke callback to SkillComponent.
        self.OwnerActor:SendMessage("OnEndAbility", UserData.SkillID, self.SkillType)

        -- Reset dynamic UserData which maybe changed during GA run.
        self:ResetUserData()
    else
        self.OwnerActor:SendMessage("OnEndAbility", nil, nil)
    end

    self:HandleMovementAndStateWhenEnd(bWasCancelled)
end

function GABase:HandleMovementAndStateWhenEnd(bWasCancelled)

end

function GABase:ClearSpeed()
    self.OwnerActor.Mesh:SetPhysicsLinearVelocity(UE.FVector())
    self.OwnerActor.Mesh:SetPhysicsAngularVelocityInDegrees(UE.FVector())
    self.OwnerActor:ClearVelocityAndAcceleration()
end

function GABase:GetMontageToPlay()
    return self.MontageToPlay
end

function GABase:IsServer()
    return self:K2_HasAuthority()
end

function GABase:IsClient()
    return not self:IsServer()
end

-- Add task reference to avoid gc by ue.
function GABase:AddTaskRefer(AbilityTask)
    self.Tasks:Add(AbilityTask)
end

function GABase:ClearTasks()
    self.Tasks:Clear()
end

function GABase:SetDisabled(bDisabled)
    self.bDisabled = bDisabled
end

function GABase:SetOwnerBoneServerUpdate(bEnabled)
    local flag = bEnabled and self.bEnableServerBoneUpdate
    if flag then
        self.OwnerActor.Mesh.VisibilityBasedAnimTickOption = UE.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
    else
        self.OwnerActor.Mesh.VisibilityBasedAnimTickOption = UE.EVisibilityBasedAnimTickOption.AlwaysTickPose
    end
end

function _MakeActorArray(Actor)
    local Arr = UE.TArray(UE.AActor)
    Arr:Add(Actor)
    return Arr
end

UE.DistributedDSLua.RegisterCustomClass("GABase", GABase)

return GABase
