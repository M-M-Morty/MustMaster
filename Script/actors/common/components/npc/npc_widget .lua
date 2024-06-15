--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require('G')
local Component = require("common.component")
local NpcBubbleTable = require("common.data.npc_bubble_data").data
local utils = require("common.utils")
local UI3DComponent = require('CP0032305_GH.Script.framework.ui.ui_component_base')
local SubsystemUtils = require("common.utils.subsystem_utils")

local BillBoardState = {
    None = 0,
    Dead = 1,
    LowDis = 2,
}

local BubbleType = {
    None = 0,
    TriggerByTime = 1,
    TriggerByRange = 2,
}

local curState = 0

---@class BP_NPCWidget_C
local M = Component(UI3DComponent)
local decorator = M.decorator

function M:Initialize(Initializer)
    Super(M).Initialize(self, Initializer)
    self.CurrentBubbleIndex = 0
    self.BubbleIDList = {}
    self.DelayTimer = nil
    self.IntervalTimer = nil
    self.bAutoBubbleStarted = false
    self.bLocalSelfTalkingEnabled = false
    self.bMarkedTracked = false
    self.TaskIconType = 1
    self.TaskIconState = 0
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    if self.actor:IsServer() then
        -- server
        self.SelfTalkingID = self.actor:GetNpcSelfTalkingID()
        if self.SelfTalkingID ~= 0 then
            G.log:debug("xaelpeng", "BillBoardComponent:ReceiveBeginPlay SelfTalkingID %d", self.SelfTalkingID)
        end
    end

    if self.actor:IsClient() then
        if self.actor.bShowToplogo then
            self:OpenTopLogo()
        else
            self:CloseTopLogo()
        end
        self:OpenNPC(self.actor:GetNpcDisplayName(), "", self.actor:GetNpcDisplayIdentity(), self.NpcIconType,
            self.bMarkedTracked)

        self:InitializeBubbleIDList()
        if self.SelfTalkingID ~= 0 and self.bSelfTalkingEnabled then
            self:OnEnableLocalSelfTalking()
        end

    end
end

-- client
decorator.message_receiver()
function M:OnNpcDisplayNameUpdate()
    if not self.enabled then
        return
    end
    if self.actor:IsClient() then
        if self.actor.bShowToplogo then
            local ToplogoWidget = self:GetWidget()
            ToplogoWidget:SetName(self.actor:GetNpcDisplayName())
        end
    end
end

function M:OpenNPC(name, bubble, position, NpcIconType, bShowIcon)
    if self.isUIOpened then
        return
    end
    if self:GetWidget().OpenHudNPC == nil then
        return
    end
    self:GetWidget():OpenHudNPC(name, bubble, position, NpcIconType, bShowIcon)
    self.isUIOpened = true
end

function M:OpenTopLogo()
    self:GetWidget():OpenTopLogo()
end

function M:CloseTopLogo()
    self:GetWidget():CloseTopLogo()
end

function M:UpdateDistance(DeltaSeconds)
    if not self.isUIOpened then
        return
    end
    if not self:GetWidget().UpdateDistance then
        return
    end
    local Owner = self:GetOwner()
    local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
    local PlayerLocation = Controller:K2_GetPawn():K2_GetActorLocation()
    -- local PlayerCameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self, 0)
    -- local CameraLocation = PlayerCameraManager:GetCameraLocation()
    if not PlayerLocation or not Owner then
        return
    end
    local OwnerLocation = Owner:K2_GetActorLocation()
    local Distance = UE.UKismetMathLibrary.Vector_Distance(PlayerLocation, OwnerLocation)

    self:GetWidget():UpdateDistance(Distance * 0.01, DeltaSeconds)
    -- self:OnAdjustScale(Owner, Distance * 0.01)
    self:OnAdjustLocation()
    if self.isOpenHudHp then
        self:UpdateHUDHPDis(Distance)
    end
    if self.isOpenHudNPC then
        self:UpdateHUDNPCDis(Distance)
    end
end

function M:UpdateHUDNPCDis(Distance)

end

