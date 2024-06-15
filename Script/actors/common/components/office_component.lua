local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local BPConst = require("common.const.blueprint_const")
local EdUtils = require("common.utils.ed_utils")
local GameConstData = require("common.data.game_const_data").data
local SubsystemUtils = require("common.utils.subsystem_utils")
local MSConfig = require("micro_service.ms_config")
local GlobalActorConst = require("common.const.global_actor_const")

local OfficeComponent = Component(ComponentBase)
local decorator = OfficeComponent.decorator


---挂在PlayerState上
function OfficeComponent:Initialize(Initializer)
    Super(OfficeComponent).Initialize(self, Initializer)
    self.EnterOfficeTimer = nil -- server
end

function OfficeComponent:NpcEnterOffice(NpcActorID, MissionActID)
    if not self:CanEnterOffice() then
        -- 当前事务所被NPC占用, 或者还在进入CD中。NPC进入排队列表
        local WaitEnterOfficeInfoClass = EdUtils:GetUE5ObjectClass(BPConst.NpcWaitEnterOfficeInfo, true)
        local WaitEnterOfficeInfo = WaitEnterOfficeInfoClass()
        WaitEnterOfficeInfo.ActorID = NpcActorID
        WaitEnterOfficeInfo.MissionActID = MissionActID
        self.WaitEnterNpcList:Add(WaitEnterOfficeInfo)
        return false
    else
        self.OccupyNpcActorID = NpcActorID
        return true
    end
end

function OfficeComponent:NpcLeaveOffice(NpcActor)
    local NpcActorID = NpcActor:GetActorID()
    if NpcActorID ~= self.OccupyNpcActorID then
        G.log:error("[OfficeComponent:NpcLeaveOffice]", "Npc not in office, LeaveNpcID=%s, OccupyNpcID=%s", NpcActorID, self.OccupyNpcActorID)
        return
    end
    self.OccupyNpcActorID = ""
    if self.EnterOfficeTimer then
        G.log:error("[OfficeComponent:NpcLeaveOffice]", "EnterOfficeTimer is not nil")
        return
    end
    self.EnterOfficeTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnEnterOfficeTimerEnd}, 
        GameConstData.NPC_ENTER_OFFICE_CD.IntValue, false)
end

function OfficeComponent:CanEnterOffice()
    return self.OccupyNpcActorID == "" and self.EnterOfficeTimer == nil and self.actor.AreaType ~= Enum.Enum_AreaType.Office
end

function OfficeComponent:OnEnterOfficeTimerEnd()
    self.EnterOfficeTimer = nil
    self:TryNextEnterOffice()
end

function OfficeComponent:TryNextEnterOffice()
    if self.WaitEnterNpcList:Length() > 0 and self:CanEnterOffice() then
        -- 安排下一个npc进入事务所
        local WaitEnterOfficeInfo = self.WaitEnterNpcList:Get(1)
        self.WaitEnterNpcList:Remove(1)
        local NextNpc = SubsystemUtils.GetMutableActorSubSystem(self):GetActor(WaitEnterOfficeInfo.ActorID)
        if not NextNpc then
            return
        end
        NextNpc.NpcTeleportComponent:Server_TeleportToOffice()
        self.OccupyNpcActorID = WaitEnterOfficeInfo.ActorID
        self.OnNpcEnterOffice:Broadcast(WaitEnterOfficeInfo.ActorID, WaitEnterOfficeInfo.MissionActID)
    end
end


function OfficeComponent:ReceiveBeginPlay()
    Super(OfficeComponent).ReceiveBeginPlay(self)

    local bIsServer = UE.UHiUtilsFunctionLibrary.IsServer(self)
    if bIsServer then
        ---@type OfficeSubsystem
        local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(self:GetWorld())

        if OfficeSubsystem then
            OfficeSubsystem:OnPlayerEnterOffice(self:GetOwner())
        end
    end

    if not bIsServer then
        local IRPC = require("micro_service.irpc.irpc")
        local Protoc = require("micro_service.ProtocInstance")
        Protoc:loadfile("Services/OfficeService/office_client.proto")
        IRPC:BindRPCService("HiGame.Office.ClientOfficeService", self)
    end
end

function OfficeComponent:ReceiveEndPlay()
    Super(OfficeComponent).ReceiveEndPlay(self)
    local bIsServer = UE.UHiUtilsFunctionLibrary.IsServer(self)
    if bIsServer then
        local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(self:GetWorld())
        if OfficeSubsystem then
            OfficeSubsystem:OnPlayerLeaveOffice(self:GetOwner():GetPlayerController():GetPlayerRoleId())
        end
    end
end


-- client
function OfficeComponent:NotifyOfficeLevel(ServerContext, Request)
    G.log:info("yongzyzhang", "OfficeComponent,NotifyOfficeLevel exp:%d level:%d", Request.Exp, Request.Level)

    self.CurrentExp = Request.Exp
    self.CurrentLevel = Request.Level
    self.LevelRewardState = Request.LevelRewardState or {}
end

-- client
function OfficeComponent:NotifyOfficeAsset(ServerContext, Request)
    G.log:info("yongzyzhang", "OfficeComponent, NotifyOfficeAsset")

    self.OfficeAsset = Request.OfficeAsset
    self:OnSyncOfficeAsset()
end

-- client
function OfficeComponent:OnSyncOfficeAsset()
    if UE.UHiUtilsFunctionLibrary.IsClient(self) then
        ---@type OfficeManager
        local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
        if OfficeManager then
            OfficeManager:GetDecorationHandlerComp():ClientOnSyncOfficeAsset(self.OfficeAsset)
        end
    end
end

return OfficeComponent