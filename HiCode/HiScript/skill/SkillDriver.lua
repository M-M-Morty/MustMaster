require "UnLua"

local G = require("G")
local SkillManagerCombo = require("skill.SkillManagerCombo")
local SkillManagerBase = require("skill.SkillManagerBase")
local SkillManagerAssist = require("skill.SkillManagerAssist")
local SkillObj = require ("skill.SkillObj")
local check_table = require("common.data.state_conflict_data")
local SkillData = require("common.data.skill_list_data").data
local SkillFieldConsts = require("common.event_const").SkillField
local MinComboSkillCount = require("common.event_const").MinComboSkillCount
local SkillUtils = require("common.skill_utils")
local MoveDirConst = require("common.event_const").MoveDir
local TargetFilter = require("actors.common.TargetFilter")
local HiCollisionLibrary = require("common.HiCollisionLibrary")


local SkillDriver = Class()

function SkillDriver:ctor(owner)
    self.__TAG__ = "SkillDriver"
    ---@type BP_SkillComponent_C
    self.Owner = owner
    self.actor = self.Owner.actor
    self.AbilitySystemComponent = G.GetHiAbilitySystemComponent(self.Owner.actor)

    -- Cache for (SkillType, SkillManager)
    self.ManagerDict = {}

    -- Cache for (SkillID, SkillManager), non-combo skills.
    self.DefaultManagerDict = {}

    self.SkillContainer = {}

    self.ClimbManagerDict = {}
    self.ClimbManagerDict[MoveDirConst.Forward] = { self.GetClimbForwardManager, self.GetClimbForwardChargeManager }
    self.ClimbManagerDict[MoveDirConst.Left] = { self.GetClimbLeftManager, self.GetClimbLeftChargeManager }
    self.ClimbManagerDict[MoveDirConst.Right] = { self.GetClimbRightManager, self.GetClimbRightChargeManager }
    self.ClimbManagerDict[MoveDirConst.Backward] = { self.GetClimbBackManager, self.GetClimbBackChargeManager }
end

-- When rep new activatable skill, check skill type and try init corresponding combo manager.
function SkillDriver:OnRepNewSkill(SkillID, SkillType)
    if SkillUtils.IsComboManagerSkill(SkillType) then
        G.log:debug("SkillDriver", "OnRepNewSkill, Init combo, skillID: %d, skillType: %d", SkillID, SkillType)
        self:InitNormalCombo(SkillID, SkillType)
    elseif SkillUtils.IsDefaultTypeSkill(SkillType)
            or SkillType == Enum.Enum_SkillType.MultiStage
            or SkillType == Enum.Enum_SkillType.CaptureAndThrow
            or SkillType == Enum.Enum_SkillType.SecondarySkill
            or SkillType == Enum.Enum_SkillType.Rush
            or SkillType == Enum.Enum_SkillType.FallAttack
            or SkillUtils.IsChargeManagerSkill(SkillType) then -- TODO In future switch all skill use SkillID to trigger, not SkillType.
        G.log:debug("SkillDriver", "OnRepNewSkill, Init default, skillID: %d, skillType: %d", SkillID, SkillType)
        self.DefaultManagerDict[SkillID] = SkillManagerBase.new(self.Owner, SkillID, SkillType)
    elseif SkillUtils.IsAssistManagerSkill(SkillType) then
        self:InitAssistSkill(SkillID)
    else
        G.log:debug("SkillDriver", "OnRepNewSkill, Init with skill type, skillID: %d, skillType: %d", SkillID, SkillType)
        self.ManagerDict[SkillType] = SkillManagerBase.new(self.Owner, SkillID, SkillType)
    end
    
    ---初始化助战技能列表
    self.Owner:SendMessage("OnRepNewSkill", SkillID, SkillType)
end

-- Init normal skill combos include Normal and InAirNormal
function SkillDriver:InitNormalCombo(SkillID, SkillType)
    local SkillInfo = SkillData[SkillID]
    if SkillInfo then
        local ComboSkillIDs = SkillInfo[SkillFieldConsts.ComboSkillID]
        if ComboSkillIDs and #ComboSkillIDs >= MinComboSkillCount then
            -- Init combo manager
            self.ManagerDict[SkillType] = SkillManagerCombo.new(self.Owner, SkillID, SkillType)
            if SkillUtils.IsNormalSkill(SkillType) then
                self:GetNormalManager():Clear()
                self:GetNormalManager():InitFromData(ComboSkillIDs)
            else
                self:GetInAirNormalManager():Clear()
                self:GetInAirNormalManager():InitFromData(ComboSkillIDs)
            end
        end
    end
