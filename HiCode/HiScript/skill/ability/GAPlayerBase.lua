-- Normal attack base.

local G = require("G")
local SkillUtils = require("common.skill_utils")
local MsgCode = require("common.consts").MsgCode
local TargetFilter = require("actors.common.TargetFilter")
local MoveDirConst = require("common.event_const").MoveDir
local GASkillBase = require("skill.ability.GASkillBase")
local HiCollisionLibrary = require("common.HiCollisionLibrary")
local GAPlayerBase = Class(GASkillBase)

GAPlayerBase.__replicates = {
}

function GAPlayerBase:K2_PostTransfer()
    Super(GAPlayerBase).K2_PostTransfer(self)
end

function GAPlayerBase:OnTargetEnterOutBalance()
    -- TODO why not ability instance, but CDO?

    if not self.__TAG__ then
        self.__TAG__ = G.GetObjectName(self)
    end

    if not self.SkillID then
        self.SkillID = self:GetSkillID()
    end

    Super(GAPlayerBase).OnTargetEnterOutBalance(self)

    -- 如果是登场技会触发 QTE（连续超级登场技）
    if self.bSwitchInSkill then
        G.log:debug(self.__TAG__, "SwitchIn skill: %d hit target to out balance, trigger qte.", self.SkillID)
        local OwnerActor = self:GetAvatarActorFromActorInfo()
        OwnerActor:SendMessage(MsgCode.TriggerQTE, self.SkillID)
    end
end

function GAPlayerBase:HandleEndAbility(bWasCancelled)
    Super(GAPlayerBase).HandleEndAbility(self, bWasCancelled)
    self:ResetAssistAttackTarget()    
end

function GAPlayerBase:StartSkill(Owner, OwnerActor, SkillID, CallBackOwner, StartCallback)
    -- Reset global variables.
    self.LastTarget = nil
    self.LastTargetComponent = nil
    self.LastTargetLocation = nil
    self.bCanceled = false
    self.bInRush = false
    self.Owner = Owner
    self.OwnerActor = OwnerActor
    self.SkillID = SkillID
    self.CallBackOwner = CallBackOwner
    self.StartCallback = StartCallback

    local TargetLockComp = self:HasTargetLockComponent()

    if TargetLockComp then
        -- If has lock component, use priority.
        self:_TryLockAttack()
    else
        self:_TryAssistAttack()
    end
end

function GAPlayerBase:HasTargetLockComponent()
    local LockComp = self.OwnerActor.LockComponent
    if LockComp and LockComp.GetTargetLockComponent then
        local TargetLockComp = LockComp:GetTargetLockComponent()
        return UE.UKismetSystemLibrary.IsValid(TargetLockComp),TargetLockComp
    end
    return false,nil
end

function GAPlayerBase:_TryLockAttack()
    local LockComp = self.OwnerActor.LockComponent
    if LockComp and LockComp.BeginLockAttack then
        LockComp:BeginLockAttack(self)
    end
    self:_EndLockAttack()
end

function GAPlayerBase:_EndLockAttack()
    local TargetLockComp = self:HasTargetLockComponent()
    self.LastTarget = nil
    if TargetLockComp then
        self.LastTargetComponent = TargetLockComp
        self.LastTargetLocation = TargetLockComp:K2_GetComponentLocation()
        self.LastTarget = TargetLockComp:GetOwner()
    end
    self:_TryRush()
end

function GAPlayerBase:_TryAssistAttack()
    self.LastTarget, self.LastTargetComponent = self:BeginAssistAttack()
    self:_TryRush()
end

function GAPlayerBase:_TryRush()
    self.bInRush = true
    local bEnabled = self.OwnerActor.RushComponent:BeginRushInPreSkill(self.SkillID, self.LastTarget, self.LastTargetComponent, self, self.OnEndRush)
    if not bEnabled then
        self:OnEndRush()
    end
end

function GAPlayerBase:BeginAssistAttack()
    if not self.AssistInfo or not self.AssistInfo.bEnabled then
        self:EndAssistAttack()
        return nil, nil
    end

    -- Choose target
    local Target
    if self.PresetAttackTarget then
        Target = self.PresetAttackTarget
    else
        Target, _ = self:FindNearestTarget(self.LastTarget, true, nil, false)
    end
    self:ResetAssistAttackTarget(Target)

    local ToRotation
    local TargetComp, TargetLocation
    local SelfLocation = self.OwnerActor:K2_GetActorLocation()
    if Target then
        TargetLocation, TargetComp = self:FindLockableComponent(Target)
        if TargetLocation and TargetComp then
            local DirToTarget = TargetLocation - SelfLocation
            UE.UKismetMathLibrary.Vector_Normalize(DirToTarget)
            ToRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(DirToTarget)
        else
            -- If not ignore viewport and target not visible, set no target.
            Target = nil
            TargetLocation = nil
            TargetComp = nil
        end
    else
        -- Climb attack no need this.
        if not self.bClimbAttack then
            local TargetForwardVector = self:GetInputControlForward()
            if TargetForwardVector then
                G.log:debug("SkillDriver", "Assist attack no target found rotate to control direction.")
                ToRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(TargetForwardVector)
            end
        end
    end

    if ToRotation then
        if self.bClimbAttack then
            ToRotation.Roll = 0
        else
            -- Never change roll and pitch
            ToRotation.Roll = 0
            ToRotation.Pitch = 0
        end

        -- Check bFaceTarget as some skill like climb charge will disable rotation in assist attack.
        if self.AssistInfo.bFaceTarget then
            local CustomSmoothContext = UE.FCustomSmoothContext()
            self.OwnerActor:GetLocomotionComponent():SetCharacterRotation(ToRotation, false, CustomSmoothContext)
            self.OwnerActor:GetLocomotionComponent():Server_SetCharacterRotation(ToRotation, false, CustomSmoothContext)

            -- Auto rotate camera to face enemy
            local PlayerCameraManager = UE.UGameplayStatics.GetPlayerController(self.OwnerActor:GetWorld(), 0).PlayerCameraManager
            PlayerCameraManager:PlayAnimation_WatchTarget(Target)
        end
    end

    self:EndAssistAttack()
    --G.log:debug("AssistAttack", "Assist attack skillID: %d, skillType: %d, found target: %s, comp: %s",
    --        self.SkillID, self.SkillType, G.GetDisplayName(Target), G.GetDisplayName(TargetComp))

    return Target, TargetComp
end

---Use for optimize boss attack(only rush to lockable component)
---1. If TargetComp no need rush (TargetDis < RushInfo.RushDisToTarget) return, otherwise:
---2. Find nearest TargetComp which can lockable and return, otherwise:
---3. Find any nearest TargetComp and return.
function GAPlayerBase:FindLockableComponent(Target)
    local SelfLocation = self.OwnerActor:K2_GetActorLocation()
    local bTargetVisible = utils.CheckActorInScreen(self.OwnerActor:GetWorld(), Target, SelfLocation)
    local bIgnoreViewport = self.bIgnoreViewport
    if not bIgnoreViewport and not bTargetVisible then
        G.log:debug("AssistAttack", "FindLockableComponent target not visible, no target found.")
        return nil, nil
    end

    -- Find target nearest components to attack.
    local TargetDis, TargetLocation, TargetComp = utils.GetTargetNearestDistance(SelfLocation, Target, nil)
    if (not self.RushInfo.RushEnabled or TargetDis <= self.RushInfo.RushDisToTarget)
            and (bIgnoreViewport or utils.CheckPointInScreen(self.OwnerActor:GetWorld(), TargetLocation)) then
        G.log:debug("AssistAttack", "FindLockableComponent target comp: %s, RushEnabled: %s, dis: %f, RushDisToTarget: %s",
                G.GetObjectName(TargetComp), self.RushInfo.RushEnabled, TargetDis, self.RushInfo.RushDisToTarget)
        return TargetLocation, TargetComp
    end

    local FoundDis, FoundLocation, FoundComp
    if not self.OwnerActor:IsOnFloor() then
        -- 1. Priority check InAirLockable components (ignore component visibility in case big body boss, even player jump up cant see the head!)
        local InAirLockableComps = Target:GetComponentsByTag(UE.UPrimitiveComponent, ComponentUtils.Tags.InAirLockable)
        if InAirLockableComps:Length() > 0 then
            FoundDis, FoundLocation, FoundComp = utils.GetNearestComponent(SelfLocation, InAirLockableComps)
            if FoundComp then
                G.log:debug("AssistAttack", "FindLockableComponent found InAir lockable nearest in screen comp: %s, dis: %f", G.GetObjectName(FoundComp), FoundDis)
                return FoundLocation, FoundComp
            end
        end
    end

    local LockableComps = Target:GetComponentsByTag(UE.UPrimitiveComponent, ComponentUtils.Tags.Lockable)
    local InScreenLockableComps = UE.TArray(UE.UPrimitiveComponent)
    for Ind = 1, LockableComps:Length() do
        local CurComp = LockableComps:Get(Ind)
        if utils.CheckPointInScreen(self.OwnerActor:GetWorld(), CurComp:K2_GetComponentLocation()) then
            InScreenLockableComps:Add(CurComp)
        end
    end

    -- 2. Check lockable and in screen components.
    if InScreenLockableComps:Length() > 0 then
        FoundDis, FoundLocation, FoundComp = utils.GetNearestComponent(SelfLocation, InScreenLockableComps)
        if FoundComp then
            G.log:debug("AssistAttack", "FindLockableComponent found lockable nearest in screen comp: %s, dis: %f", G.GetObjectName(FoundComp), FoundDis)
            return FoundLocation, FoundComp
        end
    end

    -- 3. Check all lockable components.
    if LockableComps:Length() > 0 then
        FoundDis, FoundLocation, FoundComp = utils.GetNearestComponent(SelfLocation, LockableComps)
        if FoundComp and (bIgnoreViewport or utils.CheckPointInScreen(self.OwnerActor:GetWorld(), FoundLocation))then
            G.log:debug("AssistAttack", "FindLockableComponent found lockable nearest comp: %s, dis: %f", G.GetObjectName(FoundComp), FoundDis)
            return FoundLocation, FoundComp
        end
    end

    -- 4. Check all components.
    local Comps = Target:K2_GetComponentsByClass(UE.UPrimitiveComponent)
    FoundDis, FoundLocation, FoundComp = utils.GetNearestComponent(SelfLocation, Comps)
    G.log:debug("AssistAttack", "FindLockableComponent found any nearest comp: %s, dis: %f", G.GetObjectName(FoundComp), FoundDis)

    return FoundLocation, FoundComp
end
--

function GAPlayerBase:EndAssistAttack()
    self.PresetAttackTarget = nil

    -- Normal attack not reset target when end assist attack.
    if not SkillUtils.IsCommonNormal(self.SkillType) then
        self:ResetAssistAttackTarget()
    end
end

function GAPlayerBase:ResetAssistAttackTarget(Target)
    if self.LastTarget and self.LastTarget:IsValid() and self.LastTarget ~= Target then
        self.LastTarget:SendMessage("BeSelected", false)
    end

    if Target and Target:IsValid() and Target ~= self.LastTarget then
        Target:SendMessage("BeSelected", true)
    end

    self.LastTarget = Target
end

-- Use in climb attack, target will already determinate should skip find target in assist attack.
function GAPlayerBase:PresetTarget(Target)
    self.PresetAttackTarget = Target
end

function GAPlayerBase:PreStartSkill()
    -- First end zero gravity of prev skill.
    self.OwnerActor.ZeroGravityComponent:EndCurrentZeroGravity()

    -- Set target for ability.
    local TargetTransform
    if self.LastTarget then
        TargetTransform = self.LastTarget:GetTransform()
    end
    if TargetTransform or self.LastTarget or self.LastTargetComponent then
        self.Owner:SendMessage("SetSkillTarget", self.SkillID, self.LastTarget, TargetTransform, TargetTransform ~= nil, self.LastTargetComponent, self:StaticClass(), true)
    else
        G.log:debug(self.__TAG__, "Try activate skill: %d without target", self.SkillID)
    end
end

function GAPlayerBase:AfterStartSkill()
    self:TryEnterSkillZeroGravity()
end

function GAPlayerBase:TryEnterSkillZeroGravity()
    -- Rush skill will always in zero gravity until rush end.
    -- 零重力设置因为rush_component里会设置一次，这里设置无穷大，如果没有进入rush就会无限卡在零重力直到释放新的技能，所以先注释了
    -- if SkillUtils.IsRushSkill(self.SkillType) then
    --     self.OwnerActor.ZeroGravityComponent:EnterZeroGravity(-1.0)
    --     return
    -- end

    if self.OwnerZeroGravityEnabled
            and self.OwnerZeroGravityTime > 0
            and (not self.OwnerActor:IsOnFloor())
            and self.bOwnerAutoZeroGravity then
        -- If config zero gravity in skill and InAir. InAirChargeSkill SPJ.
        self.OwnerActor.ZeroGravityComponent:EnterZeroGravity(self.OwnerZeroGravityTime)
    end
end

function GAPlayerBase:OnEndRush(bCanceled)
    self.bInRush = false

    return self.StartCallback(self.CallBackOwner, bCanceled)
end

function GAPlayerBase:GetInputControlForward(InputVector)
    if not InputVector then
        InputVector = self.Owner:GetInputVector()
    end

    if UE.UKismetMathLibrary.Vector_IsNearlyZero(InputVector) then
        return nil
    end

    local SelfActor = self.OwnerActor
    local ControlRotation = SelfActor:GetControlRotation()
    local InputRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(InputVector)
    local OutRotation = UE.UKismetMathLibrary.ComposeRotators(ControlRotation, InputRotation)
    return UE.UKismetMathLibrary.Conv_RotatorToVector(OutRotation)
end

function GAPlayerBase:GetInputControlForwardByDir(PressedDir)
    local SelfActor = self.OwnerActor
    local TargetForwardVector

    if not PressedDir then
        if self.Owner:IsDirPressed() then
            PressedDir = self.Owner.LastPressedDir
        end
    end

    if PressedDir then
        -- Get movement input desired target forward vector.
        local ControlRotation = SelfActor:GetControlRotation()
        if PressedDir == MoveDirConst.Right then
            TargetForwardVector = UE.UKismetMathLibrary.GetRightVector(ControlRotation)
        elseif PressedDir == MoveDirConst.Left then
            TargetForwardVector = UE.UKismetMathLibrary.NegateVector(UE.UKismetMathLibrary.GetRightVector(ControlRotation))
        elseif PressedDir == MoveDirConst.Forward then
            TargetForwardVector = UE.UKismetMathLibrary.GetForwardVector(ControlRotation)
        else
            TargetForwardVector = UE.UKismetMathLibrary.NegateVector(UE.UKismetMathLibrary.GetForwardVector(ControlRotation))
        end
    end

    return TargetForwardVector
end

function GAPlayerBase:FindNearestTarget(LastTarget, bKeepTarget, PressedDir, bOnlyPressedDir)

    local Targets
    if(self.bClimbAttack) then
        Targets = self:FindTargets_Climb(LastTarget, bKeepTarget, PressedDir, bOnlyPressedDir)
    else
        Targets = self:FindTargets(LastTarget, bKeepTarget, PressedDir, bOnlyPressedDir)
    end
    local SelfLocation = self.OwnerActor:K2_GetActorLocation()
    local NearestTarget
    local MinDis
    for ind = 1, Targets:Length() do
        local Target = Targets:Get(ind)
        local Dis = utils.GetTargetNearestDistance(SelfLocation, Target, nil)
        if (not NearestTarget) or Dis < MinDis then
            NearestTarget = Target
            MinDis = Dis
        end
    end
    return NearestTarget, MinDis
end

---@param LastTarget AActor last attack target.
---@param bKeepTarget boolean whether priority keep target not changed.
--- param PressedDir MoveDirConst pressed direction, default will use input LastPressedDir.
---@param bOnlyPressedDir boolean whether only find targets in pressed dir.
function GAPlayerBase:FindTargets(LastTarget, bKeepTarget, PressedDir, bOnlyPressedDir)
    local AssistInfo = self.AssistInfo
    local Filter = TargetFilter.new(self.OwnerActor, AssistInfo.TargetType)
    local SelfActor = self.OwnerActor
    local SelfActorLocation = SelfActor:K2_GetActorLocation()
    local ForwardVector = SelfActor:K2_GetRootComponent():GetForwardVector()
    local Targets = UE.TArray(UE.AActor)
    local TargetForwardVector = self:GetInputControlForwardByDir(PressedDir)

    if TargetForwardVector then
        -- Check actor forward vector already equal to target vector.
        if not UE.UKismetMathLibrary.EqualEqual_VectorVector(ForwardVector, TargetForwardVector, 1e-4) then
            -- Priority to keep same target, Check whether last attack target already in desired target.
            if bKeepTarget and LastTarget and Filter:FilterActor(LastTarget) then
                local InRange = UE.UHiCollisionLibrary.CheckInSection(LastTarget:K2_GetActorLocation(), SelfActorLocation, TargetForwardVector, UE.UKismetMathLibrary.DegreesToRadians(AssistInfo.Angle))
                if InRange then
                    Targets:Add(LastTarget)
                end
            end

            if Targets:Length() == 0 then
                local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
                ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
                local SectionRadian = UE.UKismetMathLibrary.DegreesToRadians(AssistInfo.Angle)
                local ActorsToIgnore = UE.TArray(UE.AActor)
                UE.UHiCollisionLibrary.SectionOverlapActors(self.OwnerActor, ObjectTypes, SelfActorLocation, TargetForwardVector, AssistInfo.Radius, SectionRadian,
                        AssistInfo.UpHeight, AssistInfo.DownHeight, nil, ActorsToIgnore, Targets, self.bDebug, self.LifeTime)
                Targets = SkillUtils.FilterTargets(Targets, Filter,true)
            end
        end
    end
    if bOnlyPressedDir or Targets:Length() > 0 then
        return Targets
    end

    -- Priority to keep same target, Check whether last attack target already in desired target.
    if bKeepTarget and LastTarget and Filter:FilterActor(LastTarget) then
        Targets:Add(LastTarget)
        return Targets
    end
    
    Targets = HiCollisionLibrary.PerformOverlapActors(self.OwnerActor, SelfActorLocation, TargetForwardVector, AssistInfo.RangeType, AssistInfo.Radius,
            AssistInfo.Angle, AssistInfo.Length, AssistInfo.HalfWidth, AssistInfo.UpHeight, AssistInfo.DownHeight, nil, self.bDebug, self.LifeTime)
    Targets = SkillUtils.FilterTargets(Targets, Filter, true)
    return Targets
end

function GAPlayerBase:FindTargets_Climb(LastTarget, bKeepTarget, PressedDir, bOnlyPressedDir)
    local Targets = self:FindTargets(LastTarget, bKeepTarget, PressedDir, bOnlyPressedDir)

    -- Climb attack need to check plane dis for plane attack(forward/left/right)
    local SelfLocation = self.OwnerActor:K2_GetActorLocation()
    local Filtered = UE.TArray(UE.AActor)
    local MaxPlaneDis = self.AssistInfo.ClimbMaxPlaneDis
    if self:IsPlaneAttack() then
        for Ind = 1, Targets:Length() do
            local CurTarget = Targets:Get(Ind)
            local TargetLocation = CurTarget:K2_GetActorLocation()
            local PlaneDis = UE.UKismetMathLibrary.Abs(TargetLocation.X - SelfLocation.X)
            if PlaneDis <= MaxPlaneDis then
                Filtered:Add(CurTarget)
            else
                G.log:debug("santi", "SkillClimb SkillID: %d, SkillType: %d, filter out target plane dis: %f(>%f)", self.SkillID, self.SkillType, PlaneDis, MaxPlaneDis)
            end
        end
        return Filtered
    else
        return Targets
    end
end

-- 处理角色切换，但是技能仍然处于激活状态的情况
function GAPlayerBase:HandleSwitchOut()
    -- do nothing now
end

UE.DistributedDSLua.RegisterCustomClass("GAPlayerBase", GAPlayerBase, GASkillBase)

return GAPlayerBase
