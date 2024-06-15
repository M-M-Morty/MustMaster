--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
local G = require("G")
local GlobalActorConst = require("common.const.global_actor_const")
local EventDispatcher = require("common.event_dispatcher")
local OfficeModelTable = require("common.data.office_model").data
local MSConfig = require("micro_service.ms_config")
local ItemUtil = require("common.item.ItemUtil")

local ItemEffectUtils = require("common.utils.item_effect_utils")
local ItemData = require("common.data.item_base_data")
local OfficeFurnitureUseType = require("common.data.item_base_data").Office_Furniture

---@param User PlayerState
local function OnAutoUseOfficeExpItem(User, _, _, ExtraData)
    local RPCStubFactory = require("micro_service.rpc_stub_factory")
    local IRPCCore = require("irpc_core")
    local OfficeRPCStub = RPCStubFactory:GetRPCStub(MSConfig.OfficeRPCServiceName)
    local ClientContext = IRPCCore:NewClientContext()
    local roleId = User:GetPlayerRoleId()
    --ClientContext:AddReqMeta("role_id", )
    local Ok = OfficeRPCStub:AddPlayerOfficeExp(ClientContext, {ExpVal = ExtraData.ItemNum, PlayerRoleId = roleId})
    if not Ok then
        G.log:info("yongzyzhang", "OnAutoUseOfficeExpItem AddPlayerOfficeExp Send req failed")
    end
    return OfficeRPCStub
end

---@param User PlayerState
local function OnUseOfficeFurnitureItem(User, _, UseParam, ExtraData)
    local SkinID = UseParam[1]
    local UserOfficeInvoker = User:GetRemoteMetaInvoker(MSConfig.MSOfficeEntityMetaName, User:GetPlayerRoleId())
    -- AlreadyPayed=true 微服务无须继续扣除皮肤费用
    UserOfficeInvoker:BuyModelSkin({SkinID = SkinID, Num = ExtraData.Num, AlreadyPayed=true})
end

ItemEffectUtils:RegisterItemEffect(ItemData.AddOfficeExp, OnAutoUseOfficeExpItem)
ItemEffectUtils:RegisterItemEffect(ItemData.Office_Furniture, OnUseOfficeFurnitureItem)

---@class OfficeSubsystem 
local OfficeSubsystem = UnLua.Class()

function OfficeSubsystem:PostInitializeScript()
    local bIsServer = UE.UHiUtilsFunctionLibrary.IsServer(self)
    G.log:info("yongzyzhang", "OfficeSubsystem PostInitializeScript isServer " .. tostring(bIsServer))

    --server
    if bIsServer then
        self.WaitForEnterPlayerList = {}
    else
        --已生成的可装饰物Actor
        ---@type table<string, boolean>
        self.ClientDecorationActorMap = {}

        self.ClientActorDecoratedEventDispatcher = EventDispatcher.new()
        self.ClientActorDecoratedEventDispatcher:Initialize()

    end
    
    self.OfficeDataTable = UE.UObject.Load("/Game/Data/Datatable/DT_Office_Model.DT_Office_Model")
    if self.OfficeDataTable == nil then
        G.log:error("yongzyzhang", "load DT_Office_Model failed")
    end

end

---only client
function OfficeSubsystem:OnOfficeDecorationActorBeginPlay(ActorID, DefaultDecorationInfo)
    self.ClientDecorationActorMap[ActorID] = DefaultDecorationInfo
    G.log:info("yongzyzhang", "OnOfficeDecorationActorBeginPlay ActorID:%s", tostring(ActorID))
end

---only client
function OfficeSubsystem:OnOfficeDecorationActorEndPlay(ActorID)
    self.ClientDecorationActorMap[ActorID] = false
    G.log:info("yongzyzhang", "OnOfficeDecorationActorEndPlay ActorID:%s", tostring(ActorID))
end

---only client
function OfficeSubsystem:IsOfficeDecorationActorValid(ActorID)
    return self.ClientDecorationActorMap[ActorID] ~= nil
end

---only client
function OfficeSubsystem:GetClientDecorationActorTable()
    return self.ClientDecorationActorMap
end

---目前只有Client会获取到数据(返回副本)
---only client
function OfficeSubsystem:GetActorDefaultDecorationInfo(ActorID)
    local DecorationInfo = Struct.BPS_OfficeDecorationInfo()
    DecorationInfo = self.ClientDecorationActorMap[ActorID]
    return DecorationInfo:Copy()
end

function OfficeSubsystem:OnPlayerEnterOffice(PlayerState)
    --local DungeonID = SubsystemUtils.GetGameplayEntitySubsystem(self):K2_GetDungeonID()
    --if DungeonID ~= self.OfficeMapID then
    --    G.log:info("yongzyzhang", "Current Map:%s is not Office", DungeonID)
    --    return
    --end
    local bIsServer = UE.UHiUtilsFunctionLibrary.IsServerWorld()
    if bIsServer then
        if not self.OfficeManager then
            self.OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
        end
        ---@type OfficeManager
        if self.OfficeManager then
            self.OfficeManager:EnterOffice(PlayerState)
        else
            table.insert(self.WaitForEnterPlayerList, PlayerState)
        end
    end
end

function OfficeSubsystem:OnPlayerLeaveOffice(PlayerRoleId)
    if self.OfficeManager then
        self.OfficeManager:LeaveOffice(PlayerRoleId)
    end
end

--server and client
---@param OfficeManager OfficeManager
function OfficeSubsystem:OnOfficeWorldReady(OfficeManager)
    self.OfficeManager = OfficeManager
    local bIsServer = UE.UHiUtilsFunctionLibrary.IsServerWorld()
    G.log:info("yongzyzhang", "OfficeSubsystem OnOfficeWorldReady bIsServer:%s", tostring(bIsServer))
    if bIsServer then
        for _, PlayerState in ipairs(self.WaitForEnterPlayerList) do
            self.OfficeManager:EnterOffice(PlayerState)
        end
    else
        local LocalPC = UE.UGameplayStatics.GetPlayerState(self, 0)
    end
end


-- args:
--- callback desc
---@param Struct.BPS_OfficeDecorationInfo
function OfficeSubsystem:RegisterClientActorDecoratedEvent(ActorID, Listener, Callback)
    local InnerCallback = function(ActorDecorationInfo, EventParam)
        xpcall(function()
            Callback(Listener, ActorDecorationInfo, EventParam)
        end, function(err)
            if err then
                G.log:error('yongzyzhang', "actor decoration failed err:%s traceback:%s", err, debug.traceback())
            end
        end)
    end
    local CallbackObj = {
        identity = Callback,
        callback = InnerCallback,
    }

    self.ClientActorDecoratedEventDispatcher:AddListener(ActorID, Listener, CallbackObj)
end

function OfficeSubsystem:UnRegisterClientActorDecoratedEvent(ActorID, Listener, Callback)
    self.ClientActorDecoratedEventDispatcher:RemoveListener(ActorID, Listener, Callback)
end

function OfficeSubsystem:GetDecorationTagName()
    return self.DecorationTagName
end

function OfficeSubsystem:GetBaseDecorationActorClass()
    if self.BaseDecorationActorClass == nil then
        local Path = '/Game/Blueprints/Office/BPA_BaseDecorationActor.BPA_BaseDecorationActor_C'
        self.BaseDecorationActorClass = UE.UObject.Load(Path)
        UE.UHiUtilsFunctionLibrary.AddBlueprintTypeToCache(Path, self.BaseDecorationActorClass)
    end
    return self.BaseDecorationActorClass
end

function OfficeSubsystem:GetOfficeDataTableRow(RowName)
    if self.OfficeDataTable == nil then
        return nil
    end
    local RowData = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.OfficeDataTable, RowName)
    return RowData
end

function OfficeSubsystem:GetOfficeDataTableRowNames()
    if self.OfficeDataTable == nil then
        return nil
    end
    local OutRowNames = UE.UDataTableFunctionLibrary.GetDataTableRowNames(self.OfficeDataTable)
    return OutRowNames
end

---@param ModelOrSkinID string
function OfficeSubsystem:GetOfficeModelConfig(ModelOrSkinID)
    for _, BaseModel in pairs(OfficeModelTable) do
        for _, Config in pairs(BaseModel) do
            if Config.Index == ModelOrSkinID then
                return Config
            end
        end
    end
end

--- 获取SkinID所属的BasicModelID
---@param SkinID string
function OfficeSubsystem:GetBasicModelIDBySkinID(SkinID)
    for BaseModelID, BaseModel in pairs(OfficeModelTable) do
        for _, Config in pairs(BaseModel) do
            if Config.Index == SkinID and Config.IsBasicMesh == false then
                return BaseModelID
            end
        end
    end
    return nil
end


--- 获取SkinID的配置
---@param SkinID string
function OfficeSubsystem:GetSkinConfig(SkinID)
    for _, BaseModel in pairs(OfficeModelTable) do
        for _, Config in pairs(BaseModel) do
            if Config.Index == SkinID and Config.IsBasicMesh == false then
                return Config
            end
        end
    end
end

function OfficeSubsystem:LoadOfficeProto(bForce)
    if self.OfficeProtoLoaded and not bForce then
        return
    end
    local FileName = "Entities/OfficeService/Office.proto"
    local PROTOC = require("micro_service.ProtocInstance")
    PROTOC:loadfile(FileName)
    G.log:info("yongzyzhang", "OfficeSubsystem Load OfficeProto file:%s finished", FileName)
    self.OfficeProtoLoaded = true
end


function OfficeSubsystem:GetModelCompDefaultColors(ModelID)
    local SkinDTConfig = self:GetOfficeDataTableRow(ModelID)
    if SkinDTConfig == nil then
        return {}
    end
    local NewMaterialName = tostring(SkinDTConfig.Material)

    local MaterialDefaultColors = {}
    local MaterialInstance = UE.UObject.Load(NewMaterialName)
    
    --TODO 读取部件数
    for PartIndex = 1, 4 do
        local LinerColor = MaterialInstance:K2_GetVectorParameterValue("MaskedColor_" .. tostring(PartIndex))
        MaterialDefaultColors[PartIndex] = LinerColor:ToFColor(false)
        G.log:info("yongzyzhang","MaterialInstance part:%d default color:%s", PartIndex, tostring(MaterialDefaultColors[PartIndex]))
    end
    return MaterialDefaultColors
end


function OfficeSubsystem:GetFurnitureItemConfigBySkinID(SkinID)
    local Configs = ItemUtil.GetAllItemConfig()
    for ExcelID, Config in pairs(Configs) do
        if Config.item_use_type == OfficeFurnitureUseType and Config.item_use_details[1] == SkinID then
            return ExcelID, Config
        end
    end
end

---Callback

function OfficeSubsystem:RequestOfficeAsset(PlayerController, Callback)
    G.log:error("yongzyzhang", "RequestOfficeAsset")
    
    local SelfOfficeProxy = PlayerController:GetRemoteMetaInvoker(MSConfig.MSOfficeEntityMetaName, PlayerController:GetPlayerRoleId())

    utils.Resume(function()
        local Context, Response = SelfOfficeProxy:Coro_GetAllAsset({})
        local Status = Context:GetStatus()
        if not Status:OK() then
            G.log:error("yongzyzhang", "RequestOfficeAsset error msg:", utils.IRPCStatusString(Status))
        else
            G.log:info("yongzyzhang", "RequestOfficeAsset succeed")
        end
        if Callback then
            Callback(Status:OK(),  Response and Response.OfficeAsset or {})
        end
    end)
end

--client 发布自身装修方案到装修圈
function OfficeSubsystem:ReleaseDesignScheme(Desc, DesignActorDecorationInfos, Callback)
    local RPCClient = self:GetDesignShareServiceClient()
    
    local DesignActorDecorationInfoList = {}
    for _, DecorationInfo in pairs(DesignActorDecorationInfos:ToTable()) do
        local StructTable  = DecorationInfo:ToMessageTable("HiGame.Office.OfficeDecorationActorInfo")
        table.insert(DesignActorDecorationInfos, StructTable)
    end
    
    RPCClient:AddOnlineDesignScheme({
        Description = Desc,
        DesignActorDecorationInfos = DesignActorDecorationInfoList
    }, function(Context, Response)
        local Status = Context:GetStatus()
        if Status:OK() then
            G.log:info("yongzyzhang", "AddOnlineDesignScheme succeed")
        else
            G.log:info("yongzyzhang", "AddOnlineDesignScheme failed:%s", utils.IRPCStatusString(Status))
        end
        if Callback then
            Callback(Status:OK(), Response.SchemeGid)
        end
    end)
end

function OfficeSubsystem:GetDesignShareServiceClient()
    local RPCStubFactory = require("micro_service.rpc_stub_factory")
    local RPCClient = RPCStubFactory:GetRPCStub(MSConfig.OfficeDesignShareServiceName)
    return RPCClient
end

--client 删除装修圈上架的方案
function OfficeSubsystem:UnReleaseDesignScheme(SchemeGid, Callback)
    local RPCClient = self:GetDesignShareServiceClient()
    RPCClient:DelOnlineDesignScheme({
        SchemeGid = SchemeGid
    }, function(Context, Response)
        local Status = Context:GetStatus()
        if Status:OK() then
            G.log:info("yongzyzhang", "UnReleaseDesignScheme succeed")
        else
            G.log:info("yongzyzhang", "UnReleaseDesignScheme failed:%s", utils.IRPCStatusString(Context:GetStatus()))
        end
        if Callback then
            Callback(Status:OK())
        end
    end)
end

---@param Page number 页号从1开始
function OfficeSubsystem:GetOnlineDesignSchemesByPage(Callback, Page, PageSize, SortType)
    local Req = {
        SortType = SortType,
        Page = Page or 1,
        PageSize = PageSize or 20
    }
    local RPCClient = self:GetDesignShareServiceClient()
    RPCClient:GetOnlineDesignSchemes(Req, function(ClientCtx, Response) 
        local Status = ClientCtx:GetStatus()
        Callback(Status:OK(), Response)
    end)
end


return OfficeSubsystem
