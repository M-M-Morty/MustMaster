--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/05/26
--

---@BP_Elevator_C

require "UnLua"
local utils = require("common.utils")
local string = require("string")
local math = require("math")
local G = require("G")
local ActorBase = require("actors.common.interactable.base.interacted_item")
local EdUtils = require("common.utils.ed_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BPConst = require("common.const.blueprint_const")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local ConstTextTable = require("common.data.const_text_data").data

local M = Class(ActorBase)
local decorator = M.decorator

function M:Initialize(...)
    Super(M).Initialize(self, ...)
    self.offsetZ = -100
end

function M:MakeCurSwitchActor(cur_switch)
    if cur_switch == nil then
        local IDs = self:GetActorIds("arrSwitches")
        cur_switch = self:GetEditorActor(IDs[self.iCurFloor+1])
    end
    self.cur_switch_actor = cur_switch
    self.iCurFloor = self:GetCurFloor()
end

function M:GetCurSwitchActor()
    return self.cur_switch_actor
end

function M:IsPlayerOn(OtherActor)
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    local Owner = OtherActor:GetOwner()
    if PlayerControl ~= nil and Owner == PlayerControl then
        self.PlayerActor = OtherActor
        return true
    end
    return  false
end

function M:GetCurFloor()
    local Actors = self:GetActorSwitches()
    local Len = #Actors
    local CurSwitchActor = self:GetCurSwitchActor()
    for ind=Len,1,-1 do
        local Actor = Actors[ind][1]
        local bCurFloor = false
        for _,cActor in ipairs(Actors[ind]) do
            if cActor == CurSwitchActor then
                bCurFloor = true
                break
            end
        end
        if bCurFloor then
            return ind-1
        end
    end
    return 0
end

function M:GetUIShowActors()
    -- 这里显示楼层和UI需要迭代 (倒叙按钮状态); 停止之后需要弹出选择楼层的按钮
    local Actors = self:GetActorSwitches()
    local FoundActors = {}
    local Len = #Actors
    local CurSwitchActor = self:GetCurSwitchActor()
    local bCur = false
    local ForceIndex
    for ind=Len,1,-1 do
        local Actor = Actors[ind][1]
        if ind<=self.arrFloorText:Length() then
            Actor.sUIPick = self.arrFloorText[ind]
        else
            Actor.sUIPick = string.format(ConstTextTable.ELEVATOR_F_FLOOR.Content, ind)
        end
        local icon
        local bCurFloor = false
        for _,cActor in ipairs(Actors[ind]) do
            if cActor == CurSwitchActor then
                bCurFloor = true
                break
            end
        end
        if bCurFloor then
            icon = self.mapIcon:FindRef("cur")
            bCur = true
            ForceIndex = Len-ind+1
        else
            if bCur then
                icon = self.mapIcon:FindRef("down")
            else
                icon = self.mapIcon:FindRef("up")
            end
        end
        Actor.sUIIcon = icon
        Actor.bUseable = not bCurFloor
        Actor.bNotSort = true
        Actor.ForceIndex = ForceIndex
        Actor.bPlayerOnMove = true
        table.insert(FoundActors, Actor)
    end
    return FoundActors
end

function M:SetAllSwitchInteractable(bInteractable)
    local Actors = self:GetActorSwitches()
    for _,SwitchActors in ipairs(Actors) do
        for _,SwitchActor in ipairs(SwitchActors) do
            SwitchActor:SetSwitchInteractable(bInteractable)
        end
    end
end

function M:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    self:LogInfo("zsf", "[elevator] OnBeginOverlap %s", self:IsPlayerOn(OtherActor))
    if self:IsPlayerOn(OtherActor) then
        self.bPlayerOn = true
        if self:HasAuthority() then
        else
           self:All_Client_RemoveInitationScreenUI_RPC()
        end
        self:SetAllSwitchInteractable(false)
        self:SetInteractable(Enum.E_InteractedItemStatus.Interactable)
    end
    Super(M).OnBeginOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
end

function M:OnEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    Super(M).OnEndOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    self.bPlayerOn = false
    self.PlayerActor = nil
    self:LogInfo("zsf", "[elevator] OnEndOverlap")
    self:SetAllSwitchInteractable(true)
    self:SetInteractable(Enum.E_InteractedItemStatus.UnInteractable)
end

function M:All_Client_RemoveInitationScreenUI_RPC()
    --self:LogInfo("zsf", "[elevator] All_Client_RemoveInitationScreenUI_RPC")
    local Actors = self:GetActorSwitches()
    for _,SwitchActors in ipairs(Actors) do
        for _,SwitchActor in ipairs(SwitchActors) do
            SwitchActor:Client_RemoveInitationScreenUI()
        end
    end
    self:Client_RemoveInitationScreenUI()
end

function M:DisablePlayerCollisionWhenMove(bDisable)
    do return end
    local OverlapActors = UE.TArray(UE.AActor)
    self.Box:GetOverlappingActors(OverlapActors)
    if OverlapActors:Length() > 0 then
        for Ind=1,OverlapActors:Length() do
            local Actor = OverlapActors[Ind]
            if Actor.CapsuleComponent and Actor.Mesh then
                if bDisable then
                    self.OldPlayerCapsuleComponentCollision = Actor.CapsuleComponent:GetCollisionEnabled()
                    Actor.CapsuleComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
                    self.OldPlayerMeshCollision = Actor.Mesh:GetCollisionEnabled()
                    Actor.Mesh:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
                else
                    Actor.CapsuleComponent:SetCollisionEnabled(self.OldPlayerCapsuleComponentCollision)
                    Actor.Mesh:SetCollisionEnabled(self.OldPlayerMeshCollision )
                end
            end
        end
    end
end

-- GetSwitchActors at the same floor
function M:GetCurSwitchActors()
    local Actors = self:GetActorSwitches()
    local Len = #Actors
    local CurSwitchActor = self:GetCurSwitchActor()
    for ind=Len,1,-1 do
        local cActors = Actors[ind]
        for _,Actor in ipairs(cActors) do
            if Actor == CurSwitchActor then
                return cActors
            end
        end
    end
    return {}
end

---@param InteractLocation 电梯需要移动的目标位置
function M:MoveToSwitchActor(InteractLocation)
    self:SetServerAcceptClientAuthoritativePosition(true)
    self:DisablePlayerCollisionWhenMove(true)
    local TmpLocationZ = InteractLocation.Z + self.offsetZ
    local NewLocation = self:K2_GetActorLocation()
    self:LogInfo("zsf", "[elevator] MoveToSwitchActor %s %s %s", InteractLocation, NewLocation.Z, self.eElevatorStatus)
    NewLocation.Z = TmpLocationZ
    self.ServerLocation = NewLocation
    self.vServerLocation = NewLocation
    self.eElevatorStatus = Enum.E_ElevatorStatus.Moving
    if self:HasAuthority() then
        self:Multicast_ChangeElevatorStatus(self.eElevatorStatus)
    end
    if self:IsClient() then
        -- when start move; play sound
        HiAudioFunctionLibrary.PlayAKAudio("Play_Scn_Itm_Elevator_RunningStart", self)
        utils.DoDelay(self, 0.5, function()
            HiAudioFunctionLibrary.PlayAKAudio("Play_Scn_Itm_Elevator_RunningLoop", self)
            local cActors = self:GetCurSwitchActors()
            for _,cActor in ipairs(cActors) do
                HiAudioFunctionLibrary.PlayAKAudio("Play_Scn_Itm_Elevator_CallRunningLoop", cActor)
            end
        end)
    end
    --local HitResult = UE.FHitResult()
    --self:K2_SetActorLocation(NewLocation, false, HitResult, false)
end

function M:SetServerAcceptClientAuthoritativePosition(bAccept)
    local PlayerActor = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    if PlayerActor and PlayerActor.CharacterMovement then
        self:LogInfo("zsf", "SetServerAcceptClientAuthoritativePosition %s", bAccept)
        PlayerActor.CharacterMovement.bServerAcceptClientAuthoritativePosition = bAccept
    end
end

function M:AllChildReadyServer()
    local Actors = self:GetActorSwitches()
    for _,cActors in ipairs(Actors) do
        for _,Actor in ipairs(cActors) do
            if Actor then
                if Actor.MakeMainActor then
                    Actor:MakeMainActor(self)
                end
            end
        end
    end
    if #Actors > 0 then
        --self.offsetZ = self:K2_GetActorLocation().Z - Actors[self.iCurFloor+1]:K2_GetActorLocation().Z
    end
    self:PreviewElevator()
    self:MakeCurSwitchActor()
    self:LogInfo("zsf", "[elevator] AllChildReadyServer %s", self.offsetZ)
    Super(M).AllChildReadyServer(self)
end

function M:GetActorSwitches()
    local IDs = self:GetActorIds("arrSwitches")
    local Actors = {}
    local SoftActors = {}
    for ind=1,#IDs do
        local EditorID = tostring(IDs[ind])
        local Actor = self:GetEditorActor(EditorID)
        local t = {Actor}
        local OtherActor = self.mapSwitches:FindRef(ind-1)
        if OtherActor then
            table.insert(t, OtherActor:Get())
        end
        table.insert(Actors, t)
        table.insert(SoftActors, UE.FSoftObjectPtr(Actor))
   end

    self["arrSwitches"] = SoftActors
    return Actors
end

function M:AllChildReadyClient()
    local Actors = self:GetActorSwitches()
    for _,cActors in ipairs(Actors) do
        for _,Actor in ipairs(cActors) do
            if Actor then
                if Actor.MakeMainActor then
                    self:LogInfo("zsf", "[elevator] AllChildReadyClient %s %s", Actor, G.GetDisplayName(Actor))
                    Actor:MakeMainActor(self)
                end
            end
        end
    end
    self:PreviewElevator()
    self:MakeCurSwitchActor()
    Super(M).AllChildReadyClient(self)
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    self.vElevatorLocation = self:K2_GetActorLocation()
    self.ServerLocation = self.vElevatorLocation
    self.SphereOpen.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap_SphereOpen)
    self.SphereOpen.OnComponentEndOverlap:Add(self, self.OnEndOverlap_SphereOpen)
    for Ind=1,4 do
        local Name = "Door"..tostring(Ind)
        if self[Name] then
            self[Name].OnComponentHit:Add(self, self.OnDoorComponentHit)
            self[Name].OnComponentBeginOverlap:Add(self, self.OnDoorOverlap)
        end
    end
    self:PreviewElevator()
    self:MakeCurSwitchActor()
