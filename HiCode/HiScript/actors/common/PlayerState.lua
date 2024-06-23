---@class BP_PlayerState : AHiPlayerState
---@field public DefaultSceneRoot USceneComponent
---
---
---

require "UnLua"
local G = require("G")
local SubsystemUtils = require("common.utils.subsystem_utils")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')
local Actor = require("common.actor")
local BPConst = require("common.const.blueprint_const")
local TeamCharacterSaveData = require('actors.common.CharacterSaveData')
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")

---@class PlayerState
local PlayerState = Class(Actor)
PlayerState.EntityServiceName = "HiGame.PlayerStateInterface"
PlayerState.EntityPropertyMessageName = "PlayerState"

function PlayerState:UserConstructionScript()
    if UE.UKismetSystemLibrary.IsDedicatedServer(self) or UE.UKismetSystemLibrary.IsStandalone(self) then
        local AttributeSetClasses = self.AttributeComponent.AttributeSetClasses
        for Ind = 1, AttributeSetClasses:Length() do
            local CurAttributeSet = NewObject(AttributeSetClasses:Get(Ind), self)
            G.log:debug("PlayerState", "Add attribute set: %s", G.GetObjectName(CurAttributeSet))
            self:AddAttributeSet(CurAttributeSet)
        end
    end
end

function PlayerState:K2_PreInitializeComponents()
    if UE.UKismetSystemLibrary.IsDedicatedServer(self) then
        local ActorID = self:GenerateActorID()
        local GameplayEntitySubsystem = SubsystemUtils.GetGameplayEntitySubsystem(self)
        local PropertyMessage = GameplayEntitySubsystem:CreateMessage("HiGame.MutableActor")
        PropertyMessage.ActorID = ActorID
        PropertyMessage.ActorTypeID = 0
        PropertyMessage.CreateType = UE.EActorCreateType.ActorCreateType_Player
        PropertyMessage.Tags:Add("HiGamePlayer")
        G.log:debug("xaelpeng", "PlayerState:K2_PreInitializeComponents ActorID: %s", ActorID)
        SubsystemUtils.GetMutableActorSubSystem(self):AddMutableActorComponentToPlayer(self, ActorID, PropertyMessage) -- ActorTypeID, UE.EHiActorCreateType.ActorCreateType_Player, "HiGamePlayer", nil)
    end
end

function PlayerState:ReceiveBeginPlay()
    local PlayerController = self:GetPlayerController()
    if PlayerController then
        self.PlayerGuid = self:GetPlayerController():GetPlayerGuid()
    end

    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.PostBeginPlay}, 0.01, false)
    -- if UE.UKismetSystemLibrary.IsDedicatedServer(self) then
    --     local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    --     local MutableComponent = self:GetComponentByClass(MutableActorComponentClass)
    --     local Entity = MutableComponent:GetEntity()
    --     local ProxyMailbox = Entity:GetProxyMailbox()
    --     ProxyMailbox:OnAvatarCreated({
    --         AvatarMailbox=Entity:GetMailbox():GetMessage()
    --     })
    -- end

    --读取角色数据TODO 后续做成延迟加载 Client
    if(self.TeamSaveData == nil) then
        self.TeamSaveData = {}
        self:ReadCharacersData()
    end
end

function PlayerState:ReceiveEndPlay()
    self:UnregisterEntityMeta()
end

function PlayerState:GetMailbox()
     if UE.UKismetSystemLibrary.IsDedicatedServer(self) then
         local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
         local MutableComponent = self:GetComponentByClass(MutableActorComponentClass)
         local Entity = MutableComponent:GetEntity()
         return Entity:GetMailbox():GetMessage():SaveToTable()
     end
end

function PlayerState:GetPlayerGuidAsString()
    local PlayerController = self:GetPlayerController()
    if PlayerController then
        return PlayerController:GetPlayerGuidAsString()
    else
        return ""
    end
end


function PlayerState:GetPlayerRoleId()
    local PlayerController = self:GetPlayerController()
    if PlayerController then
        return PlayerController:GetPlayerRoleId()
    else
        return 0
    end
end