function M:OnAdjustLocation()
    if self:GetOwner() and UE.UKismetSystemLibrary.IsValid(self:GetOwner()) then
        local Owner = self:GetOwner()
        local WidgetLocation = self:K2_GetComponentLocation()
        local Origin, BoxExtent = UE.UKismetSystemLibrary.GetComponentBounds(Owner.Mesh)
        local OwnerLocation = Origin + BoxExtent
        local NpcOffset = OwnerLocation.Z + self.NpcOffset
        local NewVector = UE.FVector(WidgetLocation.X, WidgetLocation.Y, NpcOffset)
        local HitResult = UE.FHitResult()
        self:K2_SetWorldLocation(NewVector, false, HitResult, true)
    end
end

function M:OnAdjustScale(Owner, Distance)
    local Scale
    local newScale
    local dis = math.abs(Distance)
    Scale = dis / 120
    newScale = UE.FVector(Scale, Scale, Scale)

    self:SetWorldScale3D(newScale)
end

function M:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)
    if not self:GetOwner().GetAbilitySystemComponent then
        return
    end
    local ASC = self:GetOwner():GetAbilitySystemComponent()
    if ASC:HasGameplayTag(UE.UHiGASLibrary.RequestGameplayTag("StateGH.InDeath")) then
        self.SetCurState(BillBoardState.Dead)
    else
        self:CancelState(BillBoardState.Dead)
    end
    self:UpdateDistance(DeltaSeconds)
    self:StateChanged()
end

function M:SetCurState(state)
    if curState == 0 then
        curState = bit.lshift(1, state)
        return
    end
    curState = bit.bor(curState, bit.lshift(1, state))
    self:StateChanged()
end

function M:CancelState(state)
    if curState == 0 then
        return
    end
    curState = bit.band(curState, bit.bnot(bit.lshift(1, state)))
    self:StateChanged()
end

function M:StateChanged()
    if curState > 0 then
        self:GetWidget():SetVisibility(UE.ESlateVisibility.Hidden)
    else
        self:GetWidget():SetVisibility(UE.ESlateVisibility.Visible)
    end
end

-- server
function M:SetSelfTalkingID(SelfTalkingID)
    self.SelfTalkingID = SelfTalkingID
end

-- server
function M:EnableSelfTalking()
    self.bSelfTalkingEnabled = true
end

-- server
function M:DisableSelfTalking()
    self.bSelfTalkingEnabled = false
end

-- client
function M:OnRep_SelfTalkingID()
    -- OnRep before ReceiveBeginPlay
    if not self.enabled then
        return
    end
    self:OnDisableLocalSelfTalking()
    self:InitializeBubbleIDList()
    if self.SelfTalkingID ~= 0 and self.bSelfTalkingEnabled then
        self:OnEnableLocalSelfTalking()
    end
end

-- client
function M:OnRep_bSelfTalkingEnabled()
    -- OnRep before ReceiveBeginPlay
    if not self.enabled then
        return
    end
    if self.SelfTalkingID ~= 0 and self.bSelfTalkingEnabled then
        self:OnEnableLocalSelfTalking()
    else
        self:OnDisableLocalSelfTalking()
    end
end

-- client
function M:InitializeBubbleIDList()
    self.CurrentBubbleIndex = 0
    self.BubbleIDList = {}
    if self.SelfTalkingID ~= 0 then
        local NpcBubbleTableData = NpcBubbleTable[self.SelfTalkingID]
        if NpcBubbleTableData ~= nil then
            for BubbleID, _ in pairs(NpcBubbleTableData) do
                table.insert(self.BubbleIDList, BubbleID)
            end
            table.sort(self.BubbleIDList)
            if #self.BubbleIDList > 0 then
                self.CurrentBubbleIndex = 1
            end
        else
            G.log:error("xaelpeng", "BillboardComponent:InitializeBubbleIDList SelfTalkingID:%s not exist",
                self.SelfTalkingID)
        end
    end
end

function M:GetTableData()
    return NpcBubbleTable[self.SelfTalkingID]
end

function M:GetCurrentBubbleData()
    if self.CurrentBubbleIndex > 0 then
        local BubbleID = self.BubbleIDList[self.CurrentBubbleIndex]
        return NpcBubbleTable[self.SelfTalkingID][BubbleID]
    end
    return nil
