-- Charge GA.
local G = require("G")
local GAPlayerBase = require("skill.ability.GAPlayerBase")
local StateConflictData = require("common.data.state_conflict_data")
local GACharge = Class(GAPlayerBase)

GACharge.__replicates = {
}

function GACharge:K2_PostTransfer()
    Super(GACharge).K2_PostTransfer(self)
end

function GACharge:HandleActivateAbility()
    Super(GACharge).HandleActivateAbility(self)

    if self:IsClient() then
        self.CurChargeEndInd = -1

        -- 客户端触发进入零重力
        self:TryEnterZeroGravity(self.MaxChargeTime)

        self.BeginChargeTime = UE.UKismetMathLibrary.Now()
        self:_InitMaxChargeTimer()

        self.GCTags = {}
        -- Execute InCharge GC.
        if self.InChargeTag then
            self:Server_AddGameplayCue(self.InChargeTag)
            table.insert(self.GCTags, self.InChargeTag)
        end
    end
end

function GACharge:_InitMaxChargeTimer()
    self:_StopMaxChargeTimer()

    self.MaxChargeTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.ChargeReachMaxTime}, self.MaxChargeTime + 0.1,false)
end

function GACharge:_StopMaxChargeTimer()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.MaxChargeTimer)
end

function GACharge:ChargeReachMaxTime()
    G.log:debug(self.__TAG__, "Charge success and reach max time")
    -- Execute MaxCharge GC.
    if self.MaxChargeTag then
        self:Server_AddGameplayCue(self.MaxChargeTag)
    end

    if self:HandleChargeEnd() then
        return
    end

    self:K2_EndAbility()
end

function GACharge:Tick(DeltaSeconds)
    if self:IsClient() then
        self:CheckReachEndItem()
    end
end

function GACharge:KeyUp()
    if self.bEnd or self.bInEndState then
        return
    end

    G.log:debug(self.__TAG__, "KeyUp")
    if self:HandleChargeEnd() then
        return
    end

    self:K2_EndAbility()
end

---持续按下时，提示蓄力进入新阶段的特效.
function GACharge:CheckReachEndItem()
    local ChargeTime = utils.GetSecondsUntilNow(self.BeginChargeTime)
    local CurEndItem, CurEndInd = self:GetChargeEndItem(ChargeTime)
    if CurEndItem == nil or CurEndInd == -1 or CurEndInd == self.CurChargeEndInd then
        return
    end
    self.CurChargeEndInd = CurEndInd

    G.log:debug(self.__TAG__, "Charge reach new EndItem index: %d", self.CurChargeEndInd)
    if CurEndItem.EffectTag then
        self:Server_AddGameplayCue(CurEndItem.EffectTag)
        table.insert(self.GCTags, CurEndItem.EffectTag)
    end

    return
end

---蓄力结束的 end 动作、特效、零重力等.
function GACharge:HandleChargeEnd()
    if self.bInEndState then
        return true
    end

    self:CheckReachEndItem()

    local ChargeTime = utils.GetSecondsUntilNow(self.BeginChargeTime)
    local CurEndItem, EndInd = self:GetChargeEndItem(ChargeTime)
    if not CurEndItem then
        return false
    end

    G.log:debug(self.__TAG__, "HandleChargeEnd end step index: %d", EndInd)

    -- Enter zero gravity for play end.
    self:TryEnterZeroGravity(CurEndItem.ZeroGravityTime)

    -- End pre state and enter skill state.
    self.OwnerActor:SendMessage("EndState", StateConflictData.State_ChargePre)
    self.OwnerActor:SendMessage("EnterState", StateConflictData.State_Skill)

    self:PlayChargeEnd(CurEndItem.Montage)
    self:Server_PlayChargeEnd(CurEndItem.Montage)

    return true
end

function GACharge:GetChargeEndItem(ChargeTime)
    local ChargeEndItems = self.ChargeEndItems
    for Ind = ChargeEndItems:Length(), 1, -1 do
        local Item = ChargeEndItems:Get(Ind)
        if ChargeTime >= Item.Time then
            return Item, Ind
        end
    end

    return nil, -1