end

function M:IsDoorMovingStatus(DoorName)
    return self.mapDoorStatus:FindRef(DoorName)
end

function M:SetDoorMovingStatus(DoorNames, bMoving)
    for Ind=1,DoorNames:Length() do
        local Name = DoorNames:Get(Ind)
        local Node = self.mapDoorStatus:FindRef(Name)
        if Node ~= nil then
            self.mapDoorStatus:Add(Name, bMoving)
            if self[Name] then
                if bMoving then
                    self[Name]:SetCollisionProfileName('Interacted_ItemTrigger', true)
                else
                    self[Name]:SetCollisionProfileName('SmallObjectUnBreakable', true)
                end
            end
        end
    end
end

function M:DoorHitPlayer(HitComponent, OtherActor, Hit)
    do return end -- todo: fix it受击还是会卡住角色；
    if not self:HasAuthority() then
        return
    end
    -- 角色如果在电梯上就不做处理
    if self:HasPlayerOn() then
        return
    end
    local DoorName = G.GetObjectName(HitComponent)
    if not self:IsDoorMovingStatus(DoorName) then
        return
    end
    self:LogInfo("zsf", "OnDoorComponentHit %s %s %s", G.GetDisplayName(HitComponent), G.GetObjectName(HitComponent), G.GetDisplayName(OtherActor))
    local ImpactPoint = Hit.ImpactPoint
    local ImpactNormal = Hit.ImpactNormal
    ImpactNormal:Normalize()
    local NowLocation = OtherActor:K2_GetActorLocation()
    --local EndLocation = UE.UKismetMathLibrary.Add_VectorVector(NowLocation, UE.UKismetMathLibrary.Multiply_VectorVector(ImpactNormal, UE.UKismetMathLibrary.Conv_FloatToVector(-100.0)))
    --OtherActor:K2_SetActorLocation(EndLocation, false, nil, true)
    --if OtherActor.Mesh then
    --    local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(OtherActor.Mesh, self.HitAnim, 1.0)
    --end
    if OtherActor.SendMessage then
        OtherActor:SendMessage("BreakSkill")

        local HitPayload = UE.FGameplayEventData()
        -- "Event.Hit.KnockBack.Light"
        HitPayload.EventTag = UE.UHiGASLibrary.RequestGameplayTag("Event.Hit.KnockBack.Heavy")
        HitPayload.Target = OtherActor
        HitPayload.Instigator = self

        local tag = UE.UHiGASLibrary.RequestGameplayTag("Event.Hit.KnockBack.Heavy")
        local KnockInfo = UE.NewObject(FunctionUtil:IndexRes('UD_KnockInfo_C'), OtherActor)
        KnockInfo.HitTags.GameplayTags:Add(tag)
        --local game_mode = UE.UGameplayStatics.GetGameMode(self:GetWorld())
        KnockInfo.Hit = Hit
        HitPayload.OptionalObject = KnockInfo
        OtherActor:SendMessage("HandleHitEvent", HitPayload)
    end
