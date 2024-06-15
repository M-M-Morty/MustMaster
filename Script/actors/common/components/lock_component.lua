--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR panzibin
-- @DATE ${2023/11/23} ${time}
--

local utils = require("common.utils")
local ComponentUtils = require("common.component_utils")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")

---@type BP_LockComponent_C
local LockComponent = Component(ComponentBase)
local decorator = LockComponent.decorator

function LockComponent:ReceiveBeginPlay()
    Super(LockComponent).ReceiveBeginPlay(self)
    self:InitOnBeginPlay()
end

function LockComponent:ReceiveTick(DeltaSeconds)
    self:RefreshLockComponent()
end

--初始化数据
function LockComponent:InitOnBeginPlay()
    self.CurLockComponentInd = nil
    self.CurLockComponent = nil -- CurLockComponent may not nil, even if CurLockComponentInd is nil.
    self.CurLockComponentList = {}
    -- print("打印测试    LockComponent:ReceiveBeginPlay 锁定组件",self.actor:GetDisplayName(),self.CurLockComponentList)
    --蓝图变量
    -- self.LockMaxDis
    -- self.LockResetTime
    -- self.UnlockHoldTime
end

function LockComponent:GetTargetLockComponent()
    return self.CurLockComponent
end

decorator.message_receiver()
function LockComponent:LockAttack(Pressed)
    self:TriggerLock(Pressed)
end

--触发锁定,按键按下或释放都会触发
function LockComponent:TriggerLock(Pressed)
    if self.UnlockTimer then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.UnlockTimer)
    end
    if Pressed then
        self:LockNext()
        self.UnlockTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.Unlock}, self.UnlockHoldTime, false)
    end
end

function LockComponent:LockNext()
    if not self.CurLockComponentInd or #self.CurLockComponentList == 0 then
        self:_FirstLock()
        if #self.CurLockComponentList > 0 then
            self.CurLockComponentInd = 1
            self:_SetComponentLock(self.CurLockComponentList[self.CurLockComponentInd])
        end
        return
    else
        local CurInd = (self.CurLockComponentInd % #self.CurLockComponentList) + 1
        local CurComp = self.CurLockComponentList[CurInd]
        if self:_IsComponentOwnerDead(CurComp) then
            table.remove(self.CurLockComponentList, CurInd)
            self:LockNext()
            return
        else
            self.CurLockComponentInd = CurInd
            self:_SetComponentLock(self.CurLockComponentList[self.CurLockComponentInd])
            if CurInd == #self.CurLockComponentList then
                self:LockReset()
            end
        end
    end
end

function LockComponent:_FirstLock()
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:AddUnique(self.actor)
    local OutComponents = UE.TArray(UE.UPrimitiveComponent)
    -- TODO use overlap now, maybe change to scan all actors and components.
    local SelfLocation = self.actor:K2_GetActorLocation()
    local MaxDis = self.LockMaxDis
    UE.UHiCollisionLibrary.SphereOverlapComponents(self.actor, ObjectTypes, SelfLocation, MaxDis, MaxDis, MaxDis, nil,ActorsToIgnore, OutComponents, false, 1)
    -- TODO check component visibility
    if OutComponents:Length() == 0 then return end
    for Ind = 1, OutComponents:Length() do
        local CurComp = OutComponents:Get(Ind)
        local CurOwner = CurComp:GetOwner()
        if CurOwner and not CurOwner:IsPlayerComp() and ComponentUtils.ComponentLockable(CurComp) then
            table.insert(self.CurLockComponentList, CurComp)
        end
    end
    table.sort(self.CurLockComponentList, function(a, b)
        return utils.GetDisSquare(a:K2_GetComponentLocation(), SelfLocation) < utils.GetDisSquare(b:K2_GetComponentLocation(), SelfLocation)
    end)
end

function LockComponent:_IsComponentOwnerDead(Comp)
    local Owner = Comp:GetOwner()
    if not Owner or (Owner.IsDead and Owner:IsDead()) then
        return true
    end
    return false
end

function LockComponent:_SetComponentLock(LockComponent)
    self:_SetCurComponentUnLock()
    self.CurLockComponent = LockComponent
    local OwnerActor = LockComponent:GetOwner()
    if OwnerActor and OwnerActor.SetLock then
        OwnerActor:SetLock(LockComponent, true, self.LockUI)
    end
    if self.LockResetTimer then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.LockResetTimer)
    end
    self.LockResetTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.LockReset}, self.LockResetTime, false)
    self.actor:SendMessage("SyncLockTargetToServer",LockComponent)
end

function LockComponent:_SetCurComponentUnLock()
    if self.CurLockComponent then
        local OwnerActor = self.CurLockComponent:GetOwner()
        if OwnerActor and OwnerActor.SetLock then
            OwnerActor:SetLock(nil, false)
        end
        self.CurLockComponent = nil
    end
    self.actor:SendMessage("SyncLockTargetToServer",nil)
end

-- Only reset lock list and index, keep CurLockComponent unchanged.
function LockComponent:LockReset()
    self.CurLockComponentInd = nil
    self.CurLockComponentList = {}
end

-- Unlock current component and release lock list.
function LockComponent:Unlock()
    self:_SetCurComponentUnLock()
    self.CurLockComponentInd = nil
    self.CurLockComponentList = {}
    if self.LockResetTimer then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.LockResetTimer)
    end
end

--若已有锁定,则使用技能时会技调用
-- return Target, TargetLocation
function LockComponent:BeginLockAttack(SkillObj)
    if not self.CurLockComponent or not UE.UKismetSystemLibrary.IsValid(self.CurLockComponent) then
        self:Unlock()
        return nil, nil
    end
    local AbilityCDO = SkillObj:GetAbilityCDO()

    local TargetLocation = self.CurLockComponent:K2_GetComponentLocation()
    local DirToTarget = TargetLocation - self.actor:K2_GetActorLocation()
    UE.UKismetMathLibrary.Vector_Normalize(DirToTarget)
    local ToRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(DirToTarget)
    if AbilityCDO.bClimbAttack then
        ToRotation.Roll = 0
    else
        -- Never change roll and pitch
        ToRotation.Roll = 0
        ToRotation.Pitch = 0
    end
    -- Not use smooth change and wait callback, a lot of bug.
    local CustomSmoothContext = UE.FCustomSmoothContext()
    self.actor:GetLocomotionComponent():SetCharacterRotation(ToRotation, false, CustomSmoothContext)
    self.actor:GetLocomotionComponent():Server_SetCharacterRotation(ToRotation, false, CustomSmoothContext)
    -- G.log:debug("LockComponent", "Lock attack SkillID: %d, SkillType: %s", SkillObj.SkillID, AbilityCDO.SkillType)
    return self.CurLockComponent:GetOwner(),TargetLocation
end

function LockComponent:RefreshLockComponent()
    if not self.CurLockComponent then return end
    local TargetDis = utils.GetTargetNearestDistance(self.actor:K2_GetActorLocation(), nil, self.CurLockComponent)
    if TargetDis > self.LockMaxDis then
        self:Unlock()
    end
end

return LockComponent