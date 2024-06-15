--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local Actor = require("common.actor")

local SubsystemUtils = require("common.utils.subsystem_utils")
local utils = require("common.utils")
local EdUtils = require("common.utils.ed_utils")
local BPConst = require("common.const.blueprint_const")
local GlobalActorConst = require("common.const.global_actor_const")
local MSConfig = require("micro_service.ms_config")
local OfficeEnums = require("office.OfficeEnums")

---@class OfficeManager
---@field OfficeWorldOwnerGuid string
local OfficeManager = Class(Actor)

OfficeManager.EntityServiceName = "HiGame.Office.DSOfficeEntity"

-- MutableActor oneof Actor 中的字段名
OfficeManager.EntityPropertyMessageName = "OfficeManager"

function OfficeManager:UserConstructionScript()
    --装修组件
    self.DecorationHandlerComp = nil
end

function OfficeManager:ReceiveBeginPlay()
    Super(OfficeManager).ReceiveBeginPlay(self)
    local bIsServer = UE.UHiUtilsFunctionLibrary.IsServer(self)
    G.log:info("yongzyzhang", "OfficeManager ReceiveBeginPlay bIsServer:%s", tostring(bIsServer))
    
    local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(self)
    if OfficeSubsystem then
        OfficeSubsystem:OnOfficeWorldReady()
    end
end

function OfficeManager:ReceiveEndPlay()
    Super(OfficeManager).ReceiveEndPlay(self)
end

--GlobalActor 接口
function OfficeManager:GetGlobalName()
    return GlobalActorConst.OfficeManager
end


function OfficeManager:OnGetOwnerPlayerController(PlayerController)
    self:SetOwner(PlayerController)
    self.OwnerPlayerController = PlayerController
end


function OfficeManager:IsOwner(PlayerController)
    if UE.UKismetSystemLibrary.IsServer(self) then
        return PlayerController == self:GetOwner()
    else
        -- TODO 判断gid
        return PlayerController:GetPlayerRoleId() == self.OfficeGid
        -- UE.UGameplayStatics.GetPlayerController(self, 0)
    end
end

---@type BP_ItemManager
function OfficeManager:GetPlayerItemManager()
    return self:GetOwner():GetItemManager()
end

---@return OfficeDecorateHandler
function OfficeManager:GetDecorationHandlerComp()
    return self.DecorationHandlerComp
end

function OfficeManager:GetActorDecorationInfo(ActorID, bCreateCopy)
    return self:GetDecorationHandlerComp():GetActorDecorationInfo(ActorID, bCreateCopy)    
end

---@param DecorationInfo FOfficeDecorationActorInfo
function OfficeManager:SpawnDecorationActor(DecorationInfo)
    local SpawnParameters = UE.FActorSpawnParameters()
    SpawnParameters.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
    if not self.SpawnIndex then
        self.SpawnIndex = 1
    end
    SpawnParameters.Name = DecorationInfo.ActorID .. "_SpawnIndex_" .. tostring(self.SpawnIndex)
    self.SpawnIndex = self.SpawnIndex + 1
    
    local ExtraSpawnOp = function(Actor)
        
    end
    local Transform = UE.FTransform.Identity
    if DecorationInfo.Transform ~= nil then
        Transform = DecorationInfo.Transform
    end
    ---@type OfficeSubsystem
    local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(self)

    local SkinDTConfig = nil
    local ActorBPClassName = nil
    if DecorationInfo.SkinKey and DecorationInfo.SkinKey ~= "" then
        SkinDTConfig = OfficeSubsystem:GetOfficeDataTableRow(DecorationInfo.SkinKey)
        ActorBPClassName = SkinDTConfig and SkinDTConfig.BP
    else
        SkinDTConfig = OfficeSubsystem:GetOfficeDataTableRow(DecorationInfo.BasicModelKey)
        ActorBPClassName = SkinDTConfig and SkinDTConfig.BP
    end
    if ActorBPClassName then
        ActorBPClassName = tostring(ActorBPClassName) .. "_C"
        local ActorBPClass = UE.UClass.Load(ActorBPClassName)
        if ActorBPClass then
            G.log:info("yongzyzhang", "start to SpawnDecorationActor ActorBPClass:%s DecorationInfo.ActorID:%s", ActorBPClassName, DecorationInfo.ActorID)
            local ExtraData = {}
            local DecorationActor = GameAPI.SpawnActor(self:GetWorld(), ActorBPClass, Transform, SpawnParameters, ExtraData, ExtraSpawnOp)
            --if self.OfficeDecorationCompClass == nil then
            --    self.OfficeDecorationCompClass = UE.UClass.Load("/Game/Blueprints/Office/BP_OfficeDecorationComponent.BP_OfficeDecorationComponent_C")
            --end
            OfficeSubsystem.ClientActorDecoratedEventDispatcher:Broadcast(DecorationInfo.ActorID, DecorationInfo, {})
            return
        end
    end
    G.log:error("yongzyzhang", "failed to SpawnDecorationActor, DecorationInfo:%s \n SkinDTConfig:%s", DecorationInfo:ExportText(), utils.TableToString(SkinDTConfig))

end

function OfficeManager:DestroyAndRespawnNewModelActor(DecorationActor, DecorationInfo, EventParam)
    DecorationActor:K2_DestroyActor()
    
    --首次同步或者重置，不需要播放动效和延迟
    local NotPlayAnimation = EventParam.bFirstSync or EventParam.bReset
    if NotPlayAnimation then
        self:SpawnDecorationActor(DecorationInfo)
    else
        -- 延迟1秒生成
        -- TODO 播放动效
        --utils.DoDelay(self, 1, function()
        --    self:SpawnDecorationActor(DecorationInfo)
        --end)
        self:SpawnDecorationActor(DecorationInfo)

    end
end

--TODO 流程优化
function OfficeManager:EnterOffice(PlayerState)
    local PlayerController = PlayerState:GetPlayerController()
    --TODO check是否是事务所主人
    if self:GetOwner() == nil then
        self:SetOwner(PlayerController)
    end

    -- no tsf4g service 
    if UE.UHiUtilsFunctionLibrary.IsLocalAdapter() then
        return
    end
    if not UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        return
    end
    local PlayerRoleId = PlayerController:GetPlayerRoleId()
    --通知事务所微服务玩家进入成功
    local EnterOfficeNotifyRequest = {
        PlayerRoleId = PlayerRoleId,
        PlayerMailbox = PlayerState:GetMailbox()
    }
    utils.Resume(function()
        if self.GenericOfficeInvoker == nil then
            self:Coro_GetOwnerOfficeInfo()
        end
        if self.GenericOfficeInvoker then
            local Context, Response = self.GenericOfficeInvoker:Coro_EnterOffice(EnterOfficeNotifyRequest)
            local Status = Context:GetStatus()
            if not Status:OK() then
                G.log:error("yongzyzhang", "AvatarGid:%s enter office failed, frame code:%s return code:%s error msg", PlayerRoleId,  Status:GetFrameworkRetCode(), Status:GetFuncRetCode(), Status:ErrorMessage())
                return
            end
            G.log:info("yongzyzhang", "enter office succeed, AvatarGid: %s", PlayerRoleId)
        end
    end)
end

function OfficeManager:LeaveOffice(PlayerRoleId)
    --通知事务所微服务玩家退出
    local Request = {
        PlayerRoleId = PlayerRoleId
    }
    if self.GenericOfficeInvoker then
        self.GenericOfficeInvoker:LeaveOffice(Request)
    end
end

-- 获取事务所Owner玩家的Guid
function OfficeManager:GetOwnerPlayerRoleId()
    if self:GetOwner() then
        return self:GetOwner():GetPlayerRoleId()
    end
    return 1
end

function OfficeManager:GetOfficeRPCStub()
    local RPCStubFactory = require("micro_service.rpc_stub_factory")
    local OfficeRPCStub = RPCStubFactory:GetRPCStub(MSConfig.OfficeRPCServiceName)
    return OfficeRPCStub
end

-- 需在协程中执行
--TODO 按理说这个Office信息，在OfficeWorld创建好后就已知了
function OfficeManager:Coro_GetOwnerOfficeInfo()
    local PlayerRoleId = self:GetOwnerPlayerRoleId()
    G.log:info("yongzyzhang", "OfficeManager AsyncGetOwnerOfficeInfo PlayerRoleId:%s", PlayerRoleId)

    local OfficeRPCStub = self:GetOfficeRPCStub()

    local GetPlayerOfficeRequest = {
        PlayerRoleId = PlayerRoleId
    }
    
    local ClientContext, Response = OfficeRPCStub:Coro_GetPlayerOffice(GetPlayerOfficeRequest)
    local ClientStatus = ClientContext:GetStatus()

    if not ClientStatus:OK() then
        G.log:error("yongzyzhang", "OfficeManager Coro_GetPlayerOffice fail1, frame: %d, func: %d, msg: %s",
                ClientStatus:GetFrameworkRetCode(), ClientStatus:GetFuncRetCode(), ClientStatus:ErrorMessage())
        return
    end
    
    self.OfficeGid = Response.OfficeGid
    G.log:info("yongzyzhang", "OfficeManager Coro_GetPlayerOffice succ OfficeGid: " .. Response.OfficeGid)

    local RemoteMetaInvoker = require("micro_service.RemoteMetaInvoker")
    self.GenericOfficeInvoker = RemoteMetaInvoker.CreateGenericInvoker(MSConfig.MSOfficeEntityMetaName, Response.OfficeGid)
end



return OfficeManager