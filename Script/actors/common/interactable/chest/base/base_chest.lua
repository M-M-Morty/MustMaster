--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/05/15
--

---@type

require "UnLua"
local G = require("G")
local ActorBase = require("actors.common.interactable.base.interacted_item")

local M = Class(ActorBase)


function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:ReceiveBeginPlay()
    self:LogInfo("zsf", "[base_chest] BeginPlay %s %s %s", self:GetEditorID(), self.bLock, self)
    Super(M).ReceiveBeginPlay(self)
    if self.bLock then
        self.LockEffect:SetVisibility(true, false)
    end
    if self:IsServer() then
        self:UpdateTrackArrowState()
    end
end

function M:Multicast_ChestCurStatusChange_RPC()
    self:LogInfo("zsf", "[base_chest] Multicast_ChestCurStatusChange_RPC %s", self.ChestCurStatus)
    if self.ChestCurStatus == Enum.E_ChestStatus.Spawned then
        self.Niagara_Spawn:SetActive(true, true)
    elseif self.ChestCurStatus == Enum.E_ChestStatus.Unlocked then
    elseif self.ChestCurStatus == Enum.E_ChestStatus.Opened then
        self.SkeletalMesh:Play(false)
        self.Niagara_Open_Di:SetActive(true, true)
        self.Niagara_Open:SetActive(true, true)
        self:Client_RemoveInitationScreenUI()
        local MainActor = self:GetMainActor()
        if MainActor then
            MainActor:ChildTriggerMainActor(self)
        end
    elseif self.ChestCurStatus == Enum.E_ChestStatus.Fake then
    end
end

function M:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self.bLock and self.ChestCurStatus ~= Enum.E_ChestStatus.Opened and self.ChestCurStatus ~= Enum.E_ChestStatus.Fake and not self.bFakeTriggered then
        Super(M).OnBeginOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    end
end

function M:Client_AddInitationScreenUI_RPC()
    self:LogInfo("zsf", "Client_AddInitationScreenUI_RPC %s %s %s %s %s", self.bLock, not self.bLock, self:IsServer(), self.ChestCurStatus, Enum.E_ChestStatus.Opened)
    if not self.bLock and self.ChestCurStatus ~= Enum.E_ChestStatus.Opened and self.ChestCurStatus ~= Enum.E_ChestStatus.Fake then
        Super(M).Client_AddInitationScreenUI_RPC(self)
    end
end

function M:TriggerInteractedItem(PlayerActor, Damage, InteractLocation)
    Super(M).TriggerInteractedItem(self, PlayerActor, Damage, InteractLocation)
    if self.bFake then
        self:Server_SetChestStatue(Enum.E_ChestStatus.Fake)
        self.bFakeTriggered = true
    else
        self:Server_BranchChestLevel()
    end
end

function M:Server_SetChestStatue_RPC(ChestStatus)
    self:LogInfo("zsf", "Server_SetChestStatue %s %s", self.ChestCurStatus, ChestStatus)
    self.ChestCurStatus = ChestStatus
    self:Multicast_ChestCurStatusChange()
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    if Player and Player.EdRuntimeComponent then
        Player.EdRuntimeComponent:Server_OpenChest(self, self.ChestCurStatus)
    end
    self:UpdateTrackArrowState()
end

function M:OnRep_bLock()
    local bIsLock = self.bLock
    self:LogInfo("zsf", "[base_chest] OnRep_bLock %s %s %s", self:GetEditorID(), bIsLock, self)
    if not self:IsClient() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return
    end
    self.UnlockEffect:SetVisibility(not bIsLock, false)
    self.LockEffect:SetVisibility(bIsLock, false)
    self.UnlockEffect:SetActive(not bIsLock, true)
    self.LockEffect:SetActive(bIsLock, true)
    if bIsLock then
    else
        self.ChestCurStatus = Enum.E_ChestStatus.Unlocked
    end
end

function M:Server_MissionAction_ChestStatus_RPC(ActionChestStatus)
    if not self:IsServer() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return
    end
    self:LogInfo("zsf", "Server_MissionAction_ChestStatus_RPC %s %s %s", self:GetEditorID(), ActionChestStatus, self.bLock)
    if self.ChestCurStatus == Enum.E_ChestStatus.Opened then
        return
    end
    self.bLock = not self.bLock
    if not self.bLock then
        self.ChestStatus:Broadcast(Enum.E_ChestStatus.Unlocked)
    end
    self:UpdateTrackArrowState()
end

function M:Server_BranchChestLevel_RPC()
    self:LogInfo("zsf", "Server_BranchChestLevel_RPC %s", self.ChestCurStatus)
    self:Server_SetChestStatue(Enum.E_ChestStatus.Opened)
    self:Server_DropItem()
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
end

-- server
function M:UpdateTrackArrowState()
    if self.bLock then
        self.InteractTrackArrowComponent:DisableTrack()
    else
        self.InteractTrackArrowComponent:EnableTrack()
    end
end

-- client
function M:GetHudWorldLocation()
    return self:K2_GetActorLocation() + self.InteractTrackArrowComponent.TrackTargetOffset
end


return M