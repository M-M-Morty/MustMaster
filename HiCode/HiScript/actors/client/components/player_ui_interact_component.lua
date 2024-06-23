--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local utils = require("common.utils")
local DialogueObjectModule = require("mission.dialogue_object")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local NpcInteractItemModule = require("mission.npc_interact_item")
local GameConstData = require("common.data.game_const_data").data
local NpcInteractDef = require("common.data.npc_interact_data")
local NpcInteractData = require("common.data.npc_interact_data").data
local NpcBaseData = require("common.data.npc_base_data").data
local DialogueData = require("common.data.dialogue_data").data
local LuaUtils = require("common.utils.lua_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")

local NPC_INTERACT_TIMER_INTERVAL = 0.5  -- NPC交互刷新间隔

---@type PlayerUIInteractComponent_C
local PlayerUIInteractComponent = Component(ComponentBase)
local decorator = PlayerUIInteractComponent.decorator

function PlayerUIInteractComponent:Initialize(Initializer)
    Super(PlayerUIInteractComponent).Initialize(self, Initializer)
    self.CurrentDialogue = nil
    self.CurrentDialogueCallback = nil
    self.InteractItems = {}     -- array
    self.bNotSort = false
    self.ForceIndex = 1

    self.CurInteractNpc = nil  -- 当前正在交互的目标NPC
    self.NearbyNpcs = {}  -- 附近的NPC缓存
    self.NearbyNpcCount = 0  -- 附近NPC的数量
    self.NpcInteractRefreshTimer = nil  -- client
end

function PlayerUIInteractComponent:ReceiveBeginPlay()
    Super(PlayerUIInteractComponent).ReceiveBeginPlay(self)
end

function PlayerUIInteractComponent:ReceiveEndPlay()
    Super(PlayerUIInteractComponent).ReceiveEndPlay(self)
    if self.NpcInteractRefreshTimer then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.NpcInteractRefreshTimer)
        self.NpcInteractRefreshTimer = nil
    end
end

function PlayerUIInteractComponent:StartDialogue(DialogueObject)
    if self.CurrentDialogue ~= nil then
        G.log:error("xaelpeng", "PlayerUIInteractComponent:StartDialogue fail to start dialogue %d. already in dialogue %d", DialogueObject:GetStartDialogueID(), self.CurrentDialogue:GetStartDialogueID())
        return
    end
    local FinishCallback = function()
        self.CurrentDialogue = nil
        local Callback = self.CurrentDialogueCallback
        self.CurrentDialogueCallback = nil
        if Callback ~= nil then
            Callback()
        end
        self:OnDialogueEnd()
    end
    self.CurrentDialogue = DialogueObject
    self.CurrentDialogueCallback = DialogueObject:HookFinishCallback(FinishCallback)

    -- 开始对话时主动关闭交互按钮
    self:CloseInteractUI()

    -- 打开对话界面
    local DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
    if DialogueVM then
        DialogueVM:OpenDialogInstance(DialogueObject)
    end
end

function PlayerUIInteractComponent:OnDialogueEnd()
    if self.CurrentDialogue ~= nil then
        G.log:error("PlayerUIInteractComponent", "OnDialogueEnd, CurrentDialogue(%s) is not empty", self.CurrentDialogue:GetStartDialogueID())
        return
    end

    -- 对话结束释放交互的npc
    if self.CurInteractNpc then
        self:Server_InteractNpcEnd(self.CurInteractNpc.ActorId)
        self.CurInteractNpc = nil
    end

    self:RefreshInteractUI()
end

function PlayerUIInteractComponent:ForceFinishDialogue(DialogueObject)
    if self.CurrentDialogue ~= nil and self.CurrentDialogue == DialogueObject then
        local DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
        if DialogueVM then
            DialogueVM:CloseDialog()
        end
    end
end

decorator.message_receiver()
function PlayerUIInteractComponent:OnClientPlayerReady()
    -- 作为前台角色，开启npc交互timer
    if self:GetOwner():IsClient() and self.NpcInteractRefreshTimer == nil then
        self.NpcInteractRefreshTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, function() self:RefreshNpcInteract(true) end}, 
            NPC_INTERACT_TIMER_INTERVAL, true)
    end
end

decorator.message_receiver()
function PlayerUIInteractComponent:OnReceiveMessageBeforeSwitchOut()
    if self:GetOwner():IsClient() then
        -- 角色被切到后台之前，先关闭npc交互timer
        if self.NpcInteractRefreshTimer then
            UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.NpcInteractRefreshTimer)
            self.NpcInteractRefreshTimer = nil
        end
    end
end

function PlayerUIInteractComponent:CloseInteractUI()
    local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    if InteractVM then
        InteractVM:CloseInteractSelection()
    end
end

-- 更新交互物（采集物等非npc的actor）信息
function PlayerUIInteractComponent:UpdateInteractItems(InteractItems, bNotSort, ForceIndex)
    G.log:debug("xaelpeng", "PlayerUIInteractComponent:UpdateInteractItems %d", #InteractItems)
    self.InteractItems = InteractItems
    self.bNotSort = bNotSort and bNotSort or false
    self.ForceIndex = ForceIndex and ForceIndex or 1
    self:RefreshInteractUI()
end

function PlayerUIInteractComponent:AddNpcInteractItems(Actor, InteractItems)
    G.log:debug("PlayerUIInteractComponent", "AddNpcInteractItems Actor=%s, ItemNum=%s", Actor:GetActorID(), #InteractItems)
    local ActorID = Actor:GetActorID()
    if self.NearbyNpcs[ActorID] ~= nil then
        -- 重复添加
        G.log:error("PlayerUIInteractComponent", "AddNpcInteractItems ActorID(%s) already exist", Actor:GetActorID())
        return
    end
    local NpcItem = {}
    NpcItem.Items = InteractItems
    NpcItem.ActorId = ActorID
    NpcItem.bInRange = false
    NpcItem.Distance = nil
    NpcItem.HelloContent = self:GetNpcHelloContent(Actor) -- 问候语
    self.NearbyNpcs[ActorID] = NpcItem

    self.NearbyNpcCount = self.NearbyNpcCount + 1
    self:RefreshNpcInteract(false)
end

function PlayerUIInteractComponent:RemoveNpcInteractItems(ActorID)
    G.log:debug("PlayerUIInteractComponent", "RemoveNpcInteractItems Actor=%s", ActorID)
    if self.NearbyNpcs[ActorID] == nil then
        -- 重复删除
        G.log:error("PlayerUIInteractComponent", "RemoveNpcInteractItems ActorID(%s) doesn't exist", ActorID)
        return
    end
    self.NearbyNpcs[ActorID] = nil
    self.NearbyNpcCount = self.NearbyNpcCount - 1
    self:RefreshNpcInteract(false)
end

function PlayerUIInteractComponent:CanRefreshInteract()
    if not self:GetOwner():IsClient() then
        return false
    end
    if self.CurrentDialogue ~= nil then
        -- 正在对话时，不刷新交互按钮
        return false
    end
    if self.CurInteractNpc and self:GetActor(self.CurInteractNpc.ActorId) then
        -- 正在和NPC交互中
        return false
    end
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0)
    local bIsPlayingFlow = PlayerController.ControllerDialogueFlowComponent:IsPlayingFlow()
    if bIsPlayingFlow then
        -- 正在播放叙事
        return false
    end
    return true
end

function PlayerUIInteractComponent:RefreshNpcInteract(bAutoRefresh)
    if not self:CanRefreshInteract() then
        return
    end

    if bAutoRefresh and utils.is_dict_empty(self.NearbyNpcs) then
        -- 自动刷新触发且周边没有npc
        return
    end

    -- 筛选附近的NPC，哪些可以进入交互按钮
    local Player = self.actor
    local PlayerPos = Player:K2_GetActorLocation()
    local EmptyActorIdList = {}  -- 这些Actor，进入离开逻辑有问题。销毁了但是PlayerUIInteractComponent没收到退出事件
    for ActorID, NpcInfo in pairs(self.NearbyNpcs) do
        local Actor = self:GetActor(ActorID)
        if Actor then
            local NpcPos = Actor:K2_GetActorLocation()
            local Distance = UE.UKismetMathLibrary.Vector_Distance(PlayerPos, NpcPos)
            local MajorFwd = self:GetOwner():GetActorForwardVector()
            local Vector = NpcPos - PlayerPos
            UE.UKismetMathLibrary.Vector_Normalize(Vector)
            Vector.Z = 0
            local Degrees = UE.UKismetMathLibrary.RadiansToDegrees(UE.UKismetMathLibrary.Acos(UE.UKismetMathLibrary.Vector_CosineAngle2D(MajorFwd, Vector)))
            NpcInfo.Distance = Distance
            if Distance < (GameConstData.NPC_INTERACT_DISTANCE.FloatValue * 100) and Degrees < (GameConstData.NPC_INTERACT_ANGLE.IntValue / 2) then
                NpcInfo.bInRange = true
            else
                NpcInfo.bInRange = false
            end
        else
            table.insert(EmptyActorIdList, ActorID)
        end
    end

    -- 对不存在的ActorID进行处理
    if #EmptyActorIdList ~= 0 then
        G.log:error("PlayerUIInteractComponent", "EmptyActorIdList is not None, num=%s", #EmptyActorIdList)
    end
    for _, ActorID in ipairs(EmptyActorIdList) do
        G.log:error("PlayerUIInteractComponent", "RefreshNpcInteract Actor(%s) is empty", ActorID)
        self.NearbyNpcs[ActorID] = nil
    end

    self:RefreshInteractUI()
end

-- 一级交互
function PlayerUIInteractComponent:RefreshInteractUI()
    if not self:CanRefreshInteract() then
        return
    end

    local Items = {}
    -- 收集npc交互
    if self.NearbyNpcCount > 0 then
        for ActorID, NpcInfo in pairs(self.NearbyNpcs) do
            if NpcInfo.bInRange then
                local SelectAction = function()
                    self.CurInteractNpc = self.NearbyNpcs[ActorID]
                    self:OnInteractNpcBegin()
                end
                local Actor = self:GetActor(ActorID)
                if Actor then
                    local Item = NpcInteractItemModule.DistanceInteractEntranceItem.new(Actor, Actor:GetNpcDisplayName(), 
                        SelectAction, Enum.Enum_InteractType.Normal, NpcInfo.Distance)
                    table.insert(Items, Item)
                else
                    G.log:error("PlayerUIInteractComponent", "RefreshInteractUI, ActorID(%s) not exist", ActorID)
                end
            end
        end
    end

    -- 收集交互物
    if #self.InteractItems > 0 then
        for _, Item in ipairs(self.InteractItems) do
            if Item then
                table.insert(Items, Item)
            end
        end
    end

    local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    if #Items > 0 then
        -- 若不允许排序和有控制默认条目需求, 则处理为独占
        if self.bNotSort or self.ForceIndex ~= 1 then
            InteractVM:OpenInteractSelectionForPickup(self.InteractItems, self.bNotSort, self.ForceIndex)
            return
        end
        InteractVM:OpenInteractSelectionForPickup(Items)
    else
        InteractVM:CloseInteractSelection()
    end
end

-- 开始交互NPC, 此处禁止用户其他操作, 播放Camera动画, 播放叙事对话
function PlayerUIInteractComponent:OnInteractNpcBegin()
    local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    if InteractVM then
        InteractVM:CloseInteractSelection()
    end

    self:GetOwner():SendMessage("EventOnDialogueBegin")
    local Actor = self:GetActor(self.CurInteractNpc.ActorId)
    if Actor then
        local NarrateDialogue = self:GetNpcNarrateDialogue(Actor)
        if NarrateDialogue and (#NarrateDialogue > 0) then
            self:DialogueWithNPC(NarrateDialogue, 1, self.PlayHelloContent)
        else
            self:PlayHelloContent()
        end
        -- 通知NPC进入交互状态
        self:Server_InteractNpcBegin(self.CurInteractNpc.ActorId)
    else
        G.log:error("PlayerUIInteractComponent", "OnInteractNpcBegin actor(%s) not exist", self.CurInteractNpc.ActorId)
        self:FroceCloseSituation()
    end
end

-- 问候阶段
function PlayerUIInteractComponent:PlayHelloContent()
    -- NPC打招呼，然后呼出二级交互列表
    local UI = UIManager:OpenUI(UIDef.UIInfo.UI_Situation_Chat)
    local Actor = self:GetActor(self.CurInteractNpc.ActorId)
    if not Actor then
        G.log:error("PlayerUIInteractComponent", "PlayHelloContent actor(%s) not exist", self.CurInteractNpc.ActorId)
        self:FroceCloseSituation()
        return
    end

    local NpcName = Actor:GetNpcDisplayName()
    local HelloContent = self.CurInteractNpc.HelloContent
    UI:DisplaySituationChat(NpcName, '', HelloContent, nil, function ()
        local ui = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_InteractPickup.UIName)
        if not ui then
            self:BeginSituation()
        end
    end, true)
end

-- 问候语结束, 开始二级交互, 收集NPC数据, 组织条目
function PlayerUIInteractComponent:BeginSituation()
    local Items = {}

    if not self.CurInteractNpc or not self:GetActor(self.CurInteractNpc.ActorId) then
        G.log:error("PlayerUIInteractComponent", "BeginSituation CurInteractNpc(%s) not exist", self.CurInteractNpc)
        self:FroceCloseSituation()
        return
    end

    -- npc动态交互选项（任务对话等）
    if self.CurInteractNpc and self.CurInteractNpc.Items then
        for _, Item in pairs(self.CurInteractNpc.Items) do
            table.insert(Items, Item)
        end
    end

    -- npc配置的交互选项（静态配置在excel和蓝图中）
    local SituationItems = self:MakeSituationItems()
    if SituationItems then
        for _, Item in pairs(SituationItems) do
            table.insert(Items, Item)
        end
    end

    local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    if InteractVM then
        InteractVM:CloseInteractSelection()
        InteractVM:OpenSituationSelection(Items)
    end
end

-- 离开二级交互, 播放Camera动画, 恢复角色操作, 恢复目标NPC动作
function PlayerUIInteractComponent:ReleaseSituation()
    local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    if InteractVM then
        InteractVM:CloseInteractSelection()
    end

    self:GetOwner():SendMessage("EventOnDialogueEnd")

    UIManager:CloseUIByName(UIDef.UIInfo.UI_Situation_Chat.UIName)

    if self.CurInteractNpc then
        self:Server_InteractNpcEnd(self.CurInteractNpc.ActorId)
    end
    self.CurInteractNpc = nil
end

-- 构建情景条目
function PlayerUIInteractComponent:MakeSituationItems()
    local Actor = self:GetActor(self.CurInteractNpc.ActorId)
    if not Actor then
        G.log:error("PlayerUIInteractComponent", "MakeSituationItems actor(%s) not exist", self.CurInteractNpc.ActorId)
        return
    end
    local NpcID = Actor:GetNpcId()
    local InteractItems = Actor.NpcBehaviorComponent:GetInteractItems()
    if #InteractItems == 0 then
        return
    end

    local Items = {}
    for i = 1, #InteractItems do
        local ItemID = InteractItems[i]
        local Info = NpcInteractData[ItemID]
        local SelectAction = function()
            -- 每个情景条目, 先关列表, 再显示对话
            local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
            if InteractVM then
                InteractVM:CloseInteractSelection()
            end
            if Info.Tpye == NpcInteractDef.Dialogue then
                self:HandleSituationDialogue(Info.DialogueId)
            elseif Info.Tpye == NpcInteractDef.UIEvent then
                self:HandleSituationUIEvent(ItemID, Info.Parm)
            elseif Info.Tpye == NpcInteractDef.Exit then
                self:HandleSituationExit(Info.DialogueId)
            else
                G.log:error("PlayerUIInteractComponent", "MakeSituationItems Error Type(%s)", Info.Tpye)
            end
        end

        local Item = NpcInteractItemModule.DefaultDialogueItem.new(0, Info.Name, SelectAction, Info.Icon)
        table.insert(Items, Item)
    end

    return Items
end

-- 情景交互: 对话
function PlayerUIInteractComponent:HandleSituationDialogue(DialogueId)
    local Data = DialogueData[DialogueId]
    local FinishCallback = function(self)
        local Actor = self:GetActor(self.CurInteractNpc.ActorId)
        if not Actor then
            G.log:error("PlayerUIInteractComponent", "HandleSituationDialogue actor(%s) not exist", self.CurInteractNpc.ActorId)
            self:FroceCloseSituation()
            return
        end

        self:BeginSituation()

        local NpcName = Actor:GetNpcDisplayName()
        local HelloContent = self.CurInteractNpc.HelloContent
        local UI = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_Situation_Chat.UIName)
        if not UI then
            UI = UIManager:OpenUI(UIDef.UIInfo.UI_Situation_Chat)
        end
        UI:DisplaySituationChat(NpcName, '', HelloContent, nil, nil, true)
    end
    self:DialogueWithNPC(Data, 1, FinishCallback)
end

-- 情景交互: UI事件
function PlayerUIInteractComponent:HandleSituationUIEvent(InteractID, EventParam)
    -- EventParam第一个参数是UI名，后面的参数是打开UI界面的参数
    local Data = NpcInteractData[InteractID]
    local Param = LuaUtils.DeepCopy(EventParam)
    local UIName = Param[1]
    local UIInfo = UIDef.UIInfo[UIName]
    table.remove(Param, 1)
    UIManager:OpenUI(UIInfo, Param)

    if Data.IsHideNPC == NpcInteractDef.HideNPC then
        local PlayerController = SubsystemUtils.GetMutableActorSubSystem(self):GetHostPlayerController()
        PlayerController.NPCHideComponent:HideInteractNPC()
    elseif Data.IsHideNPC == NpcInteractDef.HideRangeNPC then
        local PlayerController = SubsystemUtils.GetMutableActorSubSystem(self):GetHostPlayerController()
        PlayerController.NPCHideComponent:HideNearbyNPC()
    end

    -- UI事件无视Data.Return参数，一定会结束当前对话
    self:ReleaseSituation()
end

-- 情景交互: 离开
function PlayerUIInteractComponent:HandleSituationExit(DialogueId)
    local Data = DialogueData[DialogueId]
    local FinishCallback = function(self)
        self:ReleaseSituation()
    end
    if not Data or not(#Data > 0) then
        FinishCallback(self)
    else
        self:DialogueWithNPC(Data, 1, FinishCallback)
    end
end

function PlayerUIInteractComponent:DialogueWithNPC(DialogueData, DialogueIndex, FinishCallback)
    -- ISSUE: 目前这个实现，不支持Branch对话
    local UI = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_Situation_Chat.UIName)
    if not UI then
        UI = UIManager:OpenUI(UIDef.UIInfo.UI_Situation_Chat)
    end

    local Actor = self:GetActor(self.CurInteractNpc.ActorId)
    if not Actor then
        G.log:error("PlayerUIInteractComponent", "DialogueWithNPC Actor(%s) not exist", self.CurInteractNpc.ActorId)
        self:FroceCloseSituation()
        return
    end

    local DialogName = DialogueData[DialogueIndex].owner == 0 and self:GetPlayerName() or Actor:GetNpcDisplayName()
    UI:DisplaySituationChat(DialogName, '', DialogueData[DialogueIndex].Detail, function ()
        if DialogueIndex < #DialogueData then
            self:DialogueWithNPC(DialogueData, DialogueIndex + 1, FinishCallback)
        else
            FinishCallback(self)
        end
    end)
end

-- 取得该Npc的问候语
function PlayerUIInteractComponent:GetNpcHelloContent(Npc)
    -- NPC DialogueComponentl蓝图的DefaultDialogueId属性优先级高于NPC配置表中的default_dialogue
    if Npc.DialogueComponent and Npc.DialogueComponent.DefaultDialogueId ~= 0 then
        return DialogueData[Npc.DialogueComponent.DefaultDialogueId][1].Detail
    end
    -- 如果有配功能对话, 则问候语为功能对话
    local FunctionDialogue = self:GetNpcFunctionDialogue(Npc)
    if FunctionDialogue then
        return FunctionDialogue
    end
   
    -- 如果没有功能对话, 有配叙事对话, 则问候语为叙事对话的最后一句
    local Narrate = self:GetNpcNarrateDialogue(Npc)
    if Narrate and Narrate[#Narrate] and Narrate[#Narrate].Detail then
        return Narrate[#Narrate].Detail
    end
    return 'Hello'
end

-- 获取Npc功能对话
function PlayerUIInteractComponent:GetNpcFunctionDialogue(Npc)
    local NpcID = Npc:GetNpcId()
    if NpcID == nil or NpcID == 0 then
        return nil
    end
    local DialogueID = NpcBaseData[NpcID].default_dialogue
    if DialogueID ~= nil then
        return DialogueData[DialogueID][1].Detail
    else
        return nil
    end
end

-- 获取Npc叙事对话
function PlayerUIInteractComponent:GetNpcNarrateDialogue(Npc)
    local Data = DialogueData[Npc.DialogueComponent.DefaultNarrativeDialogueId]
    if Data and #Data > 0 then
        local tb = {}
        for k, v in pairs(Data) do
            tb[k] = v
        end
        return tb
    else
        return nil
    end
end

---(临时)获取主角名字
function PlayerUIInteractComponent:GetPlayerName()
    return 'Player'
end

function PlayerUIInteractComponent:FroceCloseSituation()
    self.CurrentDialogue = nil
    local DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
    if DialogueVM then
        DialogueVM:CloseDialog()
    end
    local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    InteractVM:CloseDialogSelection()
    self.CurInteractNpc = nil
    self:CloseInteractUI()
end

-- client
function PlayerUIInteractComponent:GetActor(ActorID)
    if self.actor:IsClient() then
        return SubsystemUtils.GetMutableActorSubSystem(self):GetClientMutableActor(ActorID)
    else
        return SubsystemUtils.GetMutableActorSubSystem(self):GetActor(ActorID)
    end
end

function PlayerUIInteractComponent:Server_InteractNpcBegin_RPC(ActorID)
    local NpcActor = self:GetActor(ActorID)
    if NpcActor then
        NpcActor.DialogueComponent:OnDialogueBegin()
    end
end

function PlayerUIInteractComponent:Server_InteractNpcEnd_RPC(ActorID)
    local NpcActor = self:GetActor(ActorID)
    if NpcActor then
        NpcActor.DialogueComponent:OnDialogueEnd()
    end
end

return PlayerUIInteractComponent