end

function M:GetFirstBubbleData()
    if self.CurrentBubbleIndex > 0 then
        local BubbleID = self.BubbleIDList[1]
        return NpcBubbleTable[self.SelfTalkingID][BubbleID]
    end
    return nil
end

function M:GetSelfTalkingType()
    local BubbleData = self:GetFirstBubbleData() -- 以编号最小的Index为准
    if BubbleData ~= nil then
        return BubbleData.type
    end
    return BubbleType.None
end

function M:GetTriggerRadius()
    local BubbleData = self:GetFirstBubbleData() -- 以编号最小的Index为准
    if BubbleData ~= nil then
        return BubbleData.trigger_distance
    end
    return nil
end

function M:GetTriggerInterval()
    local BubbleData = self:GetFirstBubbleData() -- 以编号最小的Index为准
    if BubbleData ~= nil then
        return BubbleData.trigger_interval
    end
    return nil
end

-- client
function M:OnEnableLocalSelfTalking()
    if self.bLocalSelfTalkingEnabled then
        return
    end
    self.bLocalSelfTalkingEnabled = true
    local TalkingType = self:GetSelfTalkingType()
    G.log:debug("xaelpeng", "BillboardComponent:OnEnableLocalSelfTalking %s %s", self:GetOwner():GetName(), TalkingType)
    if TalkingType == BubbleType.TriggerByRange then
        self:EnableTriggerCollision()
    elseif TalkingType == BubbleType.TriggerByTime then
        self:EnableDelayTimer()
    end
end

-- client
function M:OnDisableLocalSelfTalking()
    if not self.bLocalSelfTalkingEnabled then
        return
    end
    G.log:debug("xaelpeng", "BillboardComponent:OnDisableLocalSelfTalking %s", self:GetOwner():GetName())
    self.bLocalSelfTalkingEnabled = false
    self.bAutoBubbleStarted = false
    self:DisableTriggerCollision()
    self:DisableDelayTimer()
    self:CancelIntervalTimer()
end

-- client
function M:EnableTriggerCollision()
    G.log:debug("xaelpeng", "BillboardComponent:EnableTriggerCollision %s radius:%s", self:GetOwner():GetName(),
        self:GetTriggerRadius())
    if self.TriggerCollision == nil then
        self.TriggerCollision = self:GetOwner():AddComponentByClass(UE.USphereComponent, false, UE.FTransform.Identity,
            false)
        self.TriggerCollision.OnComponentBeginOverlap:Add(self, self.OnTriggerBeginOverlap)
        self.TriggerCollision.OnComponentEndOverlap:Add(self, self.OnTriggerEndOverlap)
        self.TriggerCollision:SetCollisionProfileName("TrapActor", true)
        self.TriggerCollision:SetSphereRadius(self:GetTriggerRadius(), true)
    end
    self.TriggerCollision:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
    self.TriggerCollision:SetVisibility(true, false)
end

-- client
function M:DisableTriggerCollision()
    if self.TriggerCollision ~= nil then
        self.TriggerCollision:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        self.TriggerCollision:SetVisibility(false, false)
    end
end

-- client
function M:EnableDelayTimer()
    if self.DelayTimer == nil then
        local DelayTime = self:GetTriggerInterval()
        self.RemoveTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnDelayTimer }, DelayTime, false)
    end
end

-- client
function M:DisableDelayTimer()
    if self.DelayTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.DelayTimer)
        self.DelayTimer = nil
    end
end

-- client
function M:OnDelayTimer()
    self.DelayTimer = nil
    self:StartPlayBubble()
end

-- client
function M:OnTriggerBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    G.log:debug("xaelpeng", "BillboardComponent:OnTriggerBeginOverlap %s OtherActor:%s", self:GetOwner():GetName(),
        OtherActor:GetName())
    if OtherActor.IsPlayer ~= nil and OtherActor:IsPlayer() then
        self:StartPlayBubble()
    end
end

-- client
function M:OnTriggerEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if OtherActor.IsPlayer ~= nil and OtherActor:IsPlayer() then
        self:StopPlayBubble()
    end