end

function M:OnDoorOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    local HitResult = UE.FHitResult()
    HitResult.ImpactPoint = OtherActor:K2_GetActorLocation()
    HitResult.ImpactNormal = UE.UKismetMathLibrary.Multiply_VectorFloat(OtherActor:GetActorForwardVector(), -1.0)
    self:DoorHitPlayer(OverlappedComponent, OtherActor, HitResult)
end

function M:OnDoorComponentHit(HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
   self:DoorHitPlayer(HitComponent, OtherActor, Hit)
end

function M:OnBeginOverlap_SphereOpen(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self:IsMoving() then
        if OtherActor and OtherActor.CharacterMovement then
            if self:IsClient() then
                if not self.bSwitchDoorOpen then
                    -- if player is on the elveator; when open don't play sound
                    HiAudioFunctionLibrary.PlayAKAudio("Play_Scn_Itm_Elevator_Open", self)
                end
            end
            self:SwitchDoor(true)
        end
    end
end

function M:OnEndOverlap_SphereOpen(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if not self:IsMoving() then
        if OtherActor and OtherActor.CharacterMovement then
            if self:IsClient() then
                if self.bSwitchDoorOpen then
                    HiAudioFunctionLibrary.PlayAKAudio("Play_Scn_Itm_Elevator_Open", self)
                end
            end
            self:SwitchDoor(false)
        end
        local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
        if GameState then
            GameState:PlayerStopLockMode()
        end
    end
end

function M:IsMoving()
    return self.eElevatorStatus == Enum.E_ElevatorStatus.Moving
end

function M:IsOpenDoorTwo()
    local Actors = self:GetActorSwitches()
    local Len = #Actors
    local CurSwitchActor = self:GetCurSwitchActor()
    for ind=Len,1,-1 do
        local cActors = Actors[ind]
        for _,Actor in ipairs(cActors) do
            if Actor == CurSwitchActor then
                for ind2=1,self.arrFloorOpenTwo:Length() do
                    local Index = self.arrFloorOpenTwo:Get(ind2)
                    if ind == Index+1 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function M:IsOpenDoorForward()
    if self:GetCurSwitchActor() then
        return self:IsActorForward(self:GetCurSwitchActor())
    else
        local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
        return self:IsActorForward(Player)
    end
end

function M:SetDoorStatus(eStatus)
    if eStatus == Enum.E_ElevatorDoorStatus.ForwardOpened then
        self.eDoorForwardStatus = Enum.E_ElevatorDoorStatus.ForwardClosed
    elseif eStatus == Enum.E_ElevatorDoorStatus.ForwardClosed then
        self.eDoorForwardStatus = Enum.E_ElevatorDoorStatus.ForwardOpened
    elseif eStatus == Enum.E_ElevatorDoorStatus.BackwardOpened then
        self.eDoorBackwardStatus = Enum.E_ElevatorDoorStatus.BackwardClosed
    elseif eStatus == Enum.E_ElevatorDoorStatus.BackwardClosed then
        self.eDoorBackwardStatus = Enum.E_ElevatorDoorStatus.BackwardOpened
    end
end

function M:SwitchDoor(bOpen)
    self:LogInfo("zsf", "[elevator] SwitchDoor %s %s %s %s %s", self.eDoorForwardStatus, self.eDoorBackwardStatus, self:IsOpenDoorForward(), bOpen, self:GetCurSwitchActor())
    self.bSwitchDoorOpen = bOpen
    if bOpen then
        if self:IsOpenDoorTwo() then
            if self.eDoorForwardStatus == Enum.E_ElevatorDoorStatus.ForwardClosed then
                self:BP_SwitchDoor_Front(self.eDoorForwardStatus)
                self:SetDoorStatus(self.eDoorForwardStatus)
            end
            if self.eDoorBackwardStatus == Enum.E_ElevatorDoorStatus.BackwardClosed then
                self:BP_SwitchDoor_Back(self.eDoorBackwardStatus)
                self:SetDoorStatus(self.eDoorBackwardStatus)
            end
        else
            if self:IsOpenDoorForward() then
                if self.eDoorForwardStatus == Enum.E_ElevatorDoorStatus.ForwardClosed then
                    self:BP_SwitchDoor_Front(self.eDoorForwardStatus)
                    self:SetDoorStatus(self.eDoorForwardStatus)
                end
            else
                if self.eDoorBackwardStatus == Enum.E_ElevatorDoorStatus.BackwardClosed then
                    self:BP_SwitchDoor_Back(self.eDoorBackwardStatus)
                    self:SetDoorStatus(self.eDoorBackwardStatus)
                end
            end
        end
    else
        if self.eDoorForwardStatus == Enum.E_ElevatorDoorStatus.ForwardOpened then
            self:BP_SwitchDoor_Front(self.eDoorForwardStatus)
            self:SetDoorStatus(self.eDoorForwardStatus)
        end
        if self.eDoorBackwardStatus == Enum.E_ElevatorDoorStatus.BackwardOpened then
            self:BP_SwitchDoor_Back(self.eDoorBackwardStatus)
            self:SetDoorStatus(self.eDoorBackwardStatus)
        end
    end
end

function M:Multicast_SwitchDoor_RPC(bOpen)
    local DeleyTime = 5.0
    if self:IsClient() then
        -- when arrive; play sound
        utils.DoDelay(self, DeleyTime-2.0, function()
            HiAudioFunctionLibrary.PlayAKAudio("Stop_Scn_Itm_Elevator_RunningLoop", self)
            HiAudioFunctionLibrary.PlayAKAudio("Play_Scn_Itm_Elevator_Arrival", self)
            local cActors = self:GetCurSwitchActors()
            for _,cActor in ipairs(cActors) do
                HiAudioFunctionLibrary.PlayAKAudio("Stop_Scn_Itm_Elevator_RunningLoop", cActor)
            end
        end)
    end

    utils.DoDelay(self, DeleyTime, function()
        if not self:HasAuthority() then
            local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
            if GameState and self.bPlayerOn and bOpen then
                GameState:PlayerStopLockMode()
            end
        end
        self:SetServerAcceptClientAuthoritativePosition(false)
        self:DisablePlayerCollisionWhenMove(false)
        self:SwitchDoor(true)
    end)
end

function M:Multicast_ChangeElevatorStatus_RPC(eStatus)
    if not self:HasAuthority() then
        local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
        if GameState and self.bPlayerOn then
            if eStatus ~= Enum.E_ElevatorStatus.Stop then
                --GameState:PlayerStartLockMode()
            end
        end
        self:All_Client_RemoveInitationScreenUI_RPC()
    end
    self:LogInfo("zsf", "ChangeElevatroStatus_RPC %s %s %s", eStatus, Enum.E_ElevatorStatus.Stop, self.bPlayerOn)
    if not self:HasAuthority() then
        local Actors = self:GetActorSwitches()
        for _,SwitchActors in ipairs(Actors) do
            for _,SwitchActor in ipairs(SwitchActors) do
                --self:LogInfo("zsf", "[elevator] MoveToCurSwitchActor111 %s %s %s %s", SwitchActor, G.GetDisplayName(SwitchActor), eStatus, eStatus == Enum.E_ElevatorStatus.Stop)
                SwitchActor:SetSwitchColor(eStatus == Enum.E_ElevatorStatus.Stop)
            end
        end
    end
    if eStatus == Enum.E_ElevatorStatus.Stop then
        if self:HasAuthority() then -- 服务端达到则打开门
            local CurSwitchActor = self:GetCurSwitchActor()
            CurSwitchActor:MoveToMiddle()
            self:Multicast_SwitchDoor(true)
        end
    elseif eStatus == Enum.E_ElevatorStatus.Moving then
        self:SwitchDoor(false)
    end
end

function M:Move_Server(DeltaSeconds)
    if self.eElevatorStatus ~= Enum.E_ElevatorStatus.Moving then
        return
    end
    local NewLocation = self:K2_GetActorLocation()
    local bFinished = false
    if NewLocation.Z > self.ServerLocation.Z then
        NewLocation.Z = NewLocation.Z - self.fMoveDelta
        bFinished = NewLocation.Z < self.ServerLocation.Z
    else
        NewLocation.Z = NewLocation.Z + self.fMoveDelta
        bFinished = NewLocation.Z >= self.ServerLocation.Z
    end
    if bFinished then
        NewLocation.Z = self.ServerLocation.Z
        self.eElevatorStatus = Enum.E_ElevatorStatus.Stop
        self:Multicast_ChangeElevatorStatus(self.eElevatorStatus)
    end
    local HitResult = UE.FHitResult()
    self:K2_SetActorLocation(NewLocation, false, HitResult, false)
    self.vElevatorLocation = NewLocation
    --self:LogInfo("zsf", "MoveServer %s %s %s", NewLocation, self.ServerLocation, bFinished)
end

function M:Move_Client(DeltaSeconds)
    if self.eElevatorStatus ~= Enum.E_ElevatorStatus.Moving then
        return
    end
    self:All_Client_RemoveInitationScreenUI_RPC()
    local OldLocation = self:K2_GetActorLocation()
    local NewLocation = UE.UKismetMathLibrary.VInterpTo(OldLocation, self.vElevatorLocation, DeltaSeconds, 1.0)
    local HitResult = UE.FHitResult()
    self:K2_SetActorLocation(NewLocation, false, HitResult, false)
    local delta_z = math.abs(self.vServerLocation.Z - NewLocation.Z)
    if delta_z < 1 then
        self:LogInfo("zsf", "Move_Client %s %s %s", self.vServerLocation.Z, NewLocation.Z, delta_z)
        local CurSwitchActor = self:GetCurSwitchActor()
        CurSwitchActor:MoveToMiddle()
        self.eElevatorStatus = Enum.E_ElevatorStatus.Stop
        -- 停下来之后，如果角色在上边需要弹出交互按钮
        self:ShowInteractedIUIWhenStop()
    end
end

function M:HasPlayerOn()
    local OverlapActors = UE.TArray(UE.AActor)
    self.Box:GetOverlappingActors(OverlapActors)

    if OverlapActors:Length() > 0 then
        for ind=1,OverlapActors:Length() do
            if self:IsPlayerOn(OverlapActors[ind]) then
                return true
            end
        end
    end
    return false
end

function M:ShowInteractedIUIWhenStop()
    local OverlapActors = UE.TArray(UE.AActor)
    self.Box:GetOverlappingActors(OverlapActors)

    if OverlapActors:Length() > 0 then
        for ind=1,OverlapActors:Length() do
            if self:IsPlayerOn(OverlapActors[ind]) then
                self:LogInfo("zsf", "MoveServer %s %s %s", self.ServerLocation, OverlapActors:Length(), G.GetDisplayName(OverlapActors[ind]))
                self:OnBeginOverlap(nil, OverlapActors[ind], nil, nil, nil, nil)
                local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
                if GameState then
                    GameState:PlayerStopLockMode()
                end
                break
            end
        end
    end
end

function M:CloseAreaAbilityUsePanel()
    self:ShowInteractedIUIWhenStop()
end

function M:CloseAreaAbilityCopyPanel()
    self:ShowInteractedIUIWhenStop()
end

function M:Move(DeltaSeconds)
    if self:HasAuthority() then
        self:Move_Server(DeltaSeconds)
    else
        self:Move_Client(DeltaSeconds)
    end
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
    self:Move(DeltaSeconds)
end

function M:ReceiveEndPlay()
    self.SphereOpen.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_SphereOpen)
    self.SphereOpen.OnComponentEndOverlap:Remove(self, self.OnEndOverlap_SphereOpen)
    for Ind=1,4 do
        local Name = "Door"..tostring(Ind)
        if self[Name] then
            self[Name].OnComponentHit:Remove(self, self.OnDoorComponentHit)
            self[Name].OnComponentBeginOverlap:Remove(self, self.OnDoorOverlap)
        end
    end
    Super(M).ReceiveEndPlay(self)
end

return M