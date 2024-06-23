--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/03/29
--

---@type BP_CP001

require "UnLua"
local G = require("G")
--local ActorBase = require("actors.common.interactable.base.base_character")
--local NPCMoveViaPoint = require("actors.common.interactable.base.npc_move_via_point")
local ActorBase = require("actors.common.interactable.base.base_ghost")
local M = Class(ActorBase)


function M:Initialize(...)
    Super(M).Initialize(self, ...)
    --G.log:debug("zsf", "InitializeBegin cp001")
    self.bTriggered = false
    self.TargetTVKey = "TargetTV"
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    self.Sphere.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap_Sphere)
    self:LogInfo("zsf", "[cp001_lua] ReceiveBeginPlay %s %s", self:GetEditorID(), self.NewVar)
end

function M:OnBeginOverlap_Sphere(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self.bTriggered then
        self.NPCMoveViaPoint:TriggerAtWayPointIndex(OtherActor, -1)
    end
end

function M:CanFinish(index, OtherActor)
    local TargetTVID = self:GetActorIdSingle(self.TargetTVKey)
    if not TargetTVID then -- 没有小电视就不要进入了
        return false
    end
    if self.NPCMoveViaPoint then
        if self.NPCMoveViaPoint.GotoIndex ~= index then -- 幽灵没有到终点不触发
            return false
        end
        local moveType = self.NPCMoveViaPoint:GetMoveType()
        if moveType == Enum.E_NPCMoveType.TriggerByMission then-- 任务触发移动最后不判断 Finish
            return false
        end
    end
    if not self:IsServer() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return false
    end
    local Owner = OtherActor:GetOwner()
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    return Owner == PlayerControl
end

function M:StartMove()
    Super(M).StartMove(self)
    --self:Multicast_StartMove()
    self.eCp001State = Enum.E_CP001State.Move
end

function M:OnRep_eCp001State()
    self:PlayAnim(self.eCp001State)
end

function M:StopMove(bLast)
    self:DoStopMove(bLast)
end

function M:DoStopMove(bLast)
    local state = Enum.E_CP001State.Idel
    if bLast then
        local ChildActor = self:GetEditorActor(self.ChildActorID)
        if ChildActor then
            if ChildActor and ChildActor.bLock then
                state = Enum.E_CP001State.Anxious
                return
            end
        end
    end
    if self:IsServer() then
        self.eCp001State = state
    else
        self:PlayAnim(self.eCp001State)
    end
end

function M:ReachIndex(index, OtherActor, bLast)
    if bLast and self:CanFinish(index, OtherActor) then
        self:SetFinished()
        return
    end
    Super(M).ReachIndex(self, index, OtherActor, bLast)
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
end

function M:AllChildReadyServer()
    local ID = self:GetActorIdSingle(self.TargetTVKey)
    local Actor = self:GetEditorActor(ID)
    self.ChildActorID = ID
    if Actor then
        Actor:MakeMainActor(self)
        self[self.TargetTVKey] = UE.FSoftObjectPtr(Actor)
    end
    Super(M).AllChildReadyServer(self)
end

function M:AllChildReadyClient()
    local ID = self:GetActorIdSingle(self.TargetTVKey)
    local Actor = self:GetEditorActor(ID)
    self.ChildActorID = ID
    if Actor then
        Actor:MakeMainActor(self)
        self[self.TargetTVKey] = UE.FSoftObjectPtr(Actor)
    end
    Super(M).AllChildReadyClient(self)
end

function M:ChildTriggerMainActor(ChildActor)
    if ChildActor and not ChildActor.bLock then
        self.eCp001State = Enum.E_CP001State.Idel
    end
end

function M:PlayAnim(mode)
    local AnimMode = self.Mesh:GetAnimationMode()
    if AnimMode ~= Enum.EAnimationMode.AnimationBlueprint then
        self.Mesh:Stop()
        self.Mesh:SetAnimationMode(Enum.EAnimationMode.AnimationBlueprint)
    end
    local AnimInstance = self.Mesh:GetAnimInstance()
    self:LogInfo("zsf", "[cp001_lua] PlayAnim %s %s %s %s %s", self:GetEditorID(), mode, AnimInstance.SetIdle, self.fMoveSpeed, self:GetClassDefaultsSpeed())
    if mode == Enum.E_CP001State.Idel then
        AnimInstance:SetIdle()
    elseif mode == Enum.E_CP001State.Move then
        AnimInstance:SetMoveSpeed(self.fMoveSpeed/self:GetClassDefaultsSpeed())
        AnimInstance:SetMove()
    elseif mode == Enum.E_CP001State.GotoTV then
        AnimInstance:SetGoToTV()
    elseif mode == Enum.E_CP001State.Anxious then
        AnimInstance:SetAnxious()
    end
end

function M:SetFinished()
    local ChildActor = self:GetEditorActor(self.ChildActorID)
    if not ChildActor or (ChildActor and ChildActor.bLock) then
        return
    end
    self:LogInfo("zsf", "[cp001_lua] SetFinished")
    --self:Multicast_EndGotoTV()
end

function M:Multicast_EndGotoTV_RPC()
    self:LogInfo("zsf", "[cp001] Multicast_EndGotoTV_RPC")
    if self:IsClient() then
        self.eCp001State = Enum.E_CP001State.GotoTV
        utils.DoDelay(self:GetWorld(), 0.6,
                function()
                    self.Mesh:SetHiddenInGame(true)
                    local ChildActor = self:GetEditorActor(self.ChildActorID)
                    if ChildActor and ChildActor.PlayAppearAnim then
                        ChildActor:PlayAppearAnim()
                    end
                end)
    else
        utils.DoDelay(self:GetWorld(), 2.5,
function()
            self:LogicComplete()
        end)
    end
end

function M:SetMobility(bMoveViaSpline)
    local Mobility = Enum.EComponentMobility.Movable
    local bMoveable = true
    local Rotator = UE.UKismetMathLibrary.MakeRotator(0, 0, 0)
    if bMoveViaSpline then
        Rotator = UE.UKismetMathLibrary.MakeRotator(0, 0, 180)
        Mobility = Enum.EComponentMobility.Static
        bMoveable = false
    end
    --self.Mesh:K2_SetWorldRotation(Rotator, false, UE.FHitResult(), false)
    --self.CapsuleComponent:SetMobility(Mobility)
    --self.Mesh:SetMobility(Mobility)
    --self.Sphere:SetMobility(Mobility)
    self.CapsuleComponent:SetEnableGravity(bMoveable)
    self.Mesh:SetEnableGravity(bMoveable)
    self.Sphere:SetEnableGravity(bMoveable)
    --if self.CharacterMovement then
    --    self.CharacterMovement:SetActive(bMoveable, true)
    --end
    self:SetReplicateMovement(bMoveable)
    --self:SetReplicates(bMoveable)
end

function M:UpdateOwnerLocationAndRotation(Location, Rotator)
    --local Ro = UE.UKismetMathLibrary.Conv_RotatorToVector(Rotator)
    --Ro = Ro + UE.FVector(90, 0, 0)
    --Rotator = UE.UKismetMathLibrary.Conv_VectorToRotator(Ro)
    self:K2_SetActorLocationAndRotation(Location, Rotator, false, UE.FHitResult(), true)
end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
    self.Sphere.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_Sphere)
end

return M