end

---初始化助战技能
---@param SkillID number[]
---@param CurSkillIndex number
function SkillDriver:InitAssistSkill(SkillID)
    ---@type SkillManagerAssist
    local SkillType = Enum.Enum_SkillType.AssistSkill
    self.ManagerDict[SkillType] = SkillManagerBase.new(self.Owner, SkillID, SkillType)
end

function SkillDriver:InitSkillObj(SkillID)
    if self.SkillContainer[SkillID] then
        return self.SkillContainer[SkillID]
    end

    local Skill = SkillObj.new(self.Owner, SkillID)
    self.SkillContainer[SkillID] = Skill
    return Skill
end

function SkillDriver:OnRepRemoveSkill(SkillID, SkillType)
    local SkillMgr = nil
    if SkillUtils.IsComboManagerSkill(SkillType) then
        --
    elseif SkillUtils.IsChargeManagerSkill(SkillType) then
        SkillMgr = self.ManagerDict[SkillType]
        self.ManagerDict[SkillType] = nil
    elseif SkillUtils.IsDefaultTypeSkill(SkillType)
            or SkillType == Enum.Enum_SkillType.MultiStage
            or SkillType == Enum.Enum_SkillType.CaptureAndThrow
            or SkillType == Enum.Enum_SkillType.SecondarySkill
            or SkillType == Enum.Enum_SkillType.Rush then
        SkillMgr = self.DefaultManagerDict[SkillID]  
        self.DefaultManagerDict[SkillID] = nil
    elseif SkillUtils.IsAssistManagerSkill(SkillType) then
        SkillMgr = self.ManagerDict[SkillType]
        self.ManagerDict[SkillType] = nil        
    else
        SkillMgr = self.ManagerDict[SkillType]
        self.ManagerDict[SkillType] = nil
    end
    if self.CurManager and self.CurManager == SkillMgr then
        self.CurManager:StopAndReset()
    end
end

function SkillDriver:GetCurrentSkillObj(SkillType)
    return self.CurManager:GetCurrentSkill()
end

function SkillDriver:SwitchNormalCombo(bInAir, bResetManager)
    if bInAir then
        if self.CurManager then
            if self.CurManager:GetSkillType() == Enum.Enum_SkillType.InAirNormal then
                return
            end

            if self.CurManager == self:GetNormalManager() and not self.CurManager:CanSwitch() then
                return
            end
        end

        self:StartManager(self:GetInAirNormalManager(), true, false)
    else
        if self.CurManager then
            if self.CurManager:GetSkillType() == Enum.Enum_SkillType.Normal then
                return
            end

            if self.CurManager == self:GetInAirNormalManager() and not self.CurManager:CanSwitch() then
                return
            end
        end
        
        --bSkipRest目的是Normal及蓄力攻击只有keyup时才能确定，我们在那时候再做打断
        self:StartManager(self:GetNormalManager(), true, not bResetManager)
        
    end

    if self.CurManager then
        self.CurManager:Reset()
    end
end

function SkillDriver:ComboKeyDown()
    --当前manager为空允许切换
    local bInAir = not self.actor:IsOnFloor()
    self:SwitchNormalCombo(bInAir, false)

    local CurNode = self.CurManager:GetCurrentSkill()
    if not CurNode then
        G.log:error(self.__TAG__, "ComboKeyDown but no current node found in SkillManager.")
        return
    end

    self.CurManager:KeyDown()
end

function SkillDriver:MarkSwitchOut()
    if SkillUtils.HasActivateAbilities(self.actor) then
        if self.CurManager then
            self.CurManager:MarkSwitchOut()
        end        
    end
end

function SkillDriver:HandleClimbAttack()
    -- Attention: End climb state in here not in check_action, as skill need to know whether in climb state then use climb state attack skill.
    self.Owner:SendMessage("EndState", check_table.State_Climb, true)

    local VerticalTransform = self:GetOwnerVerticalTransform()
    local InputVector = self.Owner:GetInputVector()
    local InputRotation
    if not UE.UKismetMathLibrary.Vector_IsNearlyZero(InputVector) then
        InputRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(InputVector)
    end

    local AttackDir, Target = self:GetClimbAttackDirAndTarget(InputRotation, VerticalTransform)
    G.log:debug("SkillDriver", "HandleClimbAttack start with AttackDir: %d, Target: %s", AttackDir, G.GetDisplayName(Target))
    local NormalManager, ChargeManager = self.ClimbManagerDict[AttackDir][1](self), self.ClimbManagerDict[AttackDir][2](self)

    -- Rotate to corresponding attack dir.
    local SelfLocation = self.actor:K2_GetActorLocation()
    local ToRotation = self.actor:K2_GetActorRotation()

    if not Target and not UE.UKismetMathLibrary.Vector_IsNearlyZero(InputVector) then
        -- If has input vector, rotate to input direction.
        --UE.UKismetSystemLibrary.DrawDebugLine(self.actor, self.actor:K2_GetActorLocation(), self.actor:K2_GetActorLocation() + InputVector * 200.0, UE.FLinearColor(1, 0, 0, 1), 30, 2)
        ToRotation = UE.UKismetMathLibrary.TransformRotation(VerticalTransform, UE.FRotator(0, InputRotation.Yaw, 0))
    else
        -- Rotate to skill right direction.
        ToRotation.Roll = 0 -- Always rotate to absolute left/right/forward/backward.
        local NewTransform = UE.UKismetMathLibrary.MakeTransform(SelfLocation, ToRotation)
        if AttackDir == MoveDirConst.Forward then
            ToRotation = UE.UKismetMathLibrary.TransformRotation(NewTransform, UE.FRotator(90, 0, 0))
        elseif AttackDir == MoveDirConst.Left then
            ToRotation = UE.UKismetMathLibrary.TransformRotation(NewTransform, UE.FRotator(0, -90, -90))
        elseif AttackDir == MoveDirConst.Right then
            ToRotation = UE.UKismetMathLibrary.TransformRotation(NewTransform, UE.FRotator(0, 90, 90))
        elseif AttackDir == MoveDirConst.Backward then
            ToRotation = UE.UKismetMathLibrary.TransformRotation(NewTransform, UE.FRotator(-90, 180, 0))
        end
    end

    local CustomSmoothContext = UE.FCustomSmoothContext()
    self.actor.AppearanceComponent:SetCharacterRotation(ToRotation, false, CustomSmoothContext)
    self.actor.AppearanceComponent:Server_SetCharacterRotation(ToRotation, false, CustomSmoothContext)
    --UE.UKismetSystemLibrary.DrawDebugLine(self.actor, self.actor:K2_GetActorLocation(), self.actor:K2_GetActorLocation() + self.actor:GetActorForwardVector() * 200.0, UE.FLinearColor(0, 1, 0, 1), 30, 2)

    self.CurManager = NormalManager
    self.ChargeManager = ChargeManager
    local ChargeAbilityCDO = self.ChargeManager:GetCurrentAbilityCDO()
    -- Preset assist attack target, to let assist attack use target from here.
    if Target and ChargeAbilityCDO then
        ChargeAbilityCDO:PresetTarget(Target)
    end
    if self.ChargeManager then
        -- Set MovementAction to custom to avoid rotation update by ALS UpdateCharacterRotation.
        -- Set enter zero gravity, before charge skill really start.
        self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.Custom)
        self.actor.AppearanceComponent:Server_SetMovementAction(UE.EHiMovementAction.Custom)
        if ChargeAbilityCDO then
            self.actor.ZeroGravityComponent:EnterZeroGravity(ChargeAbilityCDO.InChargeTime, false)
        end
        self.ChargeManager:InitInChargeTimer(false)
    end
end

function SkillDriver:GetOwnerVerticalTransform()
    local SelfRotation = self.actor:K2_GetActorRotation()
    local SelfLocation = self.actor:K2_GetActorLocation()

    -- Set Roll=0 and Pitch = 90
    SelfRotation.Roll = 0
    local NewTransform = UE.UKismetMathLibrary.MakeTransform(SelfLocation, SelfRotation)
    local NewRotation = UE.UKismetMathLibrary.TransformRotation(NewTransform, UE.FRotator(90, 0, 0))
    NewTransform = UE.UKismetMathLibrary.MakeTransform(SelfLocation, NewRotation)
    return NewTransform
end

---@param InputRotation FRotator input rotation relative to ReferTransform.
---@param ReferTransform FTransform Transform from rotate self actor with pitch=90.
function SkillDriver:GetClimbAttackDirAndTarget(InputRotation, ReferTransform)
    -- Find all targets in attack radius.
    local SelfLocation = self.actor:K2_GetActorLocation()
    local AttackRadius = self.Owner.ClimbAttackRadius
    local ActorsToIgnore = UE.TArray(UE.AActor)
    local Targets = UE.TArray(UE.AActor)
    local bDebug = false
    local DebugLifeTime = 0.0

    UE.UHiCollisionLibrary.SphereOverlapActors(self.actor, HiCollisionLibrary.CollisionObjectTypes, SelfLocation,
            AttackRadius, AttackRadius, AttackRadius, nil, ActorsToIgnore, Targets, bDebug, DebugLifeTime)

    -- Filter target type
    local Filter = TargetFilter.new(self.actor, self.Owner.ClimbAttackTargetType)
    Targets = SkillUtils.FilterTargets(Targets, Filter)

    -- Find nearest target in InputDir within specific angle range, priority check same plane target.
    local ResTarget
    local MinAngle
    local MinDis
    local ValidHalfAngle = self.Owner.ClimbAttackInputValidHalfAngle
    local AngleTolerance = self.Owner.ClimbAttackAngleTolerance
    if InputRotation then
        G.log:debug("SkillDriver", "Climb attack finding nearest target in input direction.")
        for Ind = 1, Targets:Length() do
            local CurTarget = Targets:Get(Ind)
            local CurTargetLocation = CurTarget:K2_GetActorLocation()
            -- Transform target location to local space of ReferTransform
            local TargetLocationInLocal =  UE.UKismetMathLibrary.InverseTransformLocation(ReferTransform, CurTargetLocation)

            -- Check target must not in wall backward and consider as in same plane with self actor.
            if TargetLocationInLocal.Z >= 0 and TargetLocationInLocal.Z < self.Owner.ClimbAttackMaxPlaneDis then
                -- Calculate angle between InputDir and TargetLocation - SelfLocation.
                local TargetDir = TargetLocationInLocal
                local InputDir = UE.UKismetMathLibrary.Conv_RotatorToVector(InputRotation)
                local Angle = UE.UKismetMathLibrary.DegAcos(UE.UKismetMathLibrary.Vector_CosineAngle2D(TargetDir, InputDir))

                if Angle <= ValidHalfAngle then
                    local TargetDis = UE.UKismetMathLibrary.Vector_Distance2DSquared(TargetLocationInLocal, UE.FVector(0, 0, 0))
                    local bFind = MinAngle == nil
                    bFind = bFind or (Angle < MinAngle and MinAngle - Angle > AngleTolerance)
                    bFind = bFind or (UE.UKismetMathLibrary.Abs(Angle - MinAngle) <= AngleTolerance and TargetDis < MinDis)

                    if bFind then
                        ResTarget = CurTarget
                        MinAngle = Angle
                        MinDis = TargetDis
                    end
                end
            end
        end
    end

    if not ResTarget then
        G.log:debug("SkillDriver", "Climb attack finding nearest target without direction.")
        MinDis = nil
        -- Find nearest target
        for Ind = 1, Targets:Length() do
            local CurTarget = Targets:Get(Ind)
            local CurTargetLocation = CurTarget:K2_GetActorLocation()
            local TargetLocationInLocal =  UE.UKismetMathLibrary.InverseTransformLocation(ReferTransform, CurTargetLocation)
            local TargetDis = UE.UKismetMathLibrary.Vector_Distance2DSquared(TargetLocationInLocal, UE.FVector(0, 0, 0))
            if MinDis == nil or TargetDis < MinDis then
                MinDis = TargetDis
                ResTarget = CurTarget
            end
        end
    end

    if ResTarget then
        local CurTargetLocation = ResTarget:K2_GetActorLocation()
        local TargetLocationInLocal =  UE.UKismetMathLibrary.InverseTransformLocation(ReferTransform, CurTargetLocation)
        local Dir = GetRotatorDirection(UE.UKismetMathLibrary.Conv_VectorToRotator(TargetLocationInLocal))
        return Dir, ResTarget
    end

    -- No target but has input, return input direction.
    if InputRotation then
        return GetRotatorDirection(InputRotation), nil
    end

    -- No target no input, return default backward.
    return MoveDirConst.Backward, nil
end

---@param Rotation FRotator Get Rotation direction in 2D plane.
function GetRotatorDirection(Rotation)
    local Yaw = Rotation.Yaw
    if Yaw < 0 then
        Yaw = Yaw + 360
    end

    if Yaw <= 45 or Yaw > 315 then
        return MoveDirConst.Forward
    elseif Yaw > 45 and Yaw <= 135 then
        return MoveDirConst.Right
    elseif Yaw > 135 and Yaw <= 225 then
        return MoveDirConst.Backward
    else
        return MoveDirConst.Left
    end
end

function SkillDriver:FindClimbAttackNearestTarget(Dir)
    local NormalManager, _ = self.ClimbManagerDict[Dir][1](self), self.ClimbManagerDict[Dir][2](self)
    local CurSkill = NormalManager:GetCurrentSkill()
    if CurSkill then
        local SkillCDO = CurSkill:GetCurrentAbilityCDO()
        if SkillCDO then
            return SkillCDO:FindNearestTarget(nil, false, Dir, true)
        end
    end

    return nil, 0
end

-- After state check.
function SkillDriver:ComboKeyUp()
    local bInAir = not self.actor:IsOnFloor()
    if not self.CurManager or self.CurManager == self:GetNormalManager() or self.CurManager == self:GetInAirNormalManager() then
        self:SwitchNormalCombo(bInAir, true)
    end

    -- Reset movement action set in other place. HandleClimbAttack .etc.
    self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.None)
    self.actor.AppearanceComponent:Server_SetMovementAction(UE.EHiMovementAction.None)

    if self.CurManager then
        self.CurManager:KeyUp()
    end
end

-- No state check.
function SkillDriver:ComboKeyUpWithoutState()
    if self.CurManager then
        self.CurManager:KeyUp()
    end
end

function SkillDriver:GoToFirstCombo(AnimOffsetTime)
    self.CurManager:StopAndReset()

    self:SwitchNormalCombo(not self.actor:IsOnFloor(), true)

    -- Set montage offset when jump from charge to first combo.
    local CurSkill = self.CurManager:GetCurrentSkill()
    if CurSkill then
        G.log:debug("SkillDriver", "GoToFirstCombo with anim offset time: %f", AnimOffsetTime)
        CurSkill:SetMontageOffsetTime(AnimOffsetTime)
    end

    self.CurManager:Start()
end

function SkillDriver:ComboCheckStart_Notify()
    if self.CurManager then
        self.CurManager:ComboCheckStart_Notify()
    end
end

function SkillDriver:ComboCheckEnd_Notify()
    if self.CurManager and self.CurManager.ComboCheckEnd_Notify then
        self.CurManager:ComboCheckEnd_Notify()
    end
end

function SkillDriver:ComboPeriodStart_Notify()
    if self.CurManager then
        self.CurManager:ComboPeriodStart_Notify()
    end
end

function SkillDriver:ComboPeriodEnd_Notify()
    if self.CurManager and self.CurManager.ComboPeriodEnd_Notify then
        self.CurManager:ComboPeriodEnd_Notify()
    end
end

function SkillDriver:OnComboTail()
    if self.CurManager then
        self.CurManager:OnComboTail()
    end
end

function SkillDriver:StopCurrentSkill()
    if not self.CurManager then
        return
    end

    self.CurManager:StopAndReset()
end

function SkillDriver:StopSkillTail()
    if self.CurManager and self.CurManager:IsInSkillTail() then
        G.log:debug("SkillDriver", "StopSkillTail")
        self:StopCurrentSkill()
    end
end

function SkillDriver:OnEndAbility(SkillID, SkillType)
    G.log:info("SkillDriver", "skill %s on end ability", SkillID)
    if not self.CurManager then
        return
    end

    if SkillID == 0 then
        --以防不属于技能系统的GA影响到技能系统正在释放的GA无法正常结束
        return
    end

    local CurSkill = self.CurManager:GetCurrentSkill()
    if not CurSkill then
        G.log:error("SkillDriver", "SkillDriver OnEndAbility SkillID: %d, current skill is nil", SkillID)
        return
    end

    if CurSkill.SkillID ~= SkillID then
        G.log:error("SkillDriver", "SkillDriver OnEndAbility SkillID: %d not match current SkillID: %d", SkillID, CurSkill.SkillID)
        return
    end
    self.CurManager:OnEndCurrentSkill()
end

-- 开始硬直状态
function SkillDriver:OnBeginInKnock()
    if not self.CurManager then
        return
    end
    self.CurManager:StopAndReset()
    self.Owner:SendMessage("ExecuteAction", check_table.Action_InKnock)
end

-- 结束硬直状态
function SkillDriver:OnEndInKnock()
    self.Owner:SendMessage("EndState", check_table.State_InKnock)
end

