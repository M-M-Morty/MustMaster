--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local OfficeConst = require("common.const.office_const")
local json = require("thirdparty.json")
local DataManager = require("common.DataManager")
local GameConstData = require("common.data.game_const_data").data
local MapLegendTable = require("common.data.firm_map_legend_type_data")
local MapLegendData = require("common.data.firm_map_legend_type_data").data
local SubsystemUtils = require("common.utils.subsystem_utils")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@type TeleportComponent_C
local TeleportComponent = Component(ComponentBase)

local decorator = TeleportComponent.decorator
local DefaultRotation = UE.UKismetMathLibrary.MakeRotator(0, 0, 0)

----test code scene capture potal----------
--decorator.message_receiver()
--function TeleportComponent:OnBecomePlayer()
--    local Transform = UE.UKismetMathLibrary.MakeTransform(UE.FVector(0, 0, 0), UE.FRotator(0, 0, 0), UE.FVector(1, 1, 1))    
--    local SpawnParameters = UE.FActorSpawnParameters()
--    local PortalManagerActorClass = UE.UClass.Load("Blueprint'/HiPortal/BP_PotalManagerActor.BP_PotalManagerActor_C'")
--    self.PortalManager =  GameAPI.SpawnActor(self.actor:GetWorld(), PortalManagerActorClass, Transform, SpawnParameters, {})
--    self.PortalManager:K2_AttachToActor(self.actor, "None", UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, true)
--    self.PortalManager:SetControllerOwner(self.actor:GetController(), self.actor)
--    self.PortalManager:GeneratePortalTexture()
--end
--
--decorator.message_receiver()
--function TeleportComponent:OnReceiveTick(DeltaSeconds)
--    if self.actor:IsClientPlayer() then
--        if self.PortalManager and self.PortalManager:IsValid() then
--            self.PortalManager:update(DeltaSeconds)
--        end
--    end
--end
--function TeleportComponent:Start()
--    Super(TeleportComponent).Start(self)    
--    self.TimerHandle = nil
--end
--
--
--
--function TeleportComponent:Stop()
--    Super(TeleportComponent).Stop(self)    
--    if self.TimerHandle then
--        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
--        self.TimerHandle = nil
--    end
--end
--function TeleportComponent:OnResumeAdditivePivotLagSpeed(SavedValue)
--    G.log:debug("hyteleport", "OnResumeAdditivePivotLagSpeed... %s", tostring(SavedValue))
--    --local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
--    --if CameraManager and CameraManager:IsValid() then
--    --    local CameraAnimInstance = CameraManager.CameraBehavior:GetAnimInstance()        
--    --    if CameraAnimInstance and CameraAnimInstance:IsValid() then
--    --        CameraAnimInstance.AdditivePivotLagSpeed = SavedValue            
--    --    end
--    --end       
--end
-----------------------------

--run on client
function TeleportComponent:CameraFollowPlayer()
    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    if CameraManager and CameraManager:IsValid() then
        local CameraAnimInstance = CameraManager.CameraBehavior:GetAnimInstance()        
        if CameraAnimInstance and CameraAnimInstance:IsValid() then
            local AdditivePivotLagSpeed = CameraAnimInstance.AdditivePivotLagSpeed
            CameraAnimInstance.AdditivePivotLagSpeed = 5000.0
            --self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({self, self.OnResumeAdditivePivotLagSpeed}, AdditivePivotLagSpeed) 
        end
    end    
end



function TeleportComponent:Client_OnTeleportSucceed_RPC(DestRotation, DestVelocity)
    if self.actor:IsClientPlayer() then
        --utils.PrintString("OnTeleportSucceed"..tostring(DestRotation), UE.FLinearColor(0, 1, 0, 1), 2)
        local Controller = self.actor:GetController()
        if Controller and Controller:IsValid() then
            Controller:SetControlRotation(DestRotation)
            self:CameraFollowPlayer()
        end
        self.actor.CharacterMovement.Velocity = DestVelocity        
        --self.actor.AppearanceComponent.LastVelocityRotation = DestRotation
        local CustomSmoothContext = UE.FCustomSmoothContext()
        self.actor.AppearanceComponent:SetCharacterRotation(DestRotation, false, CustomSmoothContext)
    end
end

--run on server
function TeleportComponent:TeleportTo(DestLocation, DestRotation, KeepSpeed, RotateController)
    local Result = false
    if self.actor:IsValid() then
        local SaveVelocity = UE.FVector(0.0, 0.0, 0.0)
        local Dots = UE.FVector(0.0, 0.0, 0.0)
        if KeepSpeed then
            SaveVelocity = self.actor.CharacterMovement:GetLastUpdateVelocity()
            Dots.X = UE.UKismetMathLibrary.Dot_VectorVector(SaveVelocity, self.actor:GetActorForwardVector())
            Dots.Y = UE.UKismetMathLibrary.Dot_VectorVector(SaveVelocity, self.actor:GetActorRightVector())
            Dots.Z = UE.UKismetMathLibrary.Dot_VectorVector(SaveVelocity, self.actor:GetActorUpVector())
        end
        Result = self.actor:K2_TeleportTo(DestLocation, DestRotation)
        if Result then     
            local DestVelocity = UE.FVector(0.0, 0.0, 0.0)
            if KeepSpeed then
                local DestForwardVector = UE.UKismetMathLibrary.Multiply_VectorFloat(UE.UKismetMathLibrary.GetForwardVector(DestRotation), Dots.X)
                local DestRightVector = UE.UKismetMathLibrary.Multiply_VectorFloat(UE.UKismetMathLibrary.GetRightVector(DestRotation), Dots.Y)
                local DestUpVector = UE.UKismetMathLibrary.Multiply_VectorFloat(UE.UKismetMathLibrary.GetUpVector(DestRotation), Dots.Z)
                DestVelocity = DestForwardVector + DestRightVector + DestUpVector
                self.actor.CharacterMovement.Velocity = DestVelocity
                --self.actor.AppearanceComponent.LastVelocityRotation = DestRotation
                local CustomSmoothContext = UE.FCustomSmoothContext()
                self.actor.AppearanceComponent:SetCharacterRotation(DestRotation, false, CustomSmoothContext)
            end         
            self:Client_OnTeleportSucceed(DestRotation, DestVelocity)
        end                
    end    
    return Result
end


function TeleportComponent:Server_TeleportToOffice_RPC()
    self:Server_TeleportToActor(Enum.Enum_AreaType.Office, OfficeConst.OfficeTeleportPointActorID)
    self:PostEnterOffice()
end

function TeleportComponent:Server_WalkIntoOffice_RPC()
    self:TeleportTo(OfficeConst.OfficeWalkInLocation, OfficeConst.OfficeWalkInRotation, false, nil)
    self:PostEnterOffice()
end

function TeleportComponent:PostEnterOffice()
    -- 切换角色形象到主角
    self.actor.PlayerState:GetPlayerController():SendMessage("SwitchToMainPlayer")
    local OccupyNpcActorID = self.actor.PlayerState.OfficeComponent.OccupyNpcActorID
    if OccupyNpcActorID ~= "" then
        local NpcActor = SubsystemUtils.GetMutableActorSubSystem(self):GetActor(OccupyNpcActorID)
        if NpcActor then
            local Sequence = NpcActor.NpcMissionComponent.OfficeSequence
            if Sequence then
                local Setting = UE.FMovieSceneSequencePlaybackSettings()
                self.actor:GetController().BP_MissionComponent:PlaySequencer(Sequence, Setting)
            end
        end
    end
end


function TeleportComponent:Server_WalkOutOfOffice_RPC()
    self:TeleportTo(OfficeConst.OfficeWalkOutLocation, OfficeConst.OfficeWalkOutRotation, false, nil)
    local OldAreaType = self.actor.PlayerState.AreaType
    self.actor.PlayerState.AreaType = Enum.Enum_AreaType.MainWorld
    if OldAreaType == Enum.Enum_AreaType.Office then
        self.actor.PlayerState:GetPlayerController():SendMessage("SwitchBackFromMainPlayer")
    end
end


function TeleportComponent:CanEnterArea(TargetAreaType)
    return true
end

function TeleportComponent:PreEnterArea(TargetAreaType)
    -- TODO: 进入Area前的处理, 去除脱战状态, 任务失败等
end

function TeleportComponent:PostEnterArea(TargetAreaType)
    local OldAreaType = self.actor.PlayerState.AreaType
    self.actor.PlayerState.AreaType = TargetAreaType
    if OldAreaType ~= TargetAreaType and OldAreaType == Enum.Enum_AreaType.Office then
        -- 离开事务所
        self.actor.PlayerState.OfficeComponent:TryNextEnterOffice()
    end
end