end

-- client
function M:StartPlayBubble()
    self.bAutoBubbleStarted = true
    self:PlayBubble()
end

-- client
function M:StopPlayBubble()
    self.bAutoBubbleStarted = false
end

-- client
function M:PlayBubble()
    if self.IntervalTimer ~= nil then
        return
    end
    local BubbleID = self.BubbleIDList[self.CurrentBubbleIndex]
    local NpcBubbleTableData = NpcBubbleTable[self.SelfTalkingID]
    local BubbleTableData = NpcBubbleTableData[BubbleID]
    if BubbleTableData then
        self:DoShowBubble(BubbleTableData.content)
    end

    if self:GetCurrentBubbleData() == nil then
        return
    end

    local IntervalTime = self:GetCurrentBubbleData().bubble_interval
    self.IntervalTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnIntervalTimer }, IntervalTime, false)
    self.CurrentBubbleIndex = self.CurrentBubbleIndex + 1
    if self.CurrentBubbleIndex > #self.BubbleIDList then
        self.CurrentBubbleIndex = 1
    end
end

-- client
function M:OnIntervalTimer()
    self.IntervalTimer = nil
    if self.bAutoBubbleStarted then
        self:PlayBubble()
    end
end

-- client
function M:CancelIntervalTimer()
    if self.IntervalTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.IntervalTimer)
        self.IntervalTimer = nil
    end
end

function M:ReceiveEndPlay()
    if self.actor:IsClient() then
        self:DisableDelayTimer()
        self:CancelIntervalTimer()
    end
    Super(M).ReceiveEndPlay(self)
end

-- client
function M:DoShowBubble(Content)
    local HeadWidget = self:GetWidget()
    if HeadWidget then
        HeadWidget:SetBubble(Content)
    end
end

function M:Multicast_DisplayMissionBubble_RPC(BubbleID, DelayResumeTime)
    if not self.actor then
        return
    end
    if self.actor:IsClient() then
        local FirstBubbleData = self:GetFirstBubbleDataOfTable(BubbleID)
        if FirstBubbleData == nil then
            G.log:error("xaelpeng", "BillboardComponent:Multicast_DisplayMissionBubble no data found for BubbleID %d",
                BubbleID)
            return
        end
        if self.bAutoBubbleStarted then
            self:CancelIntervalTimer()
            self.IntervalTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnIntervalTimer },
                DelayResumeTime, false)
        end
        self:DoShowBubble(FirstBubbleData.content)
    end
end

function M:GetFirstBubbleDataOfTable(BubbleID)
    local NpcBubbleTableData = NpcBubbleTable[BubbleID]
    if NpcBubbleTableData ~= nil then
        local BubbleSubIndexList = {}
        for BubbleSubIndex, _ in pairs(NpcBubbleTableData) do
            table.insert(BubbleSubIndexList, BubbleSubIndex)
        end
        table.sort(BubbleSubIndexList)
        if #BubbleSubIndexList > 0 then
            return NpcBubbleTableData[BubbleSubIndexList[1]]
        end
    end
    return nil
end

function M:MarkTracked(TaskIconType, TaskIconState)
    self.bMarkedTracked = true
    self.TaskIconType = TaskIconType
    self.TaskIconState = TaskIconState
    if self.enabled then
        local HeadWidget = self:GetWidget()
        if HeadWidget then
            HeadWidget:ShowTaskIcon(self.TaskIconType, self.TaskIconState)
        end
    end
end

function M:SetBillboardVisibility(bIsVisible)
    ---被uimanager统一隐藏 bHidden3DUI为true，则弱追踪不进行SetVisibility
    ---uimanager中的hide优先级更高
    if bIsVisible then
        if not self.bHidden3DUI then
            self:SetVisibility(bIsVisible)
        end
    else
        self:SetVisibility(bIsVisible)
    end
end

function M:UnMarkTracked()
    self.bMarkedTracked = false
    if self.enabled then
        local HeadWidget = self:GetWidget()
        if HeadWidget then
            HeadWidget:HideTaskIcon()
        end
        self:SetBillboardVisibility(false)
    end
end

return M
