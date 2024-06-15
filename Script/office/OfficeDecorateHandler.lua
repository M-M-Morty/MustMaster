local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local OfficeEnums = require("office.OfficeEnums")
local MSConfig = require("micro_service.ms_config")
local G = require("G")
local EventDispatcher = require("common.event_dispatcher")
local MsConfig = require("micro_service.ms_config")

---实现装修功能RPC逻辑的组件
---@class OfficeDecorateHandler
---@field SavedActorDecorationInfos TArray(Struct.BPS_OfficeDecorationInfo) Replicate&存盘 变量。Actor退出装修默认后依然存在的非试用装修数据
---@field TrialDecorationItems Struct.BPS_OfficeDecorationTrialItems Replicate&存盘 装修模式中的Actor试用项
---@field ClientActorDecorationInfoTable table<string, Struct.BPS_OfficeDecorationInfo> OnlyClient 装修模式中的Actor装修数据
---@field DesignSchemeSlots TArray<Struct.BPS_OfficeDesignSchemeSlot> 设计方案存储槽位
---@field SlotCapacity number 设计方案存储槽位容量
local OfficeDecorateHandler = Component(ComponentBase)

local EventNameDict = {
    ClientShopCarRefreshEventName = "UnPayedItemsUpdated",
    OperateErrorEvent = "OperateErrorEvent",
    DecorationSchemeUpdated = "DecorationSchemeUpdated",
    ReleaseDesignScheme = "ReleaseDesignScheme",
}

function OfficeDecorateHandler:ReceiveBeginPlay()
    Super(OfficeDecorateHandler).ReceiveBeginPlay(self)

    ---@type OfficeManager
    self.OfficeManager = self:GetOwner()
    self.OfficeManager.DecorationHandlerComp = self

    local bIsServer = UE.UHiUtilsFunctionLibrary.IsServer(self)

    self.__Waiting_RPC_Response = false
    if bIsServer then
        self.bInDecorationMode = false

        -- 试用项的数目，具体的试用项数据，仅需在装修模式下才需要同步给客户端
        self.TrialItemsNum = self.TrialDecorationItems.SkinTrialItems:Length() + self.TrialDecorationItems.ColorTrialItems:Length()
    else
        -- 装修操作修改的Actor标记脏，最后只需要把标脏的Actor，提交给服务器
        self.DirtyActors = {}
        
        --Client 通知已经BeginPlay的Actor换肤  还没有Beginplay的Actor会在自己BeginPlay后自己换肤
        self:FlushAllDecorationActors({bFirstSync = true})
        
        self.ClientEventDispatcher = EventDispatcher.new()
        self.ClientEventDispatcher:Initialize()
    end

    if self.SlotCapacity == 0 then
        --默认槽位值读取配置
        self.SlotCapacity = 5   
    end
end

function OfficeDecorateHandler:ReceiveEndPlay()
    Super(OfficeDecorateHandler).ReceiveEndPlay(self)
    self:ClearDecorateTimerHandler()
end

-- function OfficeDecorateHandler:ReceiveTick(DeltaSeconds)
-- end

---only client
function OfficeDecorateHandler:FlushAllDecorationActors(EventParams)
    self.ClientActorDecorationInfoTable = {}
    if self.SavedActorDecorationInfos then
        for _, SavedDecorationInfo in pairs(self.SavedActorDecorationInfos:ToTable()) do
            self.ClientActorDecorationInfoTable[SavedDecorationInfo.ActorID] = SavedDecorationInfo
        end
    end
    
    if self.bInDecorationMode then
        -- 从Actor试用的皮肤和染色项，恢复试用的完整装修换肤数据
        self:RestoreTrialDecorationInfo(self.TrialDecorationItems)
    end

    if not self.ClientActorDecorationInfoTable then
        return
    end
    
    G.log:info("yongzyzhang", "OfficeDecorateHandler:FirstSyncDecorationActors ActorInfo count:%d current mode:%s", 
            utils.dict_len(self.ClientActorDecorationInfoTable), self.bInDecorationMode and "DecorationMode" or "NormalMode")
    
    ---@type OfficeSubsystem
    local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(self)

    local NeedUpdatedActorInfos = {}
    local NeedSpawnActorInfos = {}
    local NeedDestroyActorInfos = {}

    for _, DecorationInfo in pairs(self.ClientActorDecorationInfoTable) do
        if OfficeSubsystem:IsOfficeDecorationActorValid(DecorationInfo.ActorID) then
            if DecorationInfo.bRemoved then
                table.insert(NeedDestroyActorInfos, DecorationInfo)
            else
                table.insert(NeedUpdatedActorInfos, DecorationInfo)
            end
        else
            if not DecorationInfo.bRemoved then
                table.insert(NeedSpawnActorInfos, DecorationInfo)
            end
        end
    end

    --销毁编辑器中存在的Actor
    if #NeedDestroyActorInfos ~= 0 then
        for _, DecorationInfo in ipairs(NeedDestroyActorInfos) do
            OfficeSubsystem.ClientActorDecoratedEventDispatcher:Broadcast(DecorationInfo.ActorID, DecorationInfo, EventParams)
        end
    end

    --更新已存在的Actor外观
    if #NeedUpdatedActorInfos ~= 0 then
        for _, DecorationInfo in ipairs(NeedUpdatedActorInfos) do
            OfficeSubsystem.ClientActorDecoratedEventDispatcher:Broadcast(DecorationInfo.ActorID, DecorationInfo, EventParams)
        end
    end

    --创建还未存在的Actor
    if #NeedSpawnActorInfos ~= 0 then
        for _, DecorationInfo in ipairs(NeedSpawnActorInfos) do
            self.OfficeManager:SpawnDecorationActor(DecorationInfo)
        end
    end
end

--从试用项派生出购物车物品视图
function OfficeDecorateHandler:RefreshShopCarItemsView()
    ---@type FOfficeClientDecorationShopCar
    self.ClientDecorationShopCar = {
        SkinItems = {},
        ColorItems = {}
    } 
    
    ---@type table<string, FOfficeModelSkinPayItem>
    local ShopSkinItemsMap = {}
    for _, TrialSkinItem in pairs(self.TrialDecorationItems.SkinTrialItems:ToTable()) do
        local SkinKey = TrialSkinItem.SkinKey
        if ShopSkinItemsMap[SkinKey] == nil then
            ShopSkinItemsMap[SkinKey] = {SkinKey = SkinKey, Num = 1}
        else
            ShopSkinItemsMap[SkinKey].Num = ShopSkinItemsMap[SkinKey].Num + 1
        end
        G.log:info("yongzyzhang", "RefreshShopCarItemsView ActorID:%s trial Skin:%s", 
                TrialSkinItem.ActorID, TrialSkinItem.SkinKey)
    end
    self.ClientDecorationShopCar.SkinItems = ShopSkinItemsMap
    
    local ShopColorItemsMap = {}
    for _, TrialColorItem in pairs(self.TrialDecorationItems.ColorTrialItems:ToTable()) do
        local DecorationInfo = self:GetActorDecorationInfo(TrialColorItem.ActorID, false)
        local ModelKey = self:GetActorBasicModelKey(TrialColorItem.ActorID)
        if DecorationInfo.SkinKey and DecorationInfo.SkinKey ~= "" then
            ModelKey = DecorationInfo.SkinKey
        end

        ---@type FOfficeModelColorPayItem
        local ShopColorItem = {}
        ShopColorItem.ModelKey = ModelKey
        ShopColorItem.Index = TrialColorItem.Index
        ShopColorItem.Color = TrialColorItem.Color
        local ShopColorItemString = self:ColorShopItemToString(ShopColorItem)
        if ShopColorItemsMap[ShopColorItemString] == nil then
            ShopColorItemsMap[ShopColorItemString] = ShopColorItem
            table.insert(self.ClientDecorationShopCar.ColorItems, ShopColorItem)
            G.log:info("yongzyzhang", "RefreshShopCarItemsView ActorID:%s trial CompColorItemInfo:%s",
                    TrialColorItem.ActorID, ShopColorItemString)
        end
    end
    
end

function OfficeDecorateHandler:GetShopCarItemsView()
    return self.ClientDecorationShopCar
end

function OfficeDecorateHandler:RegisterShopCarRefreshEvent(Listener, Callback)
    local InnerCallback = function()
        pcall(function()
            Callback(Listener, self:GetShopCarItemsView())
        end)
    end
    local CallbackObj = {
        identity = Callback,
        callback = InnerCallback,
    }

    self.ClientEventDispatcher:AddListener(EventNameDict.ClientShopCarRefreshEventName, Listener, CallbackObj)
end


function OfficeDecorateHandler:BroadcastShopCarRefreshEvent(SourceText)
    G.log:info("yongzyzhang", "OfficeDecorateHandler:BroadcastShopCarRefreshEvent SourceText:%s", SourceText)
    self:RefreshShopCarItemsView()
    self.ClientEventDispatcher:Broadcast(EventNameDict.ClientShopCarRefreshEventName)
end

function OfficeDecorateHandler:RegisterEvent(EventName, Listener, Callback)
    if not EventNameDict[EventName] then
        G.log:info("yongzyzhang", "OfficeDecorateHandler:RegisterEvent invalid EventName:%s", EventName)
        return
    end
    local InnerCallback = function(...)
        pcall(function(...)
            Callback(Listener, ...)
        end)
    end
    local CallbackObj = {
        identity = Callback,
        callback = InnerCallback,
    }

    self.ClientEventDispatcher:AddListener(EventName, Listener, CallbackObj)
end


--client 初始全量同步后，为了可靠和保序，后续用rpc同步DecorationActorInfos变化数据
function OfficeDecorateHandler:OnRep_SavedActorDecorationInfos()
    self.Overridden.OnRep_SavedActorDecorationInfos(self)
    G.log:info("yongzyzhang", "OfficeDecorateHandler OnRep_DecorationActorInfos")
    -- beginPlay的时候去处理
    if not self.bHasBegunPlay then
        return
    end
    --目前仅初始同步一次DecorationActorInfos，Beginplay之后，DecorationActorInfos不会同步了，下面应该走不到了
    self:FlushAllDecorationActors()
end

function OfficeDecorateHandler:ColorShopItemToString(ColorShopItem)
    local Color = ColorShopItem.Color
    local ColorString = string.format("r:%d g:%d b:%d a:%d", Color.R or 0, Color.G or 0, Color.B or 0, Color.A or 0)
    return string.format("ModelKey:%s_Index:%s_Color:(%s)", ColorShopItem.ModelKey, ColorShopItem.Index, ColorString)
end

-- 事务所资产数据变化，刷新未购买项，重新派生购物车视图
function OfficeDecorateHandler:RefreshTrialItems()
    local NeedRefresh = self:RemoveOfficeTrialItems()
    if NeedRefresh then
        self:BroadcastShopCarRefreshEvent("RemoveOfficeTrialItems, so refresh shop car")
    end
end

function OfficeDecorateHandler:RemoveOfficeTrialItems()
    local bChanged = false
    local AvailablePayedSkinItemsMap = {}
    local AvailablePayedColorItemsMap = {}
    
    for Index, SkinTrialInfo in pairs(self.TrialDecorationItems.SkinTrialItems:ToTable()) do
        local TrialSkinKey = SkinTrialInfo.SkinKey
        if AvailablePayedSkinItemsMap[TrialSkinKey] == nil then
            AvailablePayedSkinItemsMap[TrialSkinKey] = self:GetPayedSkinNum(TrialSkinKey) - self:GetUsedSkinNum(TrialSkinKey)
        end
        if AvailablePayedSkinItemsMap[TrialSkinKey] > 0 then
            AvailablePayedSkinItemsMap[TrialSkinKey] = AvailablePayedSkinItemsMap[TrialSkinKey] - 1
            --移除试用换肤
            self.TrialDecorationItems.SkinTrialItems:RemoveItem(SkinTrialInfo)
            bChanged = true
        end
    end

    for Index, ColorTrialInfo in pairs(self.TrialDecorationItems.ColorTrialItems:ToTable()) do
        local ActorID = ColorTrialInfo.ActorID
        local ModelKey = self:GetActorCurrentModelKey(ActorID)
        -- 转成购物车项
        local TrialShopColorItem = {
            ModelKey = ModelKey,
            Index = ColorTrialInfo.Index,
            Color = ColorTrialInfo.Color
        }
        local ColorItemString = self:ColorShopItemToString(TrialShopColorItem)
        if AvailablePayedColorItemsMap[ColorItemString] or self:IsColorAvailable(ModelKey, ColorTrialInfo.Index, ColorTrialInfo.Color) then
            self.TrialDecorationItems.ColorTrialItems:RemoveItem(ColorTrialInfo)
            AvailablePayedColorItemsMap[ColorItemString] = true
            bChanged = true
        end
    end
    return bChanged
end

function OfficeDecorateHandler:AuthorityCheck()
    if not UE.UKismetSystemLibrary.IsServer(self) then
        return false
    end
    return self:GetOfficeOwnerPlayer() ~= nil
end

---@return PlayerController
function OfficeDecorateHandler:GetOfficeOwnerPlayer()
    return self.OfficeManager:GetOwner()
end

-- 开始请求服务RPC前调用 配合EndDecorationRPCWrapper 防止RPC重复提交
---@see OfficeDecorateHandler#EndDecorationRPCWrapper 
function OfficeDecorateHandler:StartDecorationRPCWrapper()
    self.__Waiting_RPC_Response = true
    self:ClearDecorateTimerHandler()
    self.DecorateTimerHandler = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnDecorationRPCWrapperOverTime },
            3, false)
end

function OfficeDecorateHandler:ClearDecorateTimerHandler()
    if self.DecorateTimerHandler then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.DecorateTimerHandler)
        self.DecorateTimerHandler = nil
    end
end

function OfficeDecorateHandler:OnDecorationRPCWrapperOverTime()
    self.__Waiting_RPC_Response = false
    self.DecorateTimerHandler = nil
end

-- 接收到服务response时调用
function OfficeDecorateHandler:EndDecorationRPCWrapper()
    self.__Waiting_RPC_Response = false
    self:ClearDecorateTimerHandler()
end

function OfficeDecorateHandler:GetActorCurrentModelKey(ActorID)
    local ActorDecorationInfo = self:GetActorDecorationInfo(ActorID, false)
    if ActorDecorationInfo then
        if ActorDecorationInfo.SkinKey and ActorDecorationInfo.SkinKey ~= "" then
            return ActorDecorationInfo.SkinKey
        end
    end
    return self:GetActorBasicModelKey(ActorID)
end

function OfficeDecorateHandler:GetActorBasicModelKey(ActorID)
    local DecorationInfo = self:GetActorDecorationInfo(ActorID, false)
    if DecorationInfo and DecorationInfo.BasicModelKey and DecorationInfo.BasicModelKey ~= "" then
        return DecorationInfo.BasicModelKey
    else
        -- 读取默认数据
        DecorationInfo = self:GetOfficeSubsystem():GetActorDefaultDecorationInfo(ActorID)
        return DecorationInfo.BasicModelKey
    end
end

function OfficeDecorateHandler:GetActorDefaultDecorationInfo(ActorID)
    local DecorationInfo = self:GetOfficeSubsystem():GetActorDefaultDecorationInfo(ActorID)
    if DecorationInfo == nil then
        DecorationInfo = Struct.BPS_OfficeDecorationInfo()
        DecorationInfo.ActorID = ActorID
    end

    return DecorationInfo
end

---@return OfficeSubsystem
function OfficeDecorateHandler:GetOfficeSubsystem()
    return SubsystemUtils.GetOfficeSubsystem(self)
end



---从试用的未购买项，恢复Actor完整的换肤染色数据
---@param UnPayedTrialItems FOfficeActorTrialDecorationItems
function OfficeDecorateHandler:RestoreTrialDecorationInfo(UnPayedTrialItems)
    if not self.bInDecorationMode then
        return
    end
    for Index, SkinTrialItem in pairs(UnPayedTrialItems.SkinTrialItems:ToTable()) do

        local ActorDecorationInfo = self.ClientActorDecorationInfoTable[SkinTrialItem.ActorID]
        if ActorDecorationInfo == nil then
            local DefaultDecorationInfo = self:GetActorDefaultDecorationInfo(SkinTrialItem.ActorID)

            ---@type FOfficeDecorationActorInfo
            ActorDecorationInfo = Struct.BPS_OfficeDecorationInfo()
            ActorDecorationInfo.ActorID = SkinTrialItem.ActorID
            ActorDecorationInfo.BasicModelKey = DefaultDecorationInfo.BasicModelKey or self:GetActorBasicModelKey(SkinTrialItem.ActorID)
            self.ClientActorDecorationInfoTable[SkinTrialItem.ActorID] = ActorDecorationInfo
        end
        ActorDecorationInfo.SkinKey = SkinTrialItem.SkinKey
    end

    for Index, ColorTrialItem in pairs(UnPayedTrialItems.ColorTrialItems:ToTable()) do
        ---@type FOfficeModelColorPayItem
        if self.ClientActorDecorationInfoTable[ColorTrialItem.ActorID] == nil then
            local DefaultDecorationInfo = self:GetActorDefaultDecorationInfo(ColorTrialItem.ActorID)

            ---@type FOfficeDecorationActorInfo
            local ActorUnPayedDecorationInfo = Struct.BPS_OfficeDecorationInfo()
            ActorUnPayedDecorationInfo.ActorID = ColorTrialItem.ActorID
            ActorUnPayedDecorationInfo.BasicModelKey = DefaultDecorationInfo.BasicModelKey or self:GetActorBasicModelKey(ColorTrialItem.ActorID)
            self.ClientActorDecorationInfoTable[ColorTrialItem.ActorID] = ActorUnPayedDecorationInfo
        end
        local ModelComps = self.ClientActorDecorationInfoTable[ColorTrialItem.ActorID].Component
        local bCompMultiColor = false
        for CompIndex = 1, ModelComps:Length() do
            local Comp = ModelComps:GetRef(CompIndex)
            if Comp.Index == ColorTrialItem.Index then
                --替换同部位颜色
                Comp.Color = ColorTrialItem.Color
                bCompMultiColor = true
                break
            end
        end
        if not bCompMultiColor then
            local NewComp = Struct.BPS_OfficeModelPartInfo()
            NewComp.Index = ColorTrialItem.Index
            NewComp.Color = ColorTrialItem.Color
            ModelComps:Add(NewComp)
        end
    end
end

---获取Actor的换肤数据，装修模式下，bIgnoreTrial不为true时，优先返回Actor试用的换肤数据
---@param bCreateCopy boolean 可不传，默认返回引用
---@param bIgnoreTrial boolean 默认false , 传true时，不返回试用装修数据
---@return FOfficeDecorationActorInfo Actor的换肤数据
---@return boolean 是否是试用
function OfficeDecorateHandler:GetActorDecorationInfo(ActorID, bCreateCopy)
    if self.bInDecorationMode and UE.UHiUtilsFunctionLibrary.IsClient(self) then
        -- 客户端装修模式下，如果有试用项，这里返回的是试用装修数据
        if self.ClientActorDecorationInfoTable[ActorID] then
            local result = self.ClientActorDecorationInfoTable[ActorID]
            if bCreateCopy then
                return result:Copy()
            else
                return result
            end
        end
    else
        for Index = 1, self.SavedActorDecorationInfos:Length() do
            local DecorationInfoRef = self.SavedActorDecorationInfos:GetRef(Index)
            if DecorationInfoRef.ActorID == ActorID then
                if bCreateCopy then
                    return self.SavedActorDecorationInfos:Get(Index)
                else
                    return DecorationInfoRef
                end
            end
        end
    end
end

---for cp
---Actor装修信息数据恢复默认
function OfficeDecorateHandler:ResetActorDecorationInfo(ActorID)
    if not self.bInDecorationMode then
        return
    end
    local OfficeSubsystem = self:GetOfficeSubsystem()
    if UE.UHiUtilsFunctionLibrary.IsClient(self) then
        local Default = self:GetActorDefaultDecorationInfo(ActorID)
        Default.ActorID = ActorID
        OfficeSubsystem.ClientActorDecoratedEventDispatcher:Broadcast(ActorID, Default, {bFirstSync = false, bReset = true})
        self.ClientActorDecorationInfoTable[ActorID] = nil
        
        local TrialInfoChanged = self:RemoveActorTrialItems(ActorID)
        if TrialInfoChanged then
            self:BroadcastShopCarRefreshEvent(string.format("ActorID:%s ResetActorDecorationInfo", ActorID))
        end
    else
        for Index, DecorationInfo in ipairs(self.SavedActorDecorationInfos:ToTable()) do
            if DecorationInfo.ActorID == ActorID then
                self.SavedActorDecorationInfos:RemoveItem(DecorationInfo)
                return
            end
        end
    end
end

---for cp
---一键重置全部Actor装修
function OfficeDecorateHandler:ResetAllActorDecoration()
    if not self.bInDecorationMode then
        return
    end
    self.TrialDecorationItems = Struct.BPS_OfficeDecorationTrialItems()
    if UE.UHiUtilsFunctionLibrary.IsClient(self) then
        local OfficeSubsystem = self:GetOfficeSubsystem()
        for ActorID, _ in pairs(self.ClientActorDecorationInfoTable) do
            local Default = self:GetActorDefaultDecorationInfo(ActorID)
            Default.ActorID = ActorID
            OfficeSubsystem.ClientActorDecoratedEventDispatcher:Broadcast(ActorID, Default, {bFirstSync = false, bReset = true})
        end
        self.ClientActorDecorationInfoTable = {}
        self:BroadcastShopCarRefreshEvent("ActorID:%s ResetAllActorDecoration")
    else
        ---现在都客户端操作，走不到这里
        self.SavedActorDecorationInfos:Clear()
    end
end

---更新或添加新的Actor装修信息数据
function OfficeDecorateHandler:__UpdateOrAddDecorationInfo(NewDecorationInfo)
    if not self.bInDecorationMode then
        return
    end

    if UE.UHiUtilsFunctionLibrary.IsClient(self) then
        self.ClientActorDecorationInfoTable[NewDecorationInfo.ActorID] = NewDecorationInfo
    else
        for Index, DecorationInfo in ipairs(self.SavedActorDecorationInfos:ToTable()) do
            if DecorationInfo.ActorID == NewDecorationInfo.ActorID then
                self.SavedActorDecorationInfos:Set(Index, NewDecorationInfo)
                return
            end
        end
        self.SavedActorDecorationInfos:Add(NewDecorationInfo)
    end
    
end


function OfficeDecorateHandler:OnLoadFromDatabase(GameplayProperties)
    --Mock假数据，测试逻辑，后续删除
    if GameplayProperties == nil  then
        local SavedActorDecorationInfos = {
            {
                ActorID = "HomeDecor_Furnitures_Stool_02_Exprmtl_C_1",
                Component = {
                    {
                        Index = 1,
                        Color = {
                            R = 130,
                            G = 12,
                            B = 100,
                            A = 0
                        }
                    }
                },
                Transform = {
                    Translation = {
                        X = -100,
                        Y = 100,
                    },
                },
                BasicModelKey = "Table_01_Basic",
                --SkinKey = "Table_01_Skin_01",
            },
            {
                ActorID = "HomeDecor_Furnitures_Stool_03_Exprmtl_C_1",
                Component = {
                    {
                        Index = 1,
                        Color = {
                            R = 255,
                            G = 0,
                            B = 100,
                            A = 0
                        }
                    }
                },
                Transform = {
                    Translation = {
                        X = 200,
                        Y= 200,
                    },
                },
                BasicModelKey = "Table_01_Basic",
                SkinKey = "Table_01_Skin_02",
            }
        }
        self:ParseDecorationActorInfos(SavedActorDecorationInfos)
    end
end

---for cp
---获取皮肤状态 买过不代表就可用，可用还需要看买过的件数都被Actor占用了
---@see OfficeDecorateHandler#IsSkinAvailable
function OfficeDecorateHandler:GetSkinAssetState(SkinID)
    local OfficeSubsystem = self:GetOfficeSubsystem()
    local SkinConfig = OfficeSubsystem:GetOfficeModelConfig(SkinID)
    if SkinConfig == nil then
        G.log:error("yongzyzhang", "OfficeDecorateHandler:GetSkinAssetState invalid SkinID:%s", SkinID)
        return OfficeEnums.OfficeModelSkinState.Invalid
    end

    local BasicModelID
    local ModelAsset = nil
    if SkinConfig.IsBasicMesh then
        BasicModelID = SkinID
        ModelAsset = self:GetOfficeBasicModelAsset(SkinID)
    else
        BasicModelID = OfficeSubsystem:GetBasicModelIDBySkinID(SkinID)
        ModelAsset = self:GetOfficeBasicModelAsset(BasicModelID)
    end

    if ModelAsset == nil then
        G.log:info("yongzyzhang", "OfficeDecorateHandler:IsSkinAvailable no model asset:%s", BasicModelID)
        return OfficeEnums.OfficeModelSkinState.UnPurchasedAny
    end

    local SkinAsset = ModelAsset.SkinAsset[SkinID]
    if not SkinAsset then
        return OfficeEnums.OfficeModelSkinState.UnPurchasedAny
    end
    return SkinAsset.State
end

---for cp
---获取某个基础模型或者皮肤，指的部件已解锁的颜色列表
function OfficeDecorateHandler:GetModelUnlockedColors(ModelID, CompIndex)
    local OfficeSubsystem = self:GetOfficeSubsystem()
    local ModelConfig = OfficeSubsystem:GetOfficeModelConfig(ModelID)
    if ModelConfig == nil then
        G.log:error("yongzyzhang", "OfficeDecorateHandler:GetModelUnlockedColors invalid ModelID:%s", ModelID)
        return {}
    end
    if not ModelConfig.IsBasicMesh then
        local BasicModelKey = OfficeSubsystem:GetBasicModelIDBySkinID(ModelID)
        local BasicModelAsset = self:GetOfficeBasicModelAsset(BasicModelKey)
        if BasicModelAsset and BasicModelAsset.SkinAsset and BasicModelAsset.SkinAsset[ModelID] then
            local SkinAsset = BasicModelAsset.SkinAsset[ModelID]
            if SkinAsset.ComponentAsset then
                return SkinAsset.ComponentAsset[CompIndex] or {}
            end
        end
    else
        local BasicModeAsset = self:GetOfficeBasicModelAsset(ModelID)
        if BasicModeAsset and BasicModeAsset.ComponentAsset then
            return BasicModeAsset.ComponentAsset[CompIndex] or {}
        end
    end
    return {}
end

---获取购买过的ID是SkinID的皮肤件数
function OfficeDecorateHandler:GetPayedSkinNum(SkinID)
    local OfficeSubsystem = self:GetOfficeSubsystem()
    local SkinConfig = OfficeSubsystem:GetOfficeModelConfig(SkinID)

    if self:GetSkinAssetState(SkinID) ~= OfficeEnums.OfficeModelSkinState.AlreadyPurchasedOne then
        return 0
    end

    local BasicModelID
    local ModelAsset = nil
    if SkinConfig.IsBasicMesh then
        BasicModelID = SkinID
        ModelAsset = self:GetOfficeBasicModelAsset(SkinID) or {}
    else
        BasicModelID = OfficeSubsystem:GetBasicModelIDBySkinID(SkinID)
        ModelAsset = self:GetOfficeBasicModelAsset(BasicModelID) or {}
    end

    if ModelAsset.SkinAsset == nil or ModelAsset.SkinAsset[SkinID] == nil then
        G.log:info("yongzyzhang", "OfficeDecorateHandler:IsSkinAvailable no skin asset:%s", SkinID)
        return 0
    end

    -- 拥有的皮肤件数
    local SkinNum = #ModelAsset.SkinAsset[SkinID].SkinItem
    return SkinNum
end

function OfficeDecorateHandler:GetUsedSkinNum(SkinID)
    local UsedSkinNum = 0
    if UE.UHiUtilsFunctionLibrary.IsClient(self) then
        for _, DecorationInfo in pairs(self.ClientActorDecorationInfoTable) do
            if DecorationInfo.SkinKey == SkinID then
                UsedSkinNum = UsedSkinNum + 1
            end
        end
    else
        for _, ActorDecorationInfo in pairs(self.SavedActorDecorationInfos) do
            local ActorID = ActorDecorationInfo.ActorID
            if self.SavedActorDecorationInfos[ActorID] == nil and ActorDecorationInfo.SKinID == SkinID then
                UsedSkinNum = UsedSkinNum + 1
            end
        end
    end
    return UsedSkinNum
end

--Server&client
--判断SkinID是否无须购买。直接可用
function OfficeDecorateHandler:IsSkinAvailable(SkinID)
    local OfficeSubsystem = self:GetOfficeSubsystem()
    local SkinConfig = OfficeSubsystem:GetOfficeModelConfig(SkinID)
    -- 默认皮肤直接可用
    if SkinConfig.IsBasicMesh then
        return true
    end

    local OwnedSkinNum = self:GetPayedSkinNum(SkinID)
    local UsedSkinNum = self:GetUsedSkinNum(SkinID)
   
    G.log:info("yongzyzhang", "OfficeDecorateHandler:IsSkinAvailable SkinID:%s OwnedNum:%d UsedNum:%d", 
            SkinID, OwnedSkinNum, UsedSkinNum)
    return OwnedSkinNum > UsedSkinNum
end

--Server&client
--判断是否直接可用颜色
---@param ModelID string office_model表中ID（基础模型或者皮肤ID）
---@param CompIndex number 部件列表 
---@param Color UE.FColor 
function OfficeDecorateHandler:IsColorAvailable(ModelID, CompIndex, Color)
    local OfficeSubsystem = self:GetOfficeSubsystem()
    local ModelConfig = OfficeSubsystem:GetOfficeModelConfig(ModelID)
    
    local ComponentAsset
    if ModelConfig.IsBasicMesh then
        local BasicModelAsset = self:GetOfficeBasicModelAsset(ModelID)
        if BasicModelAsset then
            ComponentAsset = BasicModelAsset.ComponentAsset
        end
    else
        -- ModelID 是一个皮肤ID
        local SkinID = ModelID
        local BasicModelID = OfficeSubsystem:GetBasicModelIDBySkinID(SkinID)
        local BasicModelAsset = self:GetOfficeBasicModelAsset(BasicModelID)
        if BasicModelAsset and BasicModelAsset.SkinAsset[SkinID] then
            ComponentAsset = BasicModelAsset.SkinAsset[SkinID].ComponentAsset
        end
    end
    
    if not ComponentAsset then
        return false
    end

    for _, ModelComp in pairs(ComponentAsset) do
        if ModelComp.Index == CompIndex then
            for _, PaidColor in pairs(ModelComp.UnlockedColor) do
                local FColor = utils.ToFColor(PaidColor)
                if FColor == Color then
                    return true
                end
            end
        end
    end
    return false
end

function OfficeDecorateHandler:RemoveActorTrialItems(ActorID)
    local TrialInfoChanged = false
    for Index, SkinPayItem in pairs(self.TrialDecorationItems.SkinTrialItems:ToTable()) do
        if SkinPayItem.ActorID == ActorID then
            self.TrialDecorationItems.SkinTrialItems:Remove(Index)
            TrialInfoChanged = true
            break
        end
    end
    for Index, ColorPayItem in pairs(self.TrialDecorationItems.ColorTrialItems:ToTable()) do
        if ColorPayItem.ActorID == ActorID then
            self.TrialDecorationItems.ColorTrialItems:RemoveItem(ColorPayItem)
            TrialInfoChanged = true
        end
    end
    return TrialInfoChanged
end

---only client CP 调用接口
---为某个Actor换肤 (非试用)
function OfficeDecorateHandler:ClientChangeSkinForActor(ActorID, NewSkinID)
    if not self.bInDecorationMode then
        return
    end
    -- 换成已拥有的皮肤了，试用的数据都失效
    local TrialInfoChanged = self:RemoveActorTrialItems(ActorID)
    
    local DecorationInfo, _ = self:__InnerChangeSkinForActor(ActorID, NewSkinID)
    self:__UpdateOrAddDecorationInfo(DecorationInfo)

    if TrialInfoChanged then
        self:BroadcastShopCarRefreshEvent(string.format("ClientChangeSkinForActor ActorID:%s NewSkinID:%s", 
                ActorID, NewSkinID))
    end
end

---only client CP 调用接口
---为某个Actor试用皮肤
function OfficeDecorateHandler:ClientTrialSkinForActor(ActorID, NewSkinID)
    if not self.bInDecorationMode then
        return
    end
    
    ---移除原先所有试用项
    self:RemoveActorTrialItems(ActorID)
    
    local NewSkinItem = Struct.BPS_OfficeModelSkinTrialItem()
    NewSkinItem.ActorID = ActorID
    NewSkinItem.SkinKey = NewSkinID
    self.TrialDecorationItems.SkinTrialItems:Add(NewSkinItem)
    
    local OriginActorDecorationInfo = self:GetActorDecorationInfo(ActorID, false)
    local OriginSkinKey = OriginActorDecorationInfo.SkinKey
    local DecorationInfo = self:__InnerChangeSkinForActor(ActorID, NewSkinID)
    
    self:__UpdateOrAddDecorationInfo(DecorationInfo)

    --释放皮肤占用
    if OriginSkinKey and OriginSkinKey ~= "" then
        self:FreeOriginUsedSkin(OriginSkinKey)
    end
    
    self:BroadcastShopCarRefreshEvent(string.format("ClientTrialSkinForActor ActorID:%s NewSkinID:%s",
            ActorID, NewSkinID))
end

--释放已拥有的皮肤占用
---@return boolean 是否释放
function OfficeDecorateHandler:FreeOriginUsedSkin(AvailableSkinKey)
    --可能某个Actor试用的是AvailableSkinKey这款皮肤，所以需要将这个Actor的皮肤试用数据去掉
    for Index, TrailSkinItem in pairs(self.TrialDecorationItems.SkinTrialItems:ToTable()) do
        if TrailSkinItem.SkinKey == AvailableSkinKey and self:IsSkinAvailable(AvailableSkinKey) then
            self.TrialDecorationItems.SkinTrialItems:Remove(Index)
            G.log:info("yongzyzhang", "OfficeDecorateHandler:FreeOriginUsedSkin SkinKey:%s, Actor:%s auto used it",
                    AvailableSkinKey, TrailSkinItem.ActorID)
            return true
        end
    end
    return false
end

--Server&client
--装修模式客户端调用，修改本地装修数据 返回是的修改的副本数据
function OfficeDecorateHandler:__InnerChangeSkinForActor(ActorID, NewSKinID)
    local DecorationInfo = self:GetActorDecorationInfo(ActorID, true)
    
    --@type FOfficeDecorationActorInfo
    if not DecorationInfo then
        DecorationInfo = self:GetActorDefaultDecorationInfo(ActorID)
    end
    
    DecorationInfo.SkinKey = NewSKinID
    -- 换肤后恢复默认颜色
    DecorationInfo.Component:Clear()
    
    if not UE.UHiUtilsFunctionLibrary.IsServer(self) then
        self:GetOfficeSubsystem().ClientActorDecoratedEventDispatcher:Broadcast(ActorID, DecorationInfo,
                {bFirstSync = false})
    end
    return DecorationInfo
end

---only client CP 调用接口
---在一个已拥有的皮肤上换上已有的颜色
---试用未拥有的颜色，使用下面这个接口 
---@see OfficeDecorateHandler#ClientTrialColorForActor 
function OfficeDecorateHandler:ClientChangeColorForActor(ActorID, CompIndex, NewColor)
    if not self.bInDecorationMode then
        return
    end
    -- 移除原试用染色
    local bTrialChanged = false
    for Index, TrailColorItem in pairs(self.TrialDecorationItems.ColorTrialItems:ToTable()) do
        if TrailColorItem.ActorID == ActorID and TrailColorItem.Index == CompIndex then
            self.TrialDecorationItems.SkinTrialItems:Remove(Index)
            bTrialChanged = true
            break
        end
    end
    local DecorationInfo = self:__InnerChangeColorForActor(ActorID, CompIndex, NewColor)
    self:__UpdateOrAddDecorationInfo(DecorationInfo)
    if bTrialChanged then
        self:BroadcastShopCarRefreshEvent(string.format("ClientTrialColorForActor ActorID:%s CompIndex:%d NewColor:%s",
                ActorID, CompIndex, NewColor))
    end
end

---only client CP 调用接口
---试用未拥有的颜色
function OfficeDecorateHandler:ClientTrialColorForActor(ActorID, CompIndex, NewColor)
    if not self.bInDecorationMode then
        return
    end
    local DecorationInfo = self:__InnerChangeColorForActor(ActorID, CompIndex, NewColor)
    self:__UpdateOrAddDecorationInfo(DecorationInfo)

    ---更新Actor换肤部件试用颜色信息
    local bReplace = false
    for Index, ColorPayItem in pairs(self.TrialDecorationItems.ColorTrialItems:ToTable()) do
        if ColorPayItem.ActorID == ActorID and ColorPayItem.Index == CompIndex then
            ColorPayItem.Color = NewColor
            self.TrialDecorationItems.ColorTrialItems:Set(Index, ColorPayItem)
            bReplace = true
            break
        end
    end
    if not bReplace then
        local NewColorTrialItem = Struct.BPS_OfficeModelColorTrialItem()
        NewColorTrialItem.ActorID = ActorID
        NewColorTrialItem.Index = CompIndex
        NewColorTrialItem.Color = NewColor
        self.TrialDecorationItems.ColorTrialItems:Add(NewColorTrialItem)
    end
    self:BroadcastShopCarRefreshEvent(string.format("ClientTrialColorForActor ActorID:%s CompIndex:%d NewColor:%s",
            ActorID, CompIndex, NewColor))
end

--Server&client
--装修模式客户端调用，修改本地装修数据 返回修改后的副本
---@return FOfficeDecorationActorInfo
function OfficeDecorateHandler:__InnerChangeColorForActor(ActorID, CompIndex, NewColor)
    local TargetComponentInfo = nil
    --新副本对象
    local ActorDecorationInfo = self:GetActorDecorationInfo(ActorID, true)
    if ActorDecorationInfo == nil then
        ActorDecorationInfo = self:GetActorDefaultDecorationInfo(ActorID)
    else
        for Index = 1, ActorDecorationInfo.Component:Length() do
            local ComponentInfoRef = ActorDecorationInfo.Component:GetRef(Index)
            if CompIndex == ComponentInfoRef.Index then
                TargetComponentInfo = ComponentInfoRef
                break
            end
        end
    end
    if not TargetComponentInfo then
        --第一次给CompIndex的组件换色
        local NewComponentInfo = Struct.BPS_OfficeModelPartInfo()
        NewComponentInfo.Index = CompIndex
        NewComponentInfo.Color = NewColor
        ActorDecorationInfo.Component:Add(NewComponentInfo)
    else
        TargetComponentInfo.Color = NewColor
    end
    
    if not UE.UHiUtilsFunctionLibrary.IsServer(self) then
        self:GetOfficeSubsystem().ClientActorDecoratedEventDispatcher:Broadcast(ActorID, ActorDecorationInfo,
                {bFirstSync = false})
    end
    return ActorDecorationInfo
end

---for cp 移除购物车项时调用
---@param RemovedShopItems FOfficeClientDecorationShopCar
function OfficeDecorateHandler:ClientRemoveShopItems(RemovedShopItems)
    if not self.bInDecorationMode then
        return
    end
    if self.__Waiting_RPC_Response then
        self:Client_OperationTooBusy(OfficeEnums.DecorationErrorCode.Busy)
        return
    end
    local RemovedSkinItemsMap = {}
    local RemovedColorItemsMap = {}

    local SkinItems = RemovedShopItems.SkinItems or {}
    for _, SkinItem in pairs(SkinItems) do
        RemovedSkinItemsMap[SkinItem.SkinKey] = SkinItem.Num
    end

    local ColorItems = RemovedShopItems.ColorItems or {}
    for _, CompColorItem in pairs(ColorItems) do
        local ColorString = self:ColorShopItemToString(CompColorItem)
        if not RemovedColorItemsMap[ColorString] then
            RemovedColorItemsMap[ColorString] = true
        end
    end

    for Index, SkinTrialInfo in pairs(self.TrialDecorationItems.SkinTrialItems:ToTable()) do
        local TrialSkinKey = SkinTrialInfo.SkinKey
        if RemovedSkinItemsMap[TrialSkinKey] and RemovedSkinItemsMap[TrialSkinKey] > 0 then
            RemovedSkinItemsMap[TrialSkinKey] = RemovedSkinItemsMap[TrialSkinKey] - 1

            --移除试用换肤
            self.TrialDecorationItems.SkinTrialItems:RemoveItem(SkinTrialInfo)
        end
    end

    for Index, ColorTrialInfo in pairs(self.TrialDecorationItems.ColorTrialItems:ToTable()) do
        local ActorID = ColorTrialInfo.ActorID
        local ModelKey = self:GetActorCurrentModelKey(ActorID)
        -- 转成购物车项
        local TrialShopColorItem = {
            ModelKey = ModelKey,
            Index = ColorTrialInfo.Index,
            Color = ColorTrialInfo.Color
        }

        local ColorItemString = self:ColorShopItemToString(TrialShopColorItem)
        if RemovedColorItemsMap[ColorItemString] then
            self.TrialDecorationItems.ColorTrialItems:RemoveItem(ColorTrialInfo)
        end
    end
    self:BroadcastShopCarRefreshEvent("OfficeDecorateHandler:ClientRemoveShopItems")
end

--TODO 读取配置返回 组件序号是否合理
function OfficeDecorateHandler:IsCompIndexValid(BasicModelID, SkinID, CompIndex)
    return CompIndex <= 4;
end

function OfficeDecorateHandler:ClientOnSyncOfficeAsset(OfficeAsset)
    self.OfficeAssetLocalCache = OfficeAsset or {}
    
end

---for cp 购买购物车项时调用
---@param ShopCarItems FOfficeClientDecorationShopCar
function OfficeDecorateHandler:ClientPurchaseTrialItems(ShopCarItems)
    if not self.bInDecorationMode then
        return
    end
    if self.__Waiting_RPC_Response then
        self:Client_OperationTooBusy(OfficeEnums.DecorationErrorCode.Busy)
        return
    end
    local Callback = function(ErrorCode, Msg)
        if ErrorCode == OfficeEnums.DecorationErrorCode.OK then
            -- 改为ping、pong的方式。统一背包使用等其他地方获取换肤资产通知客户端逻辑
        end
    end
    self:RequestBuyShopCarItems(ShopCarItems, Callback)
end

---for cp 离开装修模式时调用
function OfficeDecorateHandler:ClientRequestLevelDecorationMode(bPayAll)
    ---@type FLeaveOfficeDecorationModeParam
    local LeaveParam = Struct.BPS_OfficeLeaveDecorationModeParam()
    LeaveParam.bPayAll = bPayAll or false
    for _, ClientChangedDecorationInfo in pairs(self.ClientActorDecorationInfoTable) do
        LeaveParam.ActorDecorationInfos:Add(ClientChangedDecorationInfo)
    end
    LeaveParam.TrialDecorationItems = self.TrialDecorationItems
    self:Server_LeaveDecorationMode(LeaveParam)
end

--------------------RPC 接口 开始--------------------

function OfficeDecorateHandler:Server_EnterDecorationMode_RPC()
    if self.bInDecorationMode then
        self:Client_EnterDecorationModeResult(OfficeEnums.DecorationErrorCode.AlreadyInDecorationMode, "AlreadyInDecorationMode")
        return
    end
    --TODO 处理AOI
    self.bInDecorationMode = true
    self:Client_EnterDecorationModeResult(OfficeEnums.DecorationErrorCode.OK, "")

end

function OfficeDecorateHandler:Client_EnterDecorationModeResult_RPC(ErrorCode, Msg)
    if ErrorCode ~= OfficeEnums.DecorationErrorCode.OK then
        G.log:info("yongzyzhang", "Client_EnterDecorationModeResult failed, code:%d msg:%s", ErrorCode, Msg)
        return
    end

    --客户端请求服务，拿一份最新的资产数据
    self:GetOfficeSubsystem():RequestOfficeAsset(self:GetOfficeOwnerPlayer(), function(Ok, OfficeAsset) 
        self.OfficeAssetLocalCache = OfficeAsset or {}
    end)
    
    local AllCharacters = UE.TArray(UE.AHiCharacter)
    UE.UGameplayStatics.GetAllActorsOfClass(self, UE.AHiCharacter, AllCharacters)

    local LocalPlayerPawn = UE.UGameplayStatics.GetPlayerPawn(self, 0)
    for _, Character in pairs(AllCharacters:ToTable()) do
        Character:SetActorHiddenInGame(true)
        Character:SetActorEnableCollision(false)
        if LocalPlayerPawn ~= Character then
            local ActorName = G.GetObjectName(Character)
            G.log:info("yongzyzhang", "hide Pawn:%s in game", ActorName)
        end
    end
    LocalPlayerPawn:SetActorHiddenInGame(false)
    LocalPlayerPawn:SetActorEnableCollision(true)

    self.bInDecorationMode = true
    G.log:info("yongzyzhang", "Client_EnterDecorationModeResult succeed")
    
    self:FlushAllDecorationActors({bReset=true})
    
end

---@param ShopCarItems FOfficeClientDecorationShopCar
function OfficeDecorateHandler:RequestBuyShopCarItems(ShopCarItems, Callback)
    local BuySkinItemTable = ShopCarItems.SkinItems or {}
    local BuyColorItemTable = ShopCarItems.ColorItems or {}

    local CostItems = self:CalculateUnPayItemsCost(BuySkinItemTable, BuyColorItemTable)
    local ItemManager = self:GetOfficeOwnerPlayer():GetItemManager()

    for ItemID, CostItemNum in pairs(CostItems) do
        -- 支付项不足，返回失败
        if not ItemManager:IsItemEnough(ItemID, CostItemNum) then
            if Callback then
                Callback(OfficeEnums.DecorationErrorCode.CostItemNotEnough, "")
            end
            return
        end
    end

    local Req = {
        SkinPayItems = {},
        ColorPayItems = {}
    }
    for _, BuySkinItem in pairs(BuySkinItemTable) do
        table.insert(Req.SkinPayItems, { SkinID = BuySkinItem.SkinKey, Num = BuySkinItem.Num })
    end

    for _, BuyColorItem in pairs(BuyColorItemTable) do
        table.insert(Req.ColorPayItems, { ModelID = BuyColorItem.ModelKey,
                                          CompIndex = BuyColorItem.Index, Color = BuyColorItem.Color })
    end
    
    local Invoker = self:GetOfficeOwnerPlayer():GetRemoteMetaInvoker(MSConfig.MSOfficeEntityMetaName, self.OfficeManager.OfficeGid)
    self:StartDecorationRPCWrapper()
    Invoker:PayForDecorationItems(Req, function(Context, Response)
        self:EndDecorationRPCWrapper()
        
        ---@type IRPCStatus
        local Status = Context:GetStatus()
        if not Status:OK() then
            G.log:error("yongzyzhang", "RequestBuyShopCarItems call RPC PayForDecorationItems failed, errorMsg:%s", utils.IRPCStatusString(Status))
            if Callback then
                Callback(OfficeEnums.DecorationErrorCode.UnknownServerError, utils.IRPCStatusString(Status))
            end
        else
            if Callback then
                Callback(OfficeEnums.DecorationErrorCode.OK, "")
            end
        end
    end)
end

function OfficeDecorateHandler:GetOfficeBasicModelAsset(BasicModelID)
    if self.OfficeAssetLocalCache == nil then
        self.OfficeAssetLocalCache = {}
    end
    if self.OfficeAssetLocalCache.Model == nil then
        self.OfficeAssetLocalCache.Model = {}
    end
    return self.OfficeAssetLocalCache.Model[BasicModelID]
end

---计算所有未支付项的价格
---@param BuySkinItems table<FOfficeModelSkinPayItem>
---@param BuyColorItems table<FOfficeModelColorPayItem>
---@return table<number, number>
function OfficeDecorateHandler:CalculateUnPayItemsCost(BuySkinItems, BuyColorItems)
    local OfficeSubsystem = self:GetOfficeSubsystem()
    local CostItemTable = {}
    if BuySkinItems then
        for _, PaySkinItem in pairs(BuySkinItems) do
            local SkinConfig = OfficeSubsystem:GetSkinConfig(PaySkinItem.SkinKey)
            assert(SkinConfig ~= nil, "invalid Skin item key:" .. PaySkinItem.SkinKey)
            if SkinConfig then
                if not CostItemTable[SkinConfig.UnlockItemID] then
                    CostItemTable[SkinConfig.UnlockItemID] = SkinConfig.UnlockItemNum * PaySkinItem.Num
                else
                    CostItemTable[SkinConfig.UnlockItemID] = CostItemTable[SkinConfig.UnlockItemID]
                            + SkinConfig.UnlockItemNum * PaySkinItem.Num
                end
            end
        end
    end
    if BuyColorItems then
        for _, PayColorItem in pairs(BuyColorItems) do
            local ModelConfig = OfficeSubsystem:GetOfficeModelConfig(PayColorItem.ModelKey)
            assert(ModelConfig ~= nil, "invalid Color item modelkey:" .. PayColorItem.ModelKey)
            if ModelConfig then
                if not CostItemTable[ModelConfig.ColorUnlockItemID] then
                    CostItemTable[ModelConfig.ColorUnlockItemID] = ModelConfig.ColorUnlockItemNum
                else
                    CostItemTable[ModelConfig.ColorUnlockItemID] = CostItemTable[ModelConfig.ColorUnlockItemID] +
                            ModelConfig.ColorUnlockItemNum
                end
            end
        end
    end
    return CostItemTable
end

---@param LeaveParam FLeaveOfficeDecorationModeParam
function OfficeDecorateHandler:Server_LeaveDecorationMode_RPC(LeaveParam)
    if not self:AuthorityCheck() then
        return
    end
    if self.__Waiting_RPC_Response then
        self:Client_OperationTooBusy(OfficeEnums.DecorationErrorCode.Busy)
        return
    end
    if not self.bInDecorationMode then
        self:Client_LeaveDecorationModeResult(OfficeEnums.DecorationErrorCode.NotInDecorationMode, "NotInDecorationMode")
        return
    end
    
    
    -- 先存一份，购买成功后清空
    self.TrialDecorationItems = LeaveParam.TrialDecorationItems:Copy()

    -- 保持在SavedActorDecorationInfos，只是为了临时引用住LeaveParam的ActorDecorationInfos
    self.SavedActorDecorationInfos:Append(LeaveParam.ActorDecorationInfos)

    local LeaveLogic = function(ErrorCode, Msg)
        self.bInDecorationMode = false
        --G.log:warn("yongzyzhang", "Server_LeaveDecorationMode_RPC 222222 ActorCount:%d", ActorDecorationInfos:Length())
        local ActorDecorationInfos = UE.TArray(Struct.BPS_OfficeDecorationInfo)
        ActorDecorationInfos:Append(self.SavedActorDecorationInfos)
        
        -- 验证Actor装修数据正常
        local ValidDecorationInfoList, NeedDeleteActorIDList = self:FilterUploadDecorations(ActorDecorationInfos)
        
        self.SavedActorDecorationInfos:Clear()
        self.SavedActorDecorationInfos:Append(ValidDecorationInfoList)
        
        self:Client_LeaveDecorationModeResult(ErrorCode, Msg or "", NeedDeleteActorIDList)
        self:Multicast_OnOfficeFinishDecorated(self.SavedActorDecorationInfos)
    end

    if LeaveParam.bPayAll then
        local Callback = function(ErrorCode, Msg)
            if ErrorCode ~= OfficeEnums.DecorationErrorCode.OK then
                self:Client_LeaveDecorationModeResult(ErrorCode, Msg or "")
            else
                self.TrialDecorationItems = Struct.BPS_OfficeDecorationTrialItems()
            end
            LeaveLogic(ErrorCode, Msg or "")
        end
        
        self:RequestBuyShopCarItems(LeaveParam.TrialDecorationItems, Callback)
    else
        -- 请求一份最新的资产数据。用于判断提交的Actor装修数据是否合法
        self:StartDecorationRPCWrapper()
        self:GetOfficeSubsystem():RequestOfficeAsset(self:GetOfficeOwnerPlayer(),  function()
            self:EndDecorationRPCWrapper()
            LeaveLogic(OfficeEnums.DecorationErrorCode.OK, "")
        end)
    end
    
end

function OfficeDecorateHandler:FilterUploadDecorations(ActorDecorationInfos)
    local SkinPayNumDict = {}
    local ValidActorDecorationInfoList = UE.TArray(Struct.BPS_OfficeDecorationInfo)
    local NeedDeleteActorIDList = UE.TArray(UE.FString)

    for Index, ActorDecorationInfo in pairs(ActorDecorationInfos:ToTable()) do
        local bRemove = false
        while true 
        do
            local SkinKey = ActorDecorationInfo.SkinKey
            local UsingModelID = ActorDecorationInfo.BasicModelKey
            if SkinKey and SkinKey ~= "" then
                UsingModelID = SkinKey
                if SkinPayNumDict[SkinKey] == nil then
                    SkinPayNumDict[SkinKey] = self:GetPayedSkinNum(SkinKey)
                end
                SkinPayNumDict[SkinKey] = SkinPayNumDict[SkinKey] - 1
                -- 判断皮肤件数不够，客户端上传数据非法
                if SkinPayNumDict[SkinKey] <= 0 then
                    --NeedDeleteActorIDList:Add(ActorDecorationInfo)
                    -- 置为默认
                    ActorDecorationInfo.SkinKey = ""
                    ActorDecorationInfo.Component:Clear()

                    G.log:warn("yongzyzhang", "CheckAllUploadDecorationsValid ActorID:%s using Skin:%s bud not enough SkinNum", 
                            ActorDecorationInfo.ActorID, SkinKey)
                    break
                end
            end
            for _, Comp in pairs(ActorDecorationInfo.Component:ToTable()) do
                if not self:IsColorAvailable(UsingModelID, Comp.Index, Comp.Color) then
                    --NeedDeleteActorIDList:Add(ActorDecorationInfo)
                    -- 置为默认
                    ActorDecorationInfo.Component:RemoveItem(Comp)
                    G.log:warn("yongzyzhang", "CheckAllUploadDecorationsValid ActorID:%s Using Locked Color Model:%s CompIndex:%d Color:%s",
                            ActorDecorationInfo.ActorID, UsingModelID,Comp.Index, tostring(Comp.Color))
                    break
                end
            end
            -- 退出内层while，千万别删了
            break
        end
        if bRemove then
            NeedDeleteActorIDList:Add(ActorDecorationInfo.ActorID)
        else
            G.log:warn("yongzyzhang", "Valid ActorID:%s  BasicModel:%s Skin:%s ComponentCount:%d",
                    ActorDecorationInfo.ActorID, ActorDecorationInfo.BasicModelKey, ActorDecorationInfo.SkinKey, ActorDecorationInfo.Component:Length())
            ValidActorDecorationInfoList:Add(ActorDecorationInfo)
        end
    end
    return ValidActorDecorationInfoList, NeedDeleteActorIDList
end

function OfficeDecorateHandler:Client_LeaveDecorationModeResult_RPC(ErrorCode, ErrorMsg, NeedDeleteActorIDList)
    if ErrorCode == 0 then
        G.log:info("yongzyzhang", "Client_EnterDecorationModeResult succeed")
    else
        G.log:info("yongzyzhang", "Client_EnterDecorationModeResult failed, code:%s msg:%s")
        return
    end
    
    self.bInDecorationMode = false
    ---@type OfficeSubsystem
    local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(self)

    -- 退出试用默认后，需要清理的无效装修Actor
    if NeedDeleteActorIDList:Length() > 0 then
        for Index, ActorID in pairs(NeedDeleteActorIDList:ToTable()) do
            if OfficeSubsystem:IsOfficeDecorationActorValid(ActorID) then
                local DecorationInfo = Struct.BPS_OfficeDecorationInfo()
                DecorationInfo.ActorID = ActorID
                DecorationInfo.bRemoved = true
                OfficeSubsystem.ClientActorDecoratedEventDispatcher:Broadcast(ActorID, DecorationInfo, {})
            end
        end
    end

    local AllCharacters = UE.TArray(UE.AHiCharacter)
    UE.UGameplayStatics.GetAllActorsOfClass(self, UE.AHiCharacter, AllCharacters)
    local LocalPlayerPawn = UE.UGameplayStatics.GetPlayerPawn(self, 0)

    for _, Character in pairs(AllCharacters:ToTable()) do
        Character:SetActorHiddenInGame(false)
        Character:SetActorEnableCollision(true)
        if LocalPlayerPawn ~= Character then
            local ActorName = G.GetObjectName(Character)
            G.log:info("yongzyzhang", "show Pawn:%s in game", ActorName)
        end
    end
    
end

function OfficeDecorateHandler:Multicast_OnOfficeFinishDecorated_RPC(ActorDecorationInfos)
    if UE.UHiUtilsFunctionLibrary.IsServer(self) then
        return
    end
    self.SavedActorDecorationInfos = ActorDecorationInfos
    self:FlushAllDecorationActors({bReset = true})
end

---ParseDecorationActorInfos
---@param OfficeData {}
function OfficeDecorateHandler:ParseDecorationActorInfos(SavedActorDecorationInfos)
    if not SavedActorDecorationInfos then
        return
    end
    for Index, ActorDecorationData in pairs(SavedActorDecorationInfos) do
        -- local ModelData = DecorationDataArray:Get(index)
        ---@type FOfficeDecorationActorInfo
        local NewActorInfo = Struct.BPS_OfficeDecorationInfo()
        NewActorInfo.ActorID = ActorDecorationData.ActorID
        --NewActorInfo.Transform = UE.FTransform
        NewActorInfo.bRemoved = ActorDecorationData.bRemoved or false
        NewActorInfo.BasicModelKey = ActorDecorationData.BasicModelKey or ""
        NewActorInfo.SkinKey = ActorDecorationData.SkinKey or ""
        NewActorInfo.Transform = UE.FTransform.Identity
        if ActorDecorationData.Transform then
            if ActorDecorationData.Transform.Translation then
                local Translation = ActorDecorationData.Transform.Translation
                NewActorInfo.Transform.Translation = UE.FVector(Translation.X, Translation.Y, Translation.Z)
            end
            if ActorDecorationData.Transform.Rotation then
                local Rotation = ActorDecorationData.Transform.Rotation
                NewActorInfo.Transform.Rotation = UE.FQuat(Rotation.X, Rotation.Y, Rotation.Z, Rotation.W)
            end
            if ActorDecorationData.Transform.Scale3D then
                local Scale3D = ActorDecorationData.Transform.Scale3D
                NewActorInfo.Transform.Scale3D = UE.FVector(Scale3D.X, Scale3D.Y, Scale3D.Z)
            end
        end
        --
        if ActorDecorationData.Component then
            for _, PartData in ipairs(ActorDecorationData.Component) do
                ---@type FOfficeModelPartInfo
                local NewModelPartInfo = Struct.BPS_OfficeModelPartInfo()
                NewModelPartInfo.Index = PartData.Index
                NewModelPartInfo.Color = utils.ToFColor(PartData.Color)
                NewActorInfo.Component:Add(NewModelPartInfo)
            end
        end
        self.SavedActorDecorationInfos:Add(NewActorInfo)
    end
end

--操作频繁
function OfficeDecorateHandler:Client_OperationTooBusy_RPC()
    G.log:error("yongzyzhang", "Client_OperationTooBusy")
end


function OfficeDecorateHandler:Server_SaveDecorationToSlot_RPC(Slot, DesignActorDecorationList)
    if not self.bInDecorationMode then
        return
    end
    ---@type Struct.BPS_OfficeDesignSchemeSlot
    local TargetDesignSchemeSlot = nil
    for Index, DesignSchemeSlot in pairs(self.DesignSchemeSlots:ToTable()) do
        if DesignSchemeSlot.Slot == Slot then
            TargetDesignSchemeSlot = self.DesignSchemeSlots:GetRef(Index)
        end
    end
    
    if TargetDesignSchemeSlot == nil then
        local UsedSlotCount = self.DesignSchemeSlots:Length()
        if UsedSlotCount >= self.SlotCapacity then
            G.log:error("yongzyzhang", "UsedSlotCount:%d SlotCapacity:%d", UsedSlotCount, self.SlotCapacity)
            return
        end
        
        self.DesignSchemeSlots:AddDefault()
        UsedSlotCount = UsedSlotCount + 1
        TargetDesignSchemeSlot = self.DesignSchemeSlots:GetRef(UsedSlotCount)
        TargetDesignSchemeSlot.Slot = Slot
    end

    ---@type Struct.BPS_OfficeDesignScheme
    local DesignScheme = Struct.BPS_OfficeDesignSchemeSlot()
    DesignScheme.AuthorType = OfficeEnums.DesignSchemeAuthorType.PlayerSelf
    DesignScheme.DesignActorDecorationInfos = DesignActorDecorationList
    TargetDesignSchemeSlot.DesignScheme = DesignScheme
end

function OfficeDecorateHandler:OnRep_DesignSchemeSlots()
    G.log:info("yongzyzhang", "OnRep_DesignSchemeSlots current used slot:%d", self.DesignSchemeSlots:Length())
    self.ClientEventDispatcher:Broadcast(EventNameDict.DecorationSchemeUpdated)
end

function OfficeDecorateHandler:Server_UnlockDesignSchemeSlot_RPC()
    if not self.bInDecorationMode then
        return
    end
    -- TODO 扣费
    self.SlotCapacity = self.SlotCapacity + 1
end

function OfficeDecorateHandler:OnRep_SlotCapacity(OldCapacity)
    if OldCapacity ~= nil then
        G.log:info("yongzyzhang", "OnRep_SlotCapacity OldCapacity:%d CurrentCapacity:%d", OldCapacity, self.SlotCapacity)
    end
end

function OfficeDecorateHandler:Server_DeleteDesignScheme_RPC(Slot)
    if not self.bInDecorationMode then
        return
    end
    for Index, DesignSchemeSlot in pairs(self.DesignSchemeSlots:ToTable()) do
        if DesignSchemeSlot.Slot == Slot then
            self.DesignSchemeSlots:Remove(Index)
            break
        end
    end
end

--------------------RPC 接口 结束--------------------

---@return Struct.BPS_OfficeDesignSchemeSlot
function OfficeDecorateHandler:GetSelfDesignSchemeOnSlot(Slot)
    for Index, DesignSchemeSlot in pairs(self.DesignSchemeSlots:ToTable()) do
        if DesignSchemeSlot.Slot == Slot then
            self.DesignSchemeSlots:GetRef(Index)
            break
        end
    end
end

function OfficeDecorateHandler:ClientUseSelfDesignScheme(Slot)
    if not self.bInDecorationMode then
        return
    end
    local DesignSchemeSlot = self:GetSelfDesignSchemeOnSlot(Slot)
    if DesignSchemeSlot == nil then
        return
    end
    self.SavedActorDecorationInfos = DesignSchemeSlot.DesignScheme.DesignActorDecorationInfos
    self.TrialDecorationItems = Struct.BPS_OfficeDecorationTrialItems()
end

--function OfficeDecorateHandler:ReleaseDesignScheme(Slot)
--    local DesignSchemeSlot = self:GetSelfDesignSchemeOnSlot(Slot)
--    if DesignSchemeSlot == nil then
--        return
--    end
--    
--    local ReleaseCallback = function(Result, SchemeGid) 
--        self.ClientEventDispatcher:Broadcast(EventNameDict.ReleaseDesignScheme, Result, SchemeGid)
--    end
--    self:GetOfficeSubsystem():ReleaseDesignScheme(DesignSchemeSlot.Description, DesignSchemeSlot.DesignScheme.DesignActorDecorationInfos, ReleaseCallback)
--end
--


return OfficeDecorateHandler