end

function GACharge:TryEnterZeroGravity(ZGTime)
    if not SkillUtils.IsInAirChargeSkill(self.SkillType) then
        return
    end

    -- Charge start and loop always in zero gravity.
    self.ZGHandle = self.OwnerActor.ZeroGravityComponent:EnterZeroGravity(ZGTime, false)
end

function GACharge:TryEndZeroGravity()
    if not SkillUtils.IsInAirChargeSkill(self.SkillType) then
        return
    end

    self.OwnerActor.ZeroGravityComponent:EndZeroGravity(self.ZGHandle)
end

function GACharge:ClearAllGCTags()
    for _, Tag in ipairs(self.GCTags) do
        self:Server_RemoveGameplayCue(Tag)
    end
end

function GACharge:HandlePlayMontage()
    if not self.ChargeStartMontage then
        self:K2_EndAbility()
        return
    end

    G.log:debug(self.__TAG__, "Play charge start montage: %s", G.GetObjectName(self.ChargeStartMontage))
    self.bInEndState = false
    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, "", self.ChargeStartMontage, 1.0, nil, true, 1.0, 0)
    PlayTask.OnCompleted:Add(self, self.OnChargeStartCompleted)
    PlayTask.OnBlendOut:Add(self, self.OnChargeStartBlendOut)
    PlayTask.OnInterrupted:Add(self, self.OnChargeStartInterrupted)
    PlayTask.OnCancelled:Add(self, self.OnChargeStartCancelled)
    PlayTask:ReadyForActivation()
    self:AddTaskRefer(PlayTask)
end

function GACharge:OnChargeStartCompleted()
    G.log:debug(self.__TAG__, "OnChargeStartCompleted")
    if not self.bInEndState then
        self:PlayChargeLoop()
    end
end
UE.DistributedDSLua.RegisterFunction("OnChargeStartCompleted", GACharge.OnChargeStartCompleted)

function GACharge:OnChargeStartBlendOut()
    G.log:debug(self.__TAG__, "OnChargeStartBlendOut")
    if not self.bInEndState then
        self:PlayChargeLoop()
    end
end
UE.DistributedDSLua.RegisterFunction("OnChargeStartBlendOut", GACharge.OnChargeStartBlendOut)

function GACharge:OnChargeStartCancelled()
    G.log:debug(self.__TAG__, "OnChargeStartCancelled")
    if not self.bInEndState then
        self:K2_EndAbility()
    end
end
UE.DistributedDSLua.RegisterFunction("OnChargeStartCancelled", GACharge.OnChargeStartCancelled)

function GACharge:OnChargeStartInterrupted()
    G.log:debug(self.__TAG__, "OnChargeStartInterrupted")
    if not self.bInEndState then
        self:K2_EndAbility()
    end
end
UE.DistributedDSLua.RegisterFunction("OnChargeStartInterrupted", GACharge.OnChargeStartInterrupted)

function GACharge:PlayChargeLoop()
    if not self.ChargeLoopMontage then
        G.log.debug(self.__TAG__, "Charge loop montage is nil, then Cancel Charge GA")
        self:K2_EndAbility()
        return
    end

    G.log:debug(self.__TAG__, "Play charge loop montage: %s", G.GetObjectName(self.ChargeLoopMontage))
    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, "", self.ChargeLoopMontage, 1.0, nil, true, 1.0, 0)
    PlayTask.OnCompleted:Add(self, self.OnChargeLoopCallback)
    PlayTask.OnBlendOut:Add(self, self.OnChargeLoopCallback)
    PlayTask.OnInterrupted:Add(self, self.OnChargeLoopCallback)
    PlayTask.OnCancelled:Add(self, self.OnChargeLoopCallback)
    PlayTask:ReadyForActivation()
    self:AddTaskRefer(PlayTask)
end

function GACharge:OnChargeLoopCallback()
    -- Do nothing.
end
UE.DistributedDSLua.RegisterFunction("OnChargeLoopCallback", GACharge.OnChargeLoopCallback)

function GACharge:PlayChargeEnd(Montage)
    self.bInEndState = true

    --self:FaceToTarget()

    G.log:debug(self.__TAG__, "Play charge end montage: %s", G.GetObjectName(Montage))
    local PlayEndTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, "", Montage, 1.0, nil, true, 1.0, 0)
    PlayEndTask.OnCompleted:Add(self, self.PlayChargeEndCallback)
    PlayEndTask.OnBlendOut:Add(self, self.PlayChargeEndCallback)
    PlayEndTask.OnInterrupted:Add(self, self.PlayChargeEndCallback)
    PlayEndTask.OnCancelled:Add(self, self.PlayChargeEndCallback)
    PlayEndTask:ReadyForActivation()
    self:AddTaskRefer(PlayEndTask)
end

-- Face to target when charge attack out.
function GACharge:FaceToTarget()
    -- Init already face to target, no need do again.
    if self.AssistInfo.bFaceTarget then
        return
    end

    local OwnerActor = self:GetAvatarActorFromActorInfo()

    local TargetActor, TargetActorTransform, bValidTransform = self:GetSkillTarget()
    local TargetLocation
    if TargetActor then
        TargetLocation = TargetActor:K2_GetActorLocation()
    elseif TargetActorTransform and bValidTransform then
        TargetLocation = TargetActorTransform.Translation
    end

    if TargetLocation then
        local selfLocation = OwnerActor:K2_GetActorLocation()
        local DirToTarget = TargetLocation - selfLocation
        UE.UKismetMathLibrary.Vector_Normalize(DirToTarget)
        local ToRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(DirToTarget)

        local CustomSmoothContext = UE.FCustomSmoothContext()
        OwnerActor:GetLocomotionComponent():SetCharacterRotation(ToRotation, false, CustomSmoothContext)
        OwnerActor:GetLocomotionComponent():Server_SetCharacterRotation(ToRotation, false, CustomSmoothContext)

        if TargetActor then
            -- Auto rotate camera to face enemy
            local PlayerCameraManager = UE.UGameplayStatics.GetPlayerController(OwnerActor:GetWorld(), 0).PlayerCameraManager
            PlayerCameraManager:PlayAnimation_WatchTarget(TargetActor)
        end
    end
end

function GACharge:PlayChargeEndCallback()
    self:K2_EndAbility()
end
UE.DistributedDSLua.RegisterFunction("PlayChargeEndCallback", GACharge.PlayChargeEndCallback)

function GACharge:HandleEndAbility(bWasCancelled)
    Super(GACharge).HandleEndAbility(self, bWasCancelled)

    self.bInEndState = false

    if self:IsClient() then
        self:ClearAllGCTags()
        self:TryEndZeroGravity()
        self:_StopMaxChargeTimer()
        self:ClearRenderParams()
    end
end

-- TODO 给美术填坑，蓄力分为 start/loop/end 3 个阶段，每个阶段播蒙太奇时，美术 未经协商 配置了后处理的 sequence。
-- 如果中间蒙太奇被打断，sequence 中的一些数据（比如 MPC 的参数)，要恢复。
function GACharge:ClearRenderParams()
    if self.ClearMPC then
        local Keys = self.ClearMPCFloatParams:Keys()
        for Ind = 1, Keys:Length() do
            local ParamName = Keys:Get(Ind)
            local ParamValue = self.ClearMPCFloatParams:Find(ParamName)
            UE.UKismetMaterialLibrary.SetScalarParameterValue(self.OwnerActor:GetWorld(), self.ClearMPC, ParamName, ParamValue)
        end
    end
end

-- 处理切人时技能处于charge start/loop，owning client向server发送的rpc失效，导致服务器技能无法正常结束
function GACharge:HandleSwitchOut()
    self:K2_EndAbility()
end

UE.DistributedDSLua.RegisterCustomClass("GACharge", GACharge, GAPlayerBase)

return GACharge