function PlayerState:GetPlayerRoleIdAsString()
    local PlayerController = self:GetPlayerController()
    if PlayerController then
        return PlayerController:GetPlayerRoleIdAsString()
    else
        return ""
    end
end

function PlayerState:GetRemoteMetaInvoker(MetaType, MetaUID)
    local PlayerController = self:GetPlayerController()
    if PlayerController then
        return PlayerController:GetRemoteMetaInvoker(MetaType, MetaUID)
    else
        local RemoteMetaInvoker = require("micro_service.RemoteMetaInvoker")
        return RemoteMetaInvoker.CreateGenericInvoker(MetaType, MetaUID)
    end
end

function PlayerState:GetPlayerGuid()
    return self.PlayerGuid
end

function PlayerState:ReceiveTick(DeltaSeconds)
    if self:HasAuthority() then
        local NowTime = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
        local PlayerController = self:GetPlayerController()
        if PlayerController == nil then
            return
        end
        local Pawn = PlayerController:K2_GetPawn()
        local Distance = UE.UKismetMathLibrary.Vector_Distance(self:K2_GetActorLocation(), Pawn:K2_GetActorLocation())
        if Distance >= 100 or not self.LastUpdateLocationTime or NowTime - self.LastUpdateLocationTime >= 1 then
            -- G.log:debug("yj", "PlayerState:ReceiveTick Location.%s PawnLocation.%s", self:K2_GetActorLocation(), Pawn:K2_GetActorLocation())
            self.LastUpdateLocationTime = NowTime
            self:K2_SetActorLocation(Pawn:K2_GetActorLocation(), true, nil, false)
        end
    end
end

function PlayerState:PostBeginPlay()
    if self:IsClient() then
        if self:GetPlayerController() == UE.UGameplayStatics.GetPlayerController(self, 0) then
            -- 本地玩家的PlayerState
            UIManager.UINotifier:UINotify(UIEventDef.LoadPlayerState)
        end
    end
    self:RegisterEntityMeta()
    self:SendMessage("PostBeginPlay")
end

function PlayerState:RegisterEntityMeta()
    if not self:IsServerAuthority() then
        return
    end
    -- no tsf4g service
    if UE.UHiUtilsFunctionLibrary.IsLocalAdapter() then
        return
    end
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local MutableComponent = self:GetComponentByClass(MutableActorComponentClass)
    local Entity = MutableComponent:GetEntity()
    if Entity == nil then
        return
    end
    local MailboxTable = Entity:GetMailbox():GetTable()
    local RpcClientStubFactory = require("micro_service.rpc_stub_factory")
    local MsConfig = require("micro_service.ms_config")

    local AgentRPCStub = RpcClientStubFactory:GetRPCStub(MsConfig.AgentRPCServiceName)
    xpcall(function()
        AgentRPCStub:OnDSEntityLoad({
            MetaType = PlayerState.EntityServiceName,
            MetaUID = self:GetPlayerRoleId(),
            Mailbox = MailboxTable
        })
    end, function (errobj)
            if errobj then
                G.log:error("yongzyzhang" ,"OnDSEntityLoad:" .. errobj .. debug.traceback())
            else
                G.log:error("yongzyzhang", "OnDSEntityLoad:" .. debug.traceback())
            end
        end
    )
end

function PlayerState:UnregisterEntityMeta()
    if not self:IsServerAuthority() then
        return
    end
    -- no tsf4g service
    if UE.UHiUtilsFunctionLibrary.IsLocalAdapter() then
        return
    end
    local RpcClientStubFactory = require("micro_service.rpc_stub_factory")
    local MsConfig = require("micro_service.ms_config")

    local AgentRPCStub = RpcClientStubFactory:GetRPCStub(MsConfig.AgentRPCServiceName)
    xpcall(function()
        AgentRPCStub:OnDSEntityUnLoad({
            MetaType = PlayerState.EntityServiceName,
            MetaUID = 1
        })
    end,function (errobj)
            if errobj then
                G.log:error("yongzyzhang" ,"OnDSEntityUnLoad:" .. errobj .. debug.traceback())
            else
                G.log:error("yongzyzhang", "OnDSEntityUnLoad:" .. errobj .. debug.traceback())
            end
        end
    )

end

-- function PlayerState:DestroyByProxy(Context, Request)
--     G.log:debug("xaelpeng", "PlayerState:DestroyByProxy Mailbox: %s", Request.ProxyMailbox:DebugString())
--     local GameplayEntitySubsystem = SubsystemUtils.GetGameplayEntitySubsystem(self)
--     local Mailbox = GameplayEntitySubsystem:CreateMailbox(Request.ProxyMailbox)
--     Mailbox:OnAvatarDestroyed()
--     return {}
-- end

function PlayerState:OnPawnSetCallback(PlayerState, NewPawn, OldPawn)
    self.AttributeComponent:OnPawnSet(PlayerState, NewPawn, OldPawn)
end

function PlayerState:OnRep_AreaType()
    self.OnAreaTypeChange:Broadcast(self.AreaType)
end

function PlayerState:OnRep_AttributeSets()
end

---Server
function PlayerState:Pay(Context, PlayerPaymentRequest)
    G.log:error("yongzyzhang", "PlayerState Pay request id:%s", tostring(Context:GetRequestId()))
    if not UE.UKismetSystemLibrary.IsServer(self) then
        return
    end

    if self.OrderRecord == nil then
        self.OrderRecord = {}
    end
    --TODO 订单幂等处理
    local OrderNumber = PlayerPaymentRequest.OrderNumber
    local Response = {}
    if self.OrderRecord[OrderNumber] then
        G.log:error("yongzyzhang", "PlayerState Pay for repeated order:%s", OrderNumber)
        Context:SetStatus(-1, "replated order number")
        return Response
    end
    self.OrderRecord[OrderNumber] = true

    ---@type BP_ItemManager
    local ItemManager = self.ItemManager

    local ItemUtil = require("common.item.ItemUtil")

    local CostTable = {}
    for _, PayItemInfo in ipairs(PlayerPaymentRequest.PayItem) do
        if ItemUtil.GetItemConfigByExcelID(PayItemInfo.ItemID) == nil then
            Context:SetStatus(-1, string.format("Invalid ItemID:%s ",  tostring(PayItemInfo.ItemID)))
            return Response
        end
        if PayItemInfo.ItemNum < 0 then
            Context:SetStatus(-1, string.format("ItemID:%s cost num < 0 invalid",  tostring(PayItemInfo.ItemID)))
            return Response
        end
        if not ItemManager:IsItemEnough(PayItemInfo.ItemID, PayItemInfo.ItemNum) then
            --TODO Error Code
            Context:SetStatus(-1, string.format("ItemNot:%s Enough:",  tostring(PayItemInfo.ItemID)))
            return Response
        end
        if CostTable[PayItemInfo.ItemID] == nil then
            CostTable[PayItemInfo.ItemID] = PayItemInfo.ItemNum
        else
            CostTable[PayItemInfo.ItemID] = CostTable[PayItemInfo.ItemID] + PayItemInfo.ItemNum
        end
    end
    --扣道具
    ItemManager:ReduceItems(CostTable)
    return Response
end

---Server
function PlayerState:AddItems(ServerCtx, Request)
    G.log:error("yongzyzhang", "PlayerState Pay request id:%s", tostring(ServerCtx:GetRequestId()))
    if not UE.UKismetSystemLibrary.IsServer(self) then
        return
    end

    if self.AddItemsRecord == nil then
        self.AddItemsRecord = {}
    end
    --TODO 幂等处理
    local UniqNumber = Request.UniqNumber
    local Response = {}
    if self.AddItemsRecord[UniqNumber] then
        G.log:error("yongzyzhang", "PlayerState AddItems for repeated request:%s", UniqNumber)
        ServerCtx:SetStatus(-1, "replated additem request")
        return Response
    end
    self.AddItemsRecord[UniqNumber] = true

    ---@type BP_ItemManager
    local ItemManager = self.ItemManager
    local ItemUtil = require("common.item.ItemUtil")

    local AddItemTable = {}
    for ItemID, ItemNum in pairs(Request.Items) do
        if ItemUtil.GetItemConfigByExcelID(ItemID) == nil then
            ServerCtx:SetStatus(-1, string.format("Invalid ItemID:%s ",  tostring(ItemID)))
            return Response
        end
        if ItemNum < 0 then
            ServerCtx:SetStatus(-1, string.format("ItemID:%s num < 0 invalid",  tostring(ItemNum)))
            return Response
        end
    end
    --加道具
    ItemManager:AddItems(Request.Items)
    return Response