function SkillDriver:Block()
    self:StartManager(self:GetBlockManager())
end

function SkillDriver:StrikeBack()
    self:StartManager(self:GetStrikeBackManager())
end

function SkillDriver:SecondarySkill()
    self:StartManager(self:GetSecondarySkillManager())
end

function SkillDriver:SuperSkill()
    self:StartManager(self:GetSuperManager())
end

function SkillDriver:Rush()
    self:StartManager(self:GetRushManager())
end

function SkillDriver:AssistSkill()
    self:StartManager(self:GetAssistSkillManager())
end

function SkillDriver:StartSkill(SkillID)
    if not self.DefaultManagerDict[SkillID] then
        G.log:error(self.__TAG__, "StartSkill of skillID: %s called, but no skill found!", SkillID)
        return
    end

    G.log:debug(self.__TAG__, "Start default type skill by id: %s", SkillID)
    self:StartManager(self.DefaultManagerDict[SkillID])
end

function SkillDriver:StartManager(Manager, bSkipStart, bSkipReset)
    if Manager then
        if self.CurManager and self.CurManager ~= Manager and not bSkipReset then
            self.CurManager:StopAndReset()
        end

        if not self.CurManager or self.CurManager ~= Manager then
            self.CurManager = Manager
        end

        if not bSkipStart then
            Manager:Start()
        end
    end
end

function SkillDriver:TrySwitchManager(SkillObj, bSkipStart)
    local SkillType = SkillObj:GetSkillType()
    local Manager = self.ManagerDict[SkillType]

    self:StartManager(Manager, bSkipStart)
end

-- TODO dynamic generate ?
function SkillDriver:GetNormalManager()
    return self.ManagerDict[Enum.Enum_SkillType.Normal]
end

function SkillDriver:GetInAirNormalManager()
    return self.ManagerDict[Enum.Enum_SkillType.InAirNormal]
end

function SkillDriver:GetRushManager()
    return self.ManagerDict[Enum.Enum_SkillType.Rush]
end

function SkillDriver:GetFallAttackManager()
    return self.ManagerDict[Enum.Enum_SkillType.FallAttack]
end

function SkillDriver:GetBlockManager()
    return self.ManagerDict[Enum.Enum_SkillType.Block]
end

function SkillDriver:GetStrikeBackManager()
    return self.ManagerDict[Enum.Enum_SkillType.StrikeBack]
end

function SkillDriver:GetSuperManager()
    return self.ManagerDict[Enum.Enum_SkillType.Super]
end

function SkillDriver:GetClimbForwardManager()
    return self.ManagerDict[Enum.Enum_SkillType.ClimbForward]
end

function SkillDriver:GetClimbForwardChargeManager()
    return self.ManagerDict[Enum.Enum_SkillType.ClimbForwardCharge]
end

function SkillDriver:GetClimbLeftManager()
    return self.ManagerDict[Enum.Enum_SkillType.ClimbLeft]
end

function SkillDriver:GetClimbLeftChargeManager()
    return self.ManagerDict[Enum.Enum_SkillType.ClimbLeftCharge]
end

function SkillDriver:GetClimbRightManager()
    return self.ManagerDict[Enum.Enum_SkillType.ClimbRight]
end

function SkillDriver:GetClimbRightChargeManager()
    return self.ManagerDict[Enum.Enum_SkillType.ClimbRightCharge]
end

function SkillDriver:GetClimbBackManager()
    return self.ManagerDict[Enum.Enum_SkillType.ClimbBack]
end

function SkillDriver:GetClimbBackChargeManager()
    return self.ManagerDict[Enum.Enum_SkillType.ClimbBackCharge]
end

function SkillDriver:GetSecondarySkillManager()
    return self.ManagerDict[Enum.Enum_SkillType.SecondarySkill]
end

function SkillDriver:GetAssistSkillManager()
    return self.ManagerDict[Enum.Enum_SkillType.AssistSkill]
end

local function dump_map(map)
    local ret = {}
    local keys = map:Keys()
    for i = 1, keys:Length() do

        local key = keys:Get(i)
        local value = map:Find(key)
        table.insert(ret, key .. ":" .. tostring(value))
    end
    return "{" .. table.concat(ret, ",") .. "}"
end

function SkillDriver:Reset()
    if self.CurManager then
        self.CurManager:StopAndReset()
    end
end

function SkillDriver:Clear()
    self.SkillContainer = {}
    self.CurManager:Clear()
end


return SkillDriver