function TeleportComponent:GetActorLocationData(TargetActorID)
    local CurLevelName = UE.UGameplayStatics.GetCurrentLevelName(self.actor:GetWorld())
    local MapData = DataManager:GetMiniMapData(CurLevelName)
    if not MapData then
        G.log:warn("[GetActorLocationData]", "Can't find MapData, CurLevelName=%s", CurLevelName)
        return nil
    end

    local ActorData = MapData[TargetActorID]
    if not ActorData then
        G.log:warn("[GetActorLocationData]", "Can't find ActorData, CurLevelName=%s, TargetActorID=%s", CurLevelName, TargetActorID)
        return nil
    end

    local MapLegendId = tonumber(ActorData.Legend_ID)
    local LegendData = MapLegendData[MapLegendId]
    if not LegendData then
        G.log:warn("[GetActorLocationData]", "Can't find LegendData, MapLegendId=%s", MapLegendId)
        return nil
    end
    if LegendData.ExtraActionType ~= MapLegendTable.Teleport and LegendData.ExtraActionType ~= MapLegendTable.TeleportNearby then
        G.log:warn("[GetActorLocationData]", "Can't Teleport, CurLevelName=%s, TargetActorID=%s, ActionType=%s", CurLevelName, TargetActorID, LegendData.ExtraActionType)
        return nil
    end

    local Pos = ActorData.Legend_Positon
    return UE.FVector(Pos.x, Pos.y, Pos.z)
end

-- server 同区域内传送
function TeleportComponent:TeleportToActorWithinArea(TargetActorID)
    local ActorLocationData = self:GetActorLocationData(TargetActorID)
    if not ActorLocationData then
        G.log:warn("TeleportComponent", "Can't get actor location data, ActorID:%s", TargetActorID)
        return
    end
    local OldPlayerPosition = self.actor:K2_GetActorLocation()
    local Ret = self:TeleportTo(ActorLocationData, DefaultRotation, false, nil)
    G.log:debug("TeleportComponent", "TeleportToActorWithinArea, ret=%s, from=%s, to=%s", Ret, OldPlayerPosition, ActorLocationData)
    
    local bIsNearbyTeleport = false
    local TeleportDistance = UE.UKismetMathLibrary.Vector_Distance(OldPlayerPosition, ActorLocationData) / 100
    if TeleportDistance < GameConstData.NEARBY_TELEPORT_DISTANCE.FloatValue then
        bIsNearbyTeleport = true
    end
    self:Client_TeleportWithinArea(bIsNearbyTeleport)
end

-- 跨区域传送
function TeleportComponent:TeleportToActorAcrossArea(TargetAreaType, TargetActorID)
    if not self:CanEnterArea(TargetAreaType) then
        return false
    end
    local ActorLocationData = self:GetActorLocationData(TargetActorID)
    if not ActorLocationData then
        G.log:warn("hangyuewang", "Can't get actor location data, ActorID:%s", TargetActorID)
        return
    end
    self:PreEnterArea(TargetAreaType)
    self:TeleportTo(ActorLocationData, DefaultRotation, false, nil)
    self:PostEnterArea(TargetAreaType)
end

function TeleportComponent:ClientPreTeleport()
    self.actor.GlideComponent:StopGlide()
end

-- client
function TeleportComponent:RequestTeleportToActor(TargetAreaType, TargetActorID)
    self:ClientPreTeleport()
    self:Server_TeleportToActor(TargetAreaType, TargetActorID)
end

function TeleportComponent:Server_TeleportToActor_RPC(TargetAreaType, TargetActorID)
    -- TODO(hangyuewang): 目前只支持在同个Level内传送
    G.log:debug("TeleportComponent", "Server_TeleportToActor TargetAreaType=%s, TargetActorID=%s", TargetAreaType, TargetActorID)
    local OldAreaType = self.actor.PlayerState.AreaType
    if OldAreaType == TargetAreaType then
        -- 在同个Area内传送
        self:TeleportToActorWithinArea(TargetActorID)
    else
        -- 在不同Area之间传送
        self:TeleportToActorAcrossArea(TargetAreaType, TargetActorID)
    end
end

function TeleportComponent:Client_TeleportWithinArea_RPC(bIsNearbyTeleport)
    if not bIsNearbyTeleport then
        UIManager:OpenUI(UIDef.UIInfo.UI_FirmLoading, 1)
    end
    UIManager:CloseUIByName(UIDef.UIInfo.UI_FirmMap.UIName)
end

return TeleportComponent