end

function PlayerState:MissionComplete(eMiniGame, sData)
    local json = require("thirdparty.json")
    local Param = {
        eMiniGame=eMiniGame,
        sData=sData
    }
    local Data=json.encode(Param)
    self.Event_MissionComplete:Broadcast(Data)
end

--TeamSaveData  Server
function PlayerState:GetCharactersSaveData()
    return self.TeamSaveData
end

-- Init
function PlayerState:ReadCharacersData()
    --测试数据
    -- self.TeamSaveData =
    -- {
    --     [9999] =
    --     {
    --         LearnedSkills =
    --         {
    --             [999] = 1,
    --         } ,
    --         PendingUnlockSkills =
    --         {
    --             9999,
    --         }
    --     }
    -- }
   -- self.CharacterSaveDataComponent.ReadCharacersData(self.TeamSaveData)
end

-- PendingSkillMark
function PlayerState:AddPendingUnlockSkill(CharacterType, SkillID)
    self.CharacterSaveDataComponent:AddPendingUnlockSkill(self.TeamSaveData, CharacterType, SkillID)
end

-- record Learned Skill
function PlayerState:ReceiveCharacterLearnSkill(CharType, SkillID)
    self.CharacterSaveDataComponent:AddLearnedSkill(self.TeamSaveData, CharType, SkillID)
end

-- Get SkillComponent
function PlayerState:GetSkillComponent(CharacterType)
    local  OwnerController = self:GetPlayerController()
    if OwnerController == nil then
        G.log:error("GetSkillComponent", "GetSkillComponent OwnerController is nil")
        return
    end

    local TargetChar = OwnerController:GetCharacterByCharType(CharacterType)
    if TargetChar == nil then
        G.log:error("GetSkillComponent", "GetSkillComponent TargetChar is nil")
        return
    end

    local SkillComp = TargetChar:_GetComponent('SkillComponent', true)
    if SkillComp == nil then
        G.log:error("GetSkillComponent", "GetSkillComponent SkillComp is nil")
        return
    end

    return  SkillComp
end

-- Character LevelUp
function PlayerState:ReceiveCharacterLevelUP(CharacterType, NewLevel)
    self.CharacterSaveDataComponent:ChangeCharacterLevel(self.TeamSaveData, CharacterType, NewLevel)

    local SkillComp = self:GetSkillComponent()
    if SkillComp == nil then
        return
    end

    --遍历记录的待解锁
    for _, SkillID in pairs(self.SaveData[CharacterType].PendingUnlockSkills) do
        if SkillComp:CheckSkillUnlockLevel(SkillID) then
            SkillComp:LearnSkill(SkillID)
        end
    end

end

-- SkillLevelUp
function PlayerState:ReceiveCharacterSkillLevelUp(CharacterType, SkillID, NewLevel)
    self.CharacterSaveDataComponent:CharacterSkillLevelUp(self.TeamSaveData, CharacterType, SkillID, NewLevel)

    local SkillComp = self:GetSkillComponent(CharacterType)
    if SkillComp == nil then
        return
    end

    SkillComp:SetSkillLevel(SkillID, NewLevel)
end

--function PlayerState:TestChangeLevel(CharID, SkillID, SkillLV)
--    self:ReceiveCharacterSkillLevelUp(CharID, SkillID, SkillLV)
--end

function PlayerState:K2_OnTransferToSpace(InSpaceID)
    G.log:info("xaelpeng", "OnTransferToSpace %s", InSpaceID)
    TipsUtil.ShowCommonTips(string.format("enter space %s", InSpaceID))
end

function PlayerState:GetSaveStrategy()
    return UE.EActorSaveStrategy.Strategy_SaveOnPeriodAndDestroy
end

return PlayerState
