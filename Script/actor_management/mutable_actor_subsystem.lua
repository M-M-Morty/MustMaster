--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local utils = require("common.utils")
local G = require("G")
local EdUtils = require("common.utils.ed_utils")
local BPConst = require ("common.const.blueprint_const")
local GlobalActorConst = require ("common.const.global_actor_const")
local SubsystemUtils = require("common.utils.subsystem_utils")
local MutableActorOperations = require("actor_management.mutable_actor_operations")
local EventDispatcher = require("common.event_dispatcher")
local LevelTable = require("common.data.level_data").data
local CProtobufUnreal = require("cprotobuf_unreal")

local EventType = {
    ActorCreateOrDestroy = 1,
}

local MutableActorRecord = UnLua.Class()

function MutableActorRecord:New(ActorID)
    local Object = {}
    setmetatable(Object, self)
    self.__index = self
    Object:Initialize(ActorID)
    return Object
end

function MutableActorRecord:Initialize(ActorID)
    self.ActorID = ActorID
    self.Actor = nil
end

function MutableActorRecord:GetActorID()
    return self.ActorID
end

function MutableActorRecord:SetActor(Actor)
    self.Actor = Actor
end

function MutableActorRecord:GetActor()
    return self.Actor
end

function MutableActorRecord:IsSpawned()
    return self.Actor ~= nil
end

local MutableActorQueueItemBase = Class()
function MutableActorQueueItemBase:ctor(ActorID)
    self.ActorID = ActorID
end

function MutableActorQueueItemBase:Run(MutableActorManager, Dispatcher)
end

local MutableActorQueueItemRegister = Class(MutableActorQueueItemBase)
function MutableActorQueueItemRegister:ctor(ActorID, Tags)
    Super(self).ctor(self, ActorID)
    self.Tags = Tags
end

function MutableActorQueueItemRegister:Run(MutableActorManager, Dispatcher)
    local RegisterInfoClass = UE.UObject.Load(BPConst.MutableActorRegisterInfo)
    local RegisterInfo = RegisterInfoClass()
    RegisterInfo.ActorID = self.ActorID
    RegisterInfo.Dispatcher = Dispatcher
    if self.Tags ~= nil then
        RegisterInfo.Tags = self.Tags
    end
    MutableActorManager:RegisterMutableActor(self.ActorID, RegisterInfo)
end


local MutableActorQueueItemUnRegister = Class(MutableActorQueueItemBase)
function MutableActorQueueItemUnRegister:ctor(ActorID)
    Super(self).ctor(self, ActorID)
end

function MutableActorQueueItemUnRegister:Run(MutableActorManager, Dispatcher)
    MutableActorManager:UnregisterMutableActor(self.ActorID)
end





---@type BP_MutableActorSubsystem_C
local MutableActorSubsystem = UnLua.Class()

function MutableActorSubsystem:GetRealLevelName()
    local GameplayEntitySubsystem = SubsystemUtils.GetGameplayEntitySubsystem(self)
    local DungeonID = GameplayEntitySubsystem:K2_GetDungeonID()
    G.log:debug("xaelpeng", "MutableActorSubsystem:GetRealLevelName %s", DungeonID)
    if LevelTable[DungeonID] == nil then
        return ""
    end
    local EditorConfig = LevelTable[DungeonID].editor_config
    if EditorConfig == nil then
        return ""
    end
    return EditorConfig

    -- local datatable_path = "/Game/Blueprints/DataTables/Scenedata.Scenedata"
    -- local AssetData = UE.UObject.Load(datatable_path)
    -- local ScenePaths = UE.UDataTableFunctionLibrary.GetDataTableColumnAsString(AssetData, "ScenePath")
    -- local ChildMap = UE.UDataTableFunctionLibrary.GetDataTableColumnAsString(AssetData, "ChildMap")
    -- local ParentLevelName = {}
    -- local CurLevelName = UE.UGameplayStatics.GetCurrentLevelName(self.GameWorld)
    -- for Ind = 1, ScenePaths:Length() do
    --     local ScenePath = ScenePaths:Get(Ind)
    --     local ScenePathData = EdUtils:SplitPath(tostring(ScenePath), ".")
    --     if #ScenePathData == 2 then
    --         local SceneName = ScenePathData[2]
    --         local ChildMapData = ChildMap:Get(Ind)
    --         if ChildMapData ~= "" then
    --             ChildMapData = EdUtils:SplitPath(ChildMapData:sub(2,-2), ",")
    --             for _,ChildMapPath in ipairs(ChildMapData) do
    --                 ChildMapPath = ChildMapPath:sub(2, -2)
    --                 local ChildMapNameData = EdUtils:SplitPath(ChildMapPath, ".")
    --                 if #ChildMapNameData == 2 then
    --                     ParentLevelName[ChildMapNameData[2]] = SceneName
    --                 end
    --             end
    --         end
    --     end
    -- end
    -- if ParentLevelName[CurLevelName] then
    --     CurLevelName = ParentLevelName[CurLevelName]
    -- end
    -- return CurLevelName
end

function MutableActorSubsystem:InitializeScript()
    -- server
    self.GameWorld = self:GetWorldScript()
    self.EditorWorld = UE.UHiEdRuntime.GetEditorWorld()
    self.data_root = None
    self.data_table = {}
    self.EditorID2SuiteDir = {}
    self.MutableActors = {}
    self.LimitedActors = UE.TSet(UE.FString)
    self.TagsToActors = {}
    self.ActorsToTags = {}
    self.ActorSpawnOrDestroyEventDispatcher = EventDispatcher.new()
    self.ActorSpawnOrDestroyEventDispatcher:Initialize()

    self.MutableActorRegisterQueue = {} -- cache for simulate async rpc

    -- client
    self.ClientMutableActors = {}
    self.ClientActorSpawnOrDestroyEventDispatcher = EventDispatcher.new()
    self.ClientActorSpawnOrDestroyEventDispatcher:Initialize()

    -- self.LimitedActorsMaxValue = 1

    -- server
    self.MissionSubscribers = {}
end

function MutableActorSubsystem:PostInitializeScript()
    
    G.log:debug("xaelpeng", "MutableActorSubsystem:PostInitializeScript %s", tostring(UE.UHiUtilsFunctionLibrary.IsSSInstanceGame()))
    local GameplayEntitySubsystem = SubsystemUtils.GetGameplayEntitySubsystem(self)
    local DungeonID = GameplayEntitySubsystem:K2_GetDungeonID()

    local LevelData = LevelTable[DungeonID]
    local ContentDir = UE.UKismetSystemLibrary.GetProjectContentDirectory()
    local RootList = ContentDir
    if LevelData ~= nil then
        local resource_path = LevelData.resource_path
        local resource_data = EdUtils:SplitPath(resource_path, "/")
        if #resource_data > 1 and resource_data[2]:sub(1,2) == "CP" then -- deal with CP Test
            local level_name = self:GetRealLevelName()
            local CheckRoot = ContentDir .. resource_data[2] .. "/Data/SceneEditorData/" .. level_name
            if UE.UBlueprintPathsLibrary.DirectoryExists(CheckRoot) then
                RootList = ContentDir..resource_data[2].."/"
            end
        end
    end
    self.data_root = RootList .. "Data/SceneEditorData/"

    if UE.UHiUtilsFunctionLibrary.IsSSInstanceGame() then
        self:LoadFiles(self.data_root)
        self:InitActors(self.data_root)
        self:InitTags()
        
        self.bIsGidAllocateApplying = false
        self.AllocateApplyCallbackList = {}
        self.__NextFreeGid = 0
        self.__LastGid = -1
        --self:ApplyAllocateFreeGidSection()
    end
end

function MutableActorSubsystem:OnWorldBeginPlayScript()
    G.log:debug("xaelpeng", "MutableActorSubsystem:OnWorldBeginPlayScript %s",
        UE.UHiUtilsFunctionLibrary.IsSSInstanceGame())
    if UE.UHiUtilsFunctionLibrary.GetSSInstanceType() == UE.ESSInstanceType.Game and UE.UHiUtilsFunctionLibrary.IsLocalAdapter() then
        SubsystemUtils.GetGameplayEntitySubsystem(self).OnLocalModeActorLoadedFinishDelegate:Add(self, self.OnLocalModeActorLoadedFinish)
    end

end

function MutableActorSubsystem:OnLocalModeActorLoadedFinish()
    self:ProcessNewEditorActors()
end

function MutableActorSubsystem:ReceiveTick(DeltaTime)
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    if MutableActorManager ~= nil then
        local Queue = self.MutableActorRegisterQueue
        self.MutableActorRegisterQueue = {}
        for Index = 1, #Queue do
            local QueueItem = Queue[Index]
            QueueItem:Run(MutableActorManager, self)
        end
    end
end

function MutableActorSubsystem:CreateMutableActorRecord(ActorID)
    local ActorRecord = MutableActorRecord:New(ActorID)
    self.MutableActors[ActorID] = ActorRecord
    return ActorRecord
end

function MutableActorSubsystem:OnGlobalActorRegister(GlobalActorName)
    if GlobalActorName == GlobalActorConst.MutableActorManager then
        self:OnMutableActorManagerReadyScript()
    elseif GlobalActorName == GlobalActorConst.MissionManager then
        self:OnMissionManagerReady()
    end
end

function MutableActorSubsystem:OnMutableActorManagerReadyScript()
    G.log:debug("xaelpeng", "MutableActorSubsystem:OnMutableActorManagerReadyScript %s", 
        UE.UHiUtilsFunctionLibrary.IsSSInstanceGame())
    if UE.UHiUtilsFunctionLibrary.IsSSInstanceGame() then
        local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
        if MutableActorManager ~= nil then
            for ActorID, ActorRecord in pairs(self.MutableActors) do
                if ActorRecord:IsSpawned() then
                    self:RegisterSpawnedMutableActorOnManager(ActorRecord)
                else
                    self:RegisterUnspawnedMutableActorOnManager(ActorID)
                end
            end
        end
    end
end

function MutableActorSubsystem:DeinitializeScript()
    G.log:debug("xaelpeng", "MutableActorSubsystem:DeinitializeScript %s", UE.UHiUtilsFunctionLibrary.IsSSInstanceGame())
    if UE.UHiUtilsFunctionLibrary.IsSSInstanceGame() then
        self:ClearSpawnedActors()
        self:ClearOctree()
        self:ClearJsonObjectWrapperDatas()
    end
end

-- used for runtime tag
function MutableActorSubsystem:GetMutableActorRuntimeTags(Actor)
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local MutableActorComponent = Actor:GetComponentByClass(MutableActorComponentClass)
    if MutableActorComponent then
        return MutableActorComponent:GetRuntimeTags()
    end
    return nil
end

function MutableActorSubsystem:GetMutableActorPosition(ActorID)
    if self.MutableActors[ActorID] ~= nil then
        local ActorRecord = self.MutableActors[ActorID]
        if ActorRecord:IsSpawned() then
            local Actor = ActorRecord:GetActor()
            if Actor.TrackTargetAnchor == nil then
                return Actor:K2_GetActorLocation()
            else
                return Actor.TrackTargetAnchor:K2_GetComponentLocation()
            end
            
        end
    end
    local PropertyMessage = SubsystemUtils.GetGameplayEntitySubsystem(self):GetActorProperties(ActorID)
    if PropertyMessage == nil then
        return nil
    end
    if PropertyMessage.Transform then
        return CProtobufUnreal.ReadTransformFromPbMessage(PropertyMessage.Transform)
    end
    return nil
end

function MutableActorSubsystem:RegisterMutableActor(ActorID, Actor)
    G.log:debug("xaelpeng", "MutableActorSubsystem:RegisterMutableActor ActorID: %s", ActorID)
    if self.MutableActors[ActorID] == nil then
        self:CreateMutableActorRecord(ActorID)
    end
    local ActorRecord = self.MutableActors[ActorID]
    if ActorRecord:IsSpawned() then
        G.log:error("xaelpeng", "MutableActorSubsystem:RegisterMutableActor ActorID: %s has already spawned", ActorID)
        return
    end
    ActorRecord:SetActor(Actor)
    self.ActorSpawnOrDestroyEventDispatcher:Broadcast(ActorID, true)
    self:RegisterSpawnedMutableActorOnManager(ActorRecord)
end

function MutableActorSubsystem:RegisterSpawnedMutableActorOnManager(ActorRecord)
    local ActorID = ActorRecord:GetActorID()
    local Actor = ActorRecord:GetActor()
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    if MutableActorManager ~= nil then
        local Tags = self:GetMutableActorRuntimeTags(Actor)
        G.log:debug("xaelpeng", "MutableActorSubsystem ActorID:%s Tags:%d", ActorID, Tags:Length())
        table.insert(self.MutableActorRegisterQueue, MutableActorQueueItemRegister.new(ActorID, Tags))
    end
end

function MutableActorSubsystem:UnregisterMutableActor(ActorID)
    G.log:debug("xaelpeng", "MutableActorSubsystem:UnregisterMutableActor ActorID: %s", ActorID)
    if self.MutableActors[ActorID] == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:UnregisterMutableActor ActorID: %s not found in local records", ActorID)
        return
    end
    local ActorRecord = self.MutableActors[ActorID]
    if not ActorRecord:IsSpawned() then
        G.log:debug("xaelpeng", "MutableActorSubsystem:UnregisterMutableActor ActorID: %s not spawned", ActorID)
        return
    end
    ActorRecord:SetActor(nil)
    self.ActorSpawnOrDestroyEventDispatcher:Broadcast(ActorID, false)
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    if MutableActorManager ~= nil then
        table.insert(self.MutableActorRegisterQueue, MutableActorQueueItemUnRegister.new(ActorID))
    end
end

function MutableActorSubsystem:RegisterUnspawnedMutableActorOnManager(ActorID)
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    if MutableActorManager ~= nil then
        MutableActorManager:RegisterNotLoadedMutableActor(ActorID, self)
    end
end

function MutableActorSubsystem:DispatchRegisterEventToActor(ActorID, EventID, EventRegisterInfo)
    G.log:debug("xaelpeng", "MutableActorSubsystem:DispatchRegisterEventToActor ActorID: %s EventID: %s EventType: %s", ActorID,
        EventID, EventRegisterInfo.EventType)
    if self.MutableActors[ActorID] == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:DispatchRegisterEventToActor ActorID: %s not found in local records", ActorID)
        return
    end
    local ActorRecord = self.MutableActors[ActorID]
    if not ActorRecord:IsSpawned() then
        G.log:debug("xaelpeng", "MutableActorSubsystem:DispatchRegisterEventToActor ActorID: %s not spawned", ActorID)
        return
    end
    local MutableActorComponentClass = BPConst.GetMutableActorComponentClass()
    local MutableActorComponent = ActorRecord:GetActor():GetComponentByClass(MutableActorComponentClass)
    if MutableActorComponent == nil then
        G.log:debug("xaelpeng", "MutableActorSubsystem:DispatchRegisterEventToActor ActorID: %s not has MutableActorComponent", ActorID)
        return
    end
    MutableActorComponent:RegisterEvent(EventID, EventRegisterInfo)
end

function MutableActorSubsystem:DispatchUnregisterEventToActor(ActorID, EventID)
    G.log:debug("xaelpeng", "MutableActorSubsystem:DispatchUnregisterEventToActor ActorID: %s EventID: %s", ActorID, EventID)
    if self.MutableActors[ActorID] == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:DispatchUnregisterEventToActor ActorID: %s not found in local records", ActorID)
        return
    end
    local ActorRecord = self.MutableActors[ActorID]
    if not ActorRecord:IsSpawned() then
        G.log:debug("xaelpeng", "MutableActorSubsystem:DispatchUnregisterEventToActor ActorID: %s not spawned", ActorID)
        return
    end
    local MutableActorComponentClass = BPConst.GetMutableActorComponentClass()
    local MutableActorComponent = ActorRecord:GetActor():GetComponentByClass(MutableActorComponentClass)
    if MutableActorComponent == nil then
        G.log:debug("xaelpeng",
            "MutableActorSubsystem:DispatchUnregisterEventToActor ActorID: %s not has MutableActorComponent", ActorID)
        return
    end
    MutableActorComponent:UnregisterEvent(EventID)
end

function MutableActorSubsystem:DispatchActionToActor(ActorID, ActionID, ActionInfo)
    G.log:debug("xaelpeng", "MutableActorSubsystem:DispatchActionToActor ActorID: %s ActionID: %s ActionType: %s",
        ActorID, ActionID, ActionInfo.ActionType)
    if self.MutableActors[ActorID] == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:DispatchActionToActor ActorID: %s not found in local records", ActorID)
        return
    end
    local ActorRecord = self.MutableActors[ActorID]
    if not ActorRecord:IsSpawned() then
        G.log:debug("xaelpeng", "MutableActorSubsystem:DispatchActionToActor ActorID: %s not spawned", ActorID)
        return
    end
    local MutableActorComponentClass = BPConst.GetMutableActorComponentClass()
    local MutableActorComponent = ActorRecord:GetActor():GetComponentByClass(MutableActorComponentClass)
    if MutableActorComponent == nil then
        G.log:debug("xaelpeng",
            "MutableActorSubsystem:DispatchActionToActor ActorID: %s not has MutableActorComponent", ActorID)
        return
    end
    MutableActorComponent:RunAction(ActionID, ActionInfo)
end

function MutableActorSubsystem:LoadFiles(data_root)
    local JsonArray = UE.UHiEdRuntime.FindFilesRecursive(data_root, "*.json", true, false)
    for Ind = 1, JsonArray:Length() do
        local JsonFile = JsonArray:Get(Ind)
        self:SetDataTable(data_root, JsonFile)
    end
end

function MutableActorSubsystem:SetDataTable(data_root, JsonFile)
    --local relative_path = JsonFile:sub(data_root:len() + 1)
    local data = EdUtils:SplitPath(JsonFile, "/")
    local level_name, suite_dir_name, file_name_wit_ext = data[#data-2], data[#data-1], data[#data]
    local ext = EdUtils:GetFileExtension(file_name_wit_ext)
    self:InitDataTable(level_name, suite_dir_name)
    local suite_id = file_name_wit_ext:sub(1, #file_name_wit_ext - #ext)
    self:InitSuiteDataTable(level_name, suite_dir_name, suite_id)
end

function MutableActorSubsystem:InitDataTable(level_name, suite_dir_name)
    if self.data_table[level_name] == nil then
        self.data_table[level_name] = {}
    end
    if self.data_table[level_name][suite_dir_name] == nil then
        self.data_table[level_name][suite_dir_name] = {}
    end
end

function MutableActorSubsystem:InitSuiteDataTable(level_name, suite_dir_name, suite_id)
    if self.data_table[level_name][suite_dir_name][suite_id] == nil then
        self.data_table[level_name][suite_dir_name][suite_id] = true
        if self.EditorID2SuiteDir[level_name] == nil then
            self.EditorID2SuiteDir[level_name] = {}
        end
        self.EditorID2SuiteDir[level_name][suite_id] = suite_dir_name
    end
end


function MutableActorSubsystem:InitActors(data_root)
    local level_name = self:GetRealLevelName()
    G.log:debug("xaelpeng", "MutableActorSubsystem:InitActors level_name %s", level_name)
    if self.data_table[level_name] ~= nil then
        local map_data_table = self.data_table[level_name]
        self:InitSuiteData(data_root, map_data_table)
    end
end

function MutableActorSubsystem:InitSuiteData(data_root, map_data_table)
    local level_name = self:GetRealLevelName()
    G.log:debug("xaelpeng", "MutableActorSubsystem:InitSuiteData level_name %s", level_name)
    self:ClearJsonObjectWrapperDatas()
    self:ClearOctree()
    for suite_dir_name, suite_dir_data in pairs(map_data_table) do
        for suite_id,_ in pairs(suite_dir_data) do
            local json_path = table.concat({data_root, level_name, '/', suite_dir_name, '/', suite_id, '.json'})
            local editor_id = suite_id
            self:LoadFileToJsonWrapper(editor_id, json_path)
            if self:ContainsInJsonObjectWrapperDatas(editor_id) then
                local JsonWrapper = self:GetJsonObjectWrapper(editor_id)
                local Source = UE.UHiEdRuntime.GetStringField(JsonWrapper, "source")
                if not EdUtils:IsWayPoint(Source) then
                    local trans = UE.UHiEdRuntime.GetTransformField(JsonWrapper, "transform")
                    local translation = trans.translation
                    self:AddElementToOctree(editor_id, translation)
                end
            else
                G.log:error("xaelpeng", "MutableActorSubsystem:InitSuiteData Duplicated %s %s", editor_id, json_path)
            end
        end
    end
end

function MutableActorSubsystem:InitTags()
    local Result = self:FindAllElementsFromOctree()
    for Ind = 1, Result:Length() do
        local ActorID = Result[Ind]
        if self:ContainsInJsonObjectWrapperDatas(ActorID) then
            local JsonWrapper = self:GetJsonObjectWrapper(ActorID)
            -- EditorTags will be deprecated in the future, replaced by EditorGameplayTags
            local EditorTags = EdUtils:GetUE5Property(nil, JsonWrapper, "EditorTags")
            if EditorTags ~= nil then
                for _, Tag in ipairs(EditorTags) do
                    if self.TagsToActors[Tag] == nil then
                        self.TagsToActors[Tag] = {}
                    end
                    table.insert(self.TagsToActors[Tag], ActorID)
                end
                self.ActorsToTags[ActorID] = EditorTags
            end

            local EditorGameplayTags = EdUtils:GetUE5Property(nil, JsonWrapper, "EditorGameplayTags")
            if EditorGameplayTags ~= nil then
                local TagNames = {}
                for _, Tag in ipairs(EditorGameplayTags) do
                    local TagName = Tag.TagName
                    if self.TagsToActors[TagName] == nil then
                        self.TagsToActors[TagName] = {}
                    end
                    table.insert(self.TagsToActors[TagName], ActorID)
                    table.insert(TagNames, TagName)
                end
                self.ActorsToTags[ActorID] = TagNames
            end
        end
    end
end

function MutableActorSubsystem:GetMutableActorTags(ActorID)
    return self.ActorsToTags[ActorID]
end

function MutableActorSubsystem:GetTagMutableActors(Tag)
    return self.TagsToActors[Tag]
end

-- for local test
function MutableActorSubsystem:ProcessNewEditorActors()
    local AddedCount = 0
    local IngoredCount = 0

    local Result = self:FindAllElementsFromOctree()
    -- local bFilterEnabled = self:IsFilterByLandscapeEnabled()
    -- local BoundingBoxList = self:GetLandscapeBoundingBoxList()
    -- bFilterEnabled = false
    -- BoundingBoxList:Clear()
    -- local IsLocationInBounding = function(Location, BoundingBox)
    --     if Location.X >= BoundingBox.Min.X and Location.X <= BoundingBox.Max.X and Location.Y >= BoundingBox.Min.Y and Location.Y <= BoundingBox.Max.Y then
    --         return true
    --     end
    --     return false
    -- end

    -- G.log:debug("xaelpeng", "MutableActorSubsystem:ProcessNewEditorActors bFilterEnabled:%s BoxLength:%s", bFilterEnabled, BoundingBoxList:Length())

    for Ind = 1, Result:Length() do
        local ActorID = Result[Ind]
        
        local JsonWrapper = self:GetJsonObjectWrapper(ActorID)
        local Transform = UE.UHiEdRuntime.GetTransformField(JsonWrapper, "transform")
        -- local Location, _, _ = UE.UKismetMathLibrary.BreakTransform(Transform)
        local bShouldAdd = true
        if UE.UHiBlueprintFunctionLibrary.IsInClientLoadRegion(self:GetWorld(), Transform) == false then
            bShouldAdd = false
        end
        -- if bFilterEnabled then
        --     bShouldAdd = false
        --     for BoundingBoxIndex = 1, BoundingBoxList:Length() do
        --         local BoundingBox = BoundingBoxList:GetRef(BoundingBoxIndex)
        --         if IsLocationInBounding(Location, BoundingBox) then
        --             bShouldAdd = true
        --             break
        --         end
        --     end
        -- end
        if bShouldAdd then
            AddedCount = AddedCount + 1
            SubsystemUtils.GetGameplayEntitySubsystem(self):OnSyncEntityDataInLocalMode(ActorID)
        else
            G.log:debug("xaelpeng", "MutableActorSubsystem:ProcessNewEditorActors Actor Ignored:%s Location:%s", ActorID, Location)
            IngoredCount = IngoredCount + 1
        end

    end
    G.log:debug("xaelpeng", "MutableActorSubsystem:ProcessNewEditorActors Added:%d Ignored:%d", AddedCount, IngoredCount)
end

function MutableActorSubsystem:OnSyncLevelActorScript(ActorID, ActorCreateType)
    G.log:debug("xaelpeng", "MutableActorSubsystem:OnSyncLevelActorScript ActorID:%s CreateType:%s", ActorID, ActorCreateType)
    local JsonWrapper = nil
    if self:ContainsInJsonObjectWrapperDatas(ActorID) then
        JsonWrapper = self:GetJsonObjectWrapper(ActorID)
    end
    local Subsystem = SubsystemUtils.GetGameplayEntitySubsystem(self)
    local PropertyMessage = SubsystemUtils.GetGameplayEntitySubsystem(self):GetActorProperties(ActorID)
    self:CreateMutableActorRecord(ActorID)
    if ActorCreateType == UE.EActorCreateType.ActorCreateType_Editor then
        if JsonWrapper == nil then
            G.log:error("xaelpeng", "MutableActorSubsystem:SpawnActorInDatabaseCache ActorID %s is ActorCreateType_Editor but JsonWrapper not found.ignore", ActorID)
            return nil
        end
        if not self:ShouldLoadEditorActor(JsonWrapper, PropertyMessage) then
            -- do not load now
            self:RegisterUnspawnedMutableActorOnManager(ActorID)
            return nil
        end
        if PropertyMessage ~= nil then
            -- spawn saved editor actor
            return self:SpawnSavedEditorActor(ActorID, JsonWrapper, PropertyMessage)
        else
            -- spawn new editor actor
            return self:SpawnNewEditorActor(ActorID, JsonWrapper)
        end
    elseif ActorCreateType == UE.EHiActorCreateType.ActorCreateType_Runtime then
        if PropertyMessage ~= nil then
            -- spawn saved runtime actor
            return self:SpawnSavedRuntimeActor(ActorID, PropertyMessage)
        else
             G.log:error("xaelpeng", "MutableActorSubsystem:SpawnActorInDatabaseCache ActorID %s ActorCreateType_Runtime without Valid SaveData", ActorID)
        end
    elseif ActorCreateType == UE.EHiActorCreateType.ActorCreateType_Fixed then
        if PropertyMessage ~= nil then
            -- spawn saved fixed actor
            return self:SpawnSavedFixedActor(ActorID, PropertyMessage)
        else
            return self:SpawnNewFixedActor(ActorID)
        end
    end
end

-- 创建关卡配置中存在的，且有存盘数据的Actor
function MutableActorSubsystem:SpawnSavedEditorActor(ActorID, JsonWrapper, PropertyMessage)
    ActorID = tostring(ActorID)
    local Class = self:GetClassFromJsonWrapper(JsonWrapper)
    if Class == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:SpawnSavedEditorActor ActorID %s Class is nil", ActorID)
        return
    end

    local SpawnParameters = UE.FActorSpawnParameters()
    SpawnParameters.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
    local ExtraData = {}
    local ExtraSpawnOp = function(Actor)
        -- 携带编辑器数据的 component
        self:AddEditorDataComponentToActor(Actor, ActorID, JsonWrapper)
        -- local ActorTypeID = self:GetTypeIDFromJsonWrapper(JsonWrapper)
        self:AddMutableActorComponentToActor(Actor, ActorID, nil) -- ActorTypeID, UE.EActorCreateType.ActorCreateType_Editor, nil, nil)
    end
    local Transform = nil
    if PropertyMessage.Transform ~= nil then
        Transform = CProtobufUnreal.ReadTransformFromPbMessage(PropertyMessage.Transform)
    else
        Transform = UE.UHiEdRuntime.GetTransformField(JsonWrapper, "transform")
    end
    local Actor = GameAPI.SpawnActor(self.GameWorld, Class, Transform, SpawnParameters, ExtraData, ExtraSpawnOp)
    G.log:debug("xaelpeng", "MutableActorSubsystem:SpawnSavedEditorActor ActorID %s Actor %s", ActorID, Actor:GetName())
    -- Actor:SetReplicates(true)
    self:AddToSpawnedActors(ActorID, Actor)
    return Actor
end

-- 创建关卡配置中存在的，但没有存盘数据的Actor
function MutableActorSubsystem:SpawnNewEditorActor(ActorID, JsonWrapper)
    local Transform = UE.UHiEdRuntime.GetTransformField(JsonWrapper, "transform")
    -- if UE.UHiBlueprintFunctionLibrary.IsInClientLoadRegion(self:GetWorld(), Transform) == false then
    --     return
    -- end
    ActorID = tostring(ActorID)
    local Class = self:GetClassFromJsonWrapper(JsonWrapper)
    if Class == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:SpawnNewEditorActor ActorID %s Class is nil", ActorID)
        return
    end
    local SpawnParameters = UE.FActorSpawnParameters()
    SpawnParameters.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
    local ExtraData = {}
    local ExtraSpawnOp = function(Actor)
        -- 携带编辑器数据的 component
        self:AddEditorDataComponentToActor(Actor, ActorID, JsonWrapper)
        local GameplayEntitySubsystem = SubsystemUtils.GetGameplayEntitySubsystem(self)
        local PropertyMessage = GameplayEntitySubsystem:CreateMessage("HiGame.MutableActor")
        PropertyMessage.ActorID = ActorID
        PropertyMessage.ActorTypeID = self:GetTypeIDFromJsonWrapper(JsonWrapper)
        PropertyMessage.CreateType = UE.EActorCreateType.ActorCreateType_Editor
        self:AddMutableActorComponentToActor(Actor, ActorID, PropertyMessage) -- ActorTypeID, UE.EActorCreateType.ActorCreateType_Editor, nil, nil)
    end
    

    local Actor = GameAPI.SpawnActor(self.GameWorld, Class, Transform, SpawnParameters, ExtraData, ExtraSpawnOp)
    G.log:debug("xaelpeng", "MutableActorSubsystem:SpawnNewEditorActor ActorID %s Actor %s Class %s", ActorID, Actor:GetName(), Class)
    --Actor:SetReplicates(true)
    self:AddToSpawnedActors(ActorID, Actor)
    return Actor
end

-- 创建关卡配置中不存在的（即游戏逻辑运行时新增的），且有存盘数据的Actor
function MutableActorSubsystem:SpawnSavedRuntimeActor(ActorID, PropertyMessage)
    ActorID = tostring(ActorID)
    local Class = UE.UObject.Load(PropertyMessage.Class)
    if Class == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:SpawnSavedRuntimeActor ActorID %s Class is nil", ActorID)
        return
    end

    local SpawnParameters = UE.FActorSpawnParameters()
    SpawnParameters.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
    local ExtraData = {}
    local ExtraSpawnOp = function(Actor)
        -- local ActorTypeID = PropertyMessage.ActorTypeID
        self:AddMutableActorComponentToActor(Actor, ActorID, nil) -- ActorTypeID, UE.EActorCreateType.ActorCreateType_Runtime, nil, nil)
    end
    local Transform = CProtobufUnreal.ReadTransformFromPbMessage(PropertyMessage.Transform)
    local Actor = GameAPI.SpawnActor(self:GetWorld(), Class, Transform, SpawnParameters, ExtraData, ExtraSpawnOp)
    G.log:debug("xaelpeng", "MutableActorSubsystem:SpawnSavedRuntimeActor ActorID %s Actor %s", ActorID, Actor:GetName())
    -- Actor:SetReplicates(true)
    self:AddToSpawnedActors(ActorID, Actor)
end


-- Warning 会自动分配一个唯一可用的ActorID给Actor，可能存在没有可用ActorID的情况，此时会申请分配，所以可能是异步逻辑。
---@param Callback function 回调，参数为创建完成的Actor
-- 创建关卡配置中不存在的（即游戏逻辑运行时新增的），但没有存盘数据的Actor
function MutableActorSubsystem:AsyncSpawnNewRuntimeActor(Class, Transform, Callback, Tag, Lifetime)
    -- if UE.UHiBlueprintFunctionLibrary.IsInClientLoadRegion(self:GetWorld(), Transform) == false then
    --     return
    -- end
    
    local ActorID = self:GetNextFreeActorGid()
    if ActorID == nil then
        local InnerCallback = function()
            ActorID = self:GetNextFreeActorGid()
            local Actor = self:SpawnNewRuntimeActor_Internal(Class, Transform, ActorID, Tag, Lifetime)
            if Callback then
                Callback(Actor)
            end
        end
        self:ApplyAllocateFreeGidSection(InnerCallback)
        return nil
    end
    local Actor = self:SpawnNewRuntimeActor_Internal(Class, Transform, ActorID, Tag, Lifetime)
    if Callback then
        Callback(Actor)
    end
    return Actor
end

-- 创建关卡配置中不存在的（即游戏逻辑运行时新增的），但没有存盘数据的Actor
function MutableActorSubsystem:SpawnNewRuntimeActor(Class, Transform, Spawner, Tag, Lifetime)
    -- if UE.UHiBlueprintFunctionLibrary.IsInClientLoadRegion(self:GetWorld(), Transform) == false then
    --     return
    -- end
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local SpawnerComponent = Spawner:GetComponentByClass(MutableActorComponentClass)
    if SpawnerComponent == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:SpawnNewRuntimeActor Spawner %s do not have MutableActorComponent", Spawner:GetName())
        return
    end
    local ActorID = tostring(SpawnerComponent:GenerateChildActorID())
    
    return self:SpawnNewRuntimeActor_Internal(Class, Transform, ActorID, Tag, Lifetime)
end

function MutableActorSubsystem:SpawnNewRuntimeActor_Internal(Class, Transform, ActorID, Tag, Lifetime)
    -- if UE.UHiBlueprintFunctionLibrary.IsInClientLoadRegion(self:GetWorld(), Transform) == false then
    --     return
    -- end
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)

    -- TODO use ActorTypeID instead of Class
    local ActorTypeID = 0
    -- TODO: bLimited should be set by ActorTypeID
    -- if bLimited then
    --     self.LimitedActors:Add(ActorID)
    -- end
    self:CreateMutableActorRecord(ActorID)
    local SpawnParameters = UE.FActorSpawnParameters()
    SpawnParameters.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
    local ExtraData = {}
    local ExtraSpawnOp = function(Actor)
        local GameplayEntitySubsystem = SubsystemUtils.GetGameplayEntitySubsystem(self)
        local PropertyMessage = GameplayEntitySubsystem:CreateMessage("HiGame.MutableActor")
        PropertyMessage.ActorID = ActorID
        PropertyMessage.ActorTypeID = ActorTypeID
        PropertyMessage.Class = UE.UKismetSystemLibrary.GetPathName(Class)
        PropertyMessage.CreateType = UE.EActorCreateType.ActorCreateType_Runtime
        if Tag ~= nil and Tag ~= "" then
            -- Check tag type(GameplayTag), Convert to String type
            if type(Tag) == "userdata" then
                Tag = Tag.TagName
            end
            PropertyMessage.Tags:Add(Tag)
        end
        if Lifetime ~= nil and Lifetime > 0 then
            PropertyMessage.RemoveTime = math.ceil(Lifetime + os.time())
        end
        self:AddMutableActorComponentToActor(Actor, ActorID, PropertyMessage) -- ActorTypeID, UE.EActorCreateType.ActorCreateType_Runtime, Tag, nil)
    end
    local Actor = GameAPI.SpawnActor(self:GetWorld(), Class, Transform, SpawnParameters, ExtraData, ExtraSpawnOp)
    G.log:debug("xaelpeng", "MutableActorSubsystem:SpawnNewRuntimeActor ActorID %s Actor %s", ActorID, Actor:GetName())
    -- Actor:SetReplicates(true)
    self:AddToSpawnedActors(ActorID, Actor)
    if self.LimitedActors:Length() > self.LimitedActorsMaxValue then
        local MutableActorComponent = Actor:GetComponentByClass(MutableActorComponentClass)
        MutableActorComponent:NotifyAutoDestroyByLimit()
    end
    return Actor
end

-- 创建全局固定的且有存盘数据的Actor
function MutableActorSubsystem:SpawnSavedFixedActor(ActorID, PropertyMessage)
    local Class = UE.UHiGlobalActorLibrary.GetGlobalActorClass(ActorID)
    if Class == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:SpawnSavedFixedActor ActorID %s Class is nil", ActorID)
        return
    end
    local SpawnParameters = UE.FActorSpawnParameters()
    SpawnParameters.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
    local ExtraData = {}
    local ExtraSpawnOp = function(Actor)
        -- local ActorTypeID = PropertyMessage.ActorTypeID
        self:AddMutableActorComponentToActor(Actor, ActorID, nil) -- ActorTypeID, UE.EActorCreateType.ActorCreateType_Fixed, nil, nil)
    end
    local Transform = CProtobufUnreal.ReadTransformFromPbMessage(PropertyMessage.Transform)
    local Actor = GameAPI.SpawnActor(self:GetWorld(), Class, Transform, SpawnParameters, ExtraData, ExtraSpawnOp)
    G.log:debug("xaelpeng", "MutableActorSubsystem:SpawnSavedFixedActor ActorID %s Actor %s", ActorID, Actor:GetName())
    -- Actor:SetReplicates(true)
    self:AddToSpawnedActors(ActorID, Actor)
end

-- 创建全局固定的，但没有存盘数据的Actor
function MutableActorSubsystem:SpawnNewFixedActor(ActorID)
    local Class = UE.UHiGlobalActorLibrary.GetGlobalActorClass(ActorID)
    if Class == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:SpawnNewFixedActor ActorID %s Class is nil", ActorID)
        return
    end
    local SpawnParameters = UE.FActorSpawnParameters()
    SpawnParameters.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
    local ExtraData = {}
    local ExtraSpawnOp = function(Actor)
        local GameplayEntitySubsystem = SubsystemUtils.GetGameplayEntitySubsystem(self)
        local PropertyMessage = GameplayEntitySubsystem:CreateMessage("HiGame.MutableActor")
        PropertyMessage.ActorID = ActorID
        PropertyMessage.CreateType = UE.EActorCreateType.ActorCreateType_Fixed
        self:AddMutableActorComponentToActor(Actor, ActorID, PropertyMessage) -- ActorTypeID, UE.EActorCreateType.ActorCreateType_Fixed, nil, nil)
    end
    local Actor = GameAPI.SpawnActor(self:GetWorld(), Class, UE.FTransform.Identity, SpawnParameters, ExtraData, ExtraSpawnOp)
    G.log:debug("xaelpeng", "MutableActorSubsystem:SpawnNewFixedActor ActorID %s Actor %s", ActorID, Actor:GetName())
    -- Actor:SetReplicates(true)
    self:AddToSpawnedActors(ActorID, Actor)
    return Actor
end

function MutableActorSubsystem:DestroyLocalRuntimeActor(ActorID, Actor)
    G.log:debug("xaelpeng", "MutableActorSubsystem:DestroyLocalRuntimeActor ActorID:%s Name:%s", ActorID, Actor:GetName())
    local PropertyMessage = SubsystemUtils.GetGameplayEntitySubsystem(self):GetActorProperties(ActorID)
    if PropertyMessage == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Remove ActorID %s not found in DatabaseCache", ActorID)
        return
    end
    if PropertyMessage.CreateType ~= UE.EHiActorCreateType.ActorCreateType_Runtime then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Remove ActorID %s cannot remove CreateType is %s", ActorID, PropertyMessage.CreateType)
        return
    end
    Actor:K2_DestroyActor()
end

function MutableActorSubsystem:RemoveRuntimeActor(ActorID)
    self.LimitedActors:Remove(ActorID)
end

function MutableActorSubsystem:GetClassFromJsonWrapper(JsonWrapper)
    local Source = UE.UHiEdRuntime.GetStringField(JsonWrapper, "source")
    local SourceData = utils.StrSplit(Source, "@")
    local Ori_Source = nil

    if SourceData[1] == "editor_test_actors" then -- CP Test BP
        Ori_Source = SourceData[3]
        Source = Ori_Source .. "_C"
    else
        local TabName = SourceData[1]
        local TabData = require("common.data." .. TabName).data
        local LuaID = tonumber(SourceData[2])
        if TabData[LuaID] then
            local resource_ref = TabData[LuaID]["resource_ref"]
            Ori_Source = EdUtils:GetUE5ObjectPath(resource_ref)
            Source = Ori_Source .. "_C"
        else
            G.log:error("xaelpeng", "MutableActorSubsystem:GetClassFromJsonWrapper -> LuaId %s not in table %s", LuaID, TabName)
        end
    end
    if Ori_Source ~= nil then
        local Class = UE.UClass.Load(Source)
        if Class == nil then -- StaticMeshActor
            Class = UE.UObject.Load(Ori_Source)
        end
        return Class
    else
        G.log:error("xaelpeng", "MutableActorSubsystem:GetClassFromJsonWrapper -> Source is nil")
    end
end

function MutableActorSubsystem:GetTypeIDFromJsonWrapper(JsonWrapper)
    local TypeID = UE.UHiEdRuntime.GetNumberField(JsonWrapper, "LuaID")
    return TypeID
end

function MutableActorSubsystem:ShouldLoadEditorActor(JsonWrapper, PropertyMessage)
    local AutoSpawn = EdUtils:GetUE5Property(nil, JsonWrapper, "AutoSpawn")
    if AutoSpawn == nil or AutoSpawn == true then
        if PropertyMessage ~= nil then
            if PropertyMessage.bUnloaded then
                return false
            else
                return true
            end
        else
            return true
        end
    elseif AutoSpawn == false then
        if PropertyMessage ~= nil then
            if PropertyMessage.bLoaded and not PropertyMessage.bUnloaded then
                return true
            else
                return false
            end
        else
            return false
        end
    else
        G.log:error("xaelpeng", "MutableActorSubsystem:ShouldLoadEditorActor invalid autospawn value:%s", AutoSpawn)
        return false
    end
end

function MutableActorSubsystem:AddEditorDataComponentToActor(Actor, ActorID, JsonWrapper)
    local HiEditorDataCompClass = UE.UClass.Load(BPConst.HiEditorDataComp)
    local HiEditorDataComp = Actor:AddComponentByClass(HiEditorDataCompClass, false, UE.FTransform.Identity, false)
    --HiEditorDataComp.EditorId = ActorID
    --HiEditorDataComp.JsonString = UE.UHiEdRuntime.EncodeJsonToString(JsonWrapper)
    local level_name = self:GetRealLevelName()
    local EditorID = tostring(ActorID)
    if self.EditorID2SuiteDir[level_name] and self.EditorID2SuiteDir[level_name][ActorID] then
        EditorID = tostring(ActorID).."@"..tostring(self.EditorID2SuiteDir[level_name][ActorID])
    end
    --Actor.JsonObject = JsonWrapper
    Actor.EditorID = EditorID
    --Actor.JsonString = UE.UHiEdRuntime.EncodeJsonToString(JsonWrapper)
    --EdUtils:SetUE5Property(Actor, JsonWrapper, false, ActorID)
end

function MutableActorSubsystem:AddMutableActorComponentToActor(Actor, ActorID, PropertyMessage) -- ActorTypeID, CreateType, Tag, Lifetime)
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local MutableActorComponent = Actor:AddComponentByClass(MutableActorComponentClass, false, UE.FTransform.Identity, true)
    MutableActorComponent:SetActorID(ActorID)
    if PropertyMessage ~= nil then
        MutableActorComponent:SetInitialPropertyMessage(PropertyMessage)
    end
    Actor:FinishAddComponent(MutableActorComponent, false, UE.FTransform.Identity)
    return MutableActorComponent
end

function MutableActorSubsystem:AddMutableActorComponentToPlayer(Actor, ActorID, PropertyMessage) -- ActorTypeID, CreateType, Tag, Lifetime)
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local MutableActorComponent = Actor:AddComponentByClass(MutableActorComponentClass, false, UE.FTransform.Identity, true)
    MutableActorComponent:SetActorID(ActorID)
    MutableActorComponent:SetIsPlayer()
    if PropertyMessage ~= nil then
        MutableActorComponent:SetInitialPropertyMessage(PropertyMessage)
    end
    Actor:FinishAddComponent(MutableActorComponent, false, UE.FTransform.Identity)
    return MutableActorComponent
end


function MutableActorSubsystem:DoMutableActorOp_Load(OperationID, ActorID)
    G.log:debug("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Load OperationID:%d ActorID:%s", OperationID, ActorID)
    ActorID = tostring(ActorID)
    if self.MutableActors[ActorID] == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Load ActorID: %s not found in local records", ActorID)
        return
    end
    local ActorRecord = self.MutableActors[ActorID]
    if ActorRecord:IsSpawned() then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Load ActorID %s is spawned", ActorID)
        -- Actor已经Load了，这里需要Confirm
        local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
        MutableActorManager:ConfirmOperationOnMutableActorByID(ActorID, OperationID)
        return
    end
    if not self:ContainsInJsonObjectWrapperDatas(ActorID) then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Load ActorID %s not found in JsonObjectWrapperDatas", ActorID)
        return
    end
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:ConfirmOperationOnMutableActorByID(ActorID, OperationID)

    local JsonWrapper = self:GetJsonObjectWrapper(ActorID)
    local PropertyMessage = SubsystemUtils.GetGameplayEntitySubsystem(self):GetActorProperties(ActorID)
    local Actor
    if PropertyMessage ~= nil then
        -- spawn saved editor actor
        Actor = self:SpawnSavedEditorActor(ActorID, JsonWrapper, PropertyMessage)
    else
        -- spawn new editor actor
        Actor = self:SpawnNewEditorActor(ActorID, JsonWrapper)
    end
end

function MutableActorSubsystem:DoMutableActorOp_Unload(OperationID, ActorID)
    G.log:debug("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Unload OperationID:%d ActorID:%s", OperationID, ActorID)
    if self.MutableActors[ActorID] == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Unload ActorID: %s not found in local records", ActorID)
        return
    end
    local ActorRecord = self.MutableActors[ActorID]
    if not ActorRecord:IsSpawned() then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Unload ActorID %s not spawned", ActorID)
        -- Actor没有被Load，这里需要Confirm
        local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
        MutableActorManager:ConfirmOperationOnMutableActorByID(ActorID, OperationID)
        return
    end
    local PropertyMessage = SubsystemUtils.GetGameplayEntitySubsystem(self):GetActorProperties(ActorID)
    if PropertyMessage == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Unload ActorID %s not found in DatabaseCache", ActorID)
        return
    end
    if PropertyMessage.CreateType ~= UE.EHiActorCreateType.ActorCreateType_Editor then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Unload ActorID %s with JsonWrapper but CreateType is %s", ActorID, PropertyMessage.CreateType)
        return
    end

    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:ConfirmOperationOnMutableActorByID(ActorID, OperationID)

    local Actor = ActorRecord:GetActor()
    Actor:K2_DestroyActor()
end

function MutableActorSubsystem:DoMutableActorOp_Remove(OperationID, ActorID)
    G.log:debug("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Remove OperationID:%d ActorID:%s", OperationID, ActorID)
    if self.MutableActors[ActorID] == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Remove ActorID: %s not found in local records", ActorID)
        return
    end
    local ActorRecord = self.MutableActors[ActorID]
    if not ActorRecord:IsSpawned() then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Remove ActorID %s not spawned", ActorID)
        return
    end
    local PropertyMessage = SubsystemUtils.GetGameplayEntitySubsystem(self):GetActorProperties(ActorID)
    if PropertyMessage == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Remove ActorID %s not found in DatabaseCache", ActorID)
        return
    end
    if PropertyMessage.CreateType ~= UE.EHiActorCreateType.ActorCreateType_Runtime then
        G.log:error("xaelpeng", "MutableActorSubsystem:DoMutableActorOp_Remove ActorID %s cannot remove CreateType is %s", ActorID, PropertyMessage.CreateType)
        return
    end

    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:ConfirmOperationOnMutableActorByID(ActorID, OperationID)

    local Actor = ActorRecord:GetActor()
    self:DestroyLocalRuntimeActor(ActorID, Actor)
end

function MutableActorSubsystem:GetActor(ActorID)
    if self.MutableActors[ActorID] ~= nil then
        return self.MutableActors[ActorID]:GetActor()
    end
end

-- args:
--- callback desc
---@param ActorID
---@param bSpawnOrDestroy
function MutableActorSubsystem:ListenActorSpawnOrDestroy(ActorID, Listener, Callback)
    local InnerCallback = function (bSpawnOrDestroy)
        Callback(Listener, ActorID, bSpawnOrDestroy)
    end
    local CallbackObj = {
        identity = Callback,
        callback = InnerCallback,
    }
    self.ActorSpawnOrDestroyEventDispatcher:AddListener(ActorID, Listener, CallbackObj)
end

function MutableActorSubsystem:UnlistenActorSpawnOrDestroy(ActorID, Listener, Callback)
    self.ActorSpawnOrDestroyEventDispatcher:RemoveListener(ActorID, Listener, Callback)
end

--- client actor management ------------------------------------------------------------------------------------------------------------------
function MutableActorSubsystem:RegisterClientMutableActor(ActorID, Actor)
    self.ClientMutableActors[ActorID] = Actor
    self.ClientActorSpawnOrDestroyEventDispatcher:Broadcast(EventType.ActorCreateOrDestroy, ActorID, true)
end

function MutableActorSubsystem:UnregisterClientMutableActor(ActorID, Actor)
    self.ClientMutableActors[ActorID] = nil
    self.ClientActorSpawnOrDestroyEventDispatcher:Broadcast(EventType.ActorCreateOrDestroy, ActorID, false)
end

function MutableActorSubsystem:GetClientMutableActor(ActorID)
    return self.ClientMutableActors[ActorID]
end

-- args:
--- callback desc
---@param ActorID
---@param bSpawnOrDestroy
function MutableActorSubsystem:ListenClientActorSpawnOrDestroy(Listener, Callback)
    local InnerCallback = function(ActorID, bSpawnOrDestroy)
        Callback(Listener, ActorID, bSpawnOrDestroy)
    end
    local CallbackObj = {
        identity = Callback,
        callback = InnerCallback,
    }
    self.ClientActorSpawnOrDestroyEventDispatcher:AddListener(EventType.ActorCreateOrDestroy, Listener, CallbackObj)
end

function MutableActorSubsystem:UnlistenClientActorSpawnOrDestroy(Listener, Callback)
    self.ClientActorSpawnOrDestroyEventDispatcher:RemoveListener(EventType.ActorCreateOrDestroy, Listener, Callback)
end


--- mission system support -------------------------------------------------------------------------------------------------------------------
function MutableActorSubsystem:RegisterMissionSubscriber(ActorID, Subscriber)
    self.MissionSubscribers[ActorID] = Subscriber
    self:RegisterSubscriberOnMissionManager(ActorID)
end

function MutableActorSubsystem:UnregisterMissionSubscriber(ActorID)
    self.MissionSubscribers[ActorID] = nil
    local MissionManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MissionManager)
    if MissionManager ~= nil then
        MissionManager:GetDataBPComponent():RemoveSubscriber(ActorID)
    end
end

function MutableActorSubsystem:RegisterSubscriberOnMissionManager(ActorID)
    local MissionManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MissionManager)
    if MissionManager ~= nil then
        local RegisterInfoClass = UE.UObject.Load(BPConst.MutableActorRegisterInfo)
        local RegisterInfo = RegisterInfoClass()
        RegisterInfo.ActorID = ActorID
        RegisterInfo.Dispatcher = self
        MissionManager:GetDataBPComponent():AddSubscriber(RegisterInfo)
    end
end

function MutableActorSubsystem:OnMissionManagerReady()
    G.log:debug("xaelpeng", "MutableActorSubsystem:OnMissionManagerReady %s", UE.UHiUtilsFunctionLibrary.IsSSInstanceGame())
    if UE.UHiUtilsFunctionLibrary.IsSSInstanceGame() then
        for ActorID, _ in pairs(self.MissionSubscribers) do
            self:RegisterSubscriberOnMissionManager(ActorID)
        end
    end
end

function MutableActorSubsystem:GetMissionAvatarComponentByID(ActorID)
    if self.MissionSubscribers[ActorID] == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:GetMissionAvatarComponentByID Actor:%s not found", ActorID)
        return nil
    end
    local MissionAvatarComponentClass = BPConst.GetMissionAvatarComponentClass()
    local MissionAvatarComponent = self.MissionSubscribers[ActorID]:GetComponentByClass(MissionAvatarComponentClass)
    if MissionAvatarComponent == nil then
        G.log:error("xaelpeng", "MutableActorSubsystem:GetMissionAvatarComponentByID Actor:%s not has MissionAvatarComponent", ActorID)
        return nil
    end
    return MissionAvatarComponent
end

function MutableActorSubsystem:SyncMissionRecords(ActorID, MissionRecordMap)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncMissionRecords(MissionRecordMap)
    end
end

function MutableActorSubsystem:SyncActiveMissions(ActorID, MissionDataList)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncActiveMissions(MissionDataList)
    end
end

function MutableActorSubsystem:SyncMissionActs(ActorID, MissionActDataList)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncMissionActs(MissionActDataList)
    end
end

function MutableActorSubsystem:SyncAddMissionAct(ActorID, MissionActID, MissionActData)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncAddMissionAct(MissionActID, MissionActData)
    end
end

function MutableActorSubsystem:SyncAddActiveMission(ActorID, MissionID, MissionData)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncAddActiveMission(MissionID, MissionData)
    end
end

function MutableActorSubsystem:SyncRemoveActiveMission(ActorID, MissionID, bFinish)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncRemoveActiveMission(MissionID, bFinish)
    end
end

function MutableActorSubsystem:SyncAddActiveMissionEvent(ActorID, MissionID, MissionEventData)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncAddActiveMissionEvent(MissionID, MissionEventData)
    end
end

function MutableActorSubsystem:SyncRemoveActiveMissionEvent(ActorID, MissionID, MissionEventID)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncRemoveActiveMissionEvent(MissionID, MissionEventID)
    end
end

function MutableActorSubsystem:SyncUpdateActiveMissionEventProgress(ActorID, MissionID, MissionEventID, Progress)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncUpdateActiveMissionEventProgress(MissionID, MissionEventID, Progress)
    end
end

function MutableActorSubsystem:SyncUpdateActiveMissionEventTrackTarget(ActorID, MissionID, MissionEventID, RawEventID, TrackTargetList)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncUpdateActiveMissionEventTrackTarget(MissionID, MissionEventID, RawEventID, TrackTargetList)
    end
end


function MutableActorSubsystem:NotifyMissionGroupStateChange(ActorID, MissionIdentifier, State)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:NotifyMissionGroupStateChange(MissionIdentifier, State)
    end
end

function MutableActorSubsystem:NotifyMissionActStateChange(ActorID, MissionIdentifier, State)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:NotifyMissionActStateChange(MissionIdentifier, State)
    end
end

function MutableActorSubsystem:NotifyMissionStateChange(ActorID, MissionIdentifier, State)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:NotifyMissionStateChange(MissionIdentifier, State)
    end
end

function MutableActorSubsystem:NotifyMissionEventStateChange(ActorID, MissionIdentifier, MissionEventID, State)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:NotifyMissionEventStateChange(MissionIdentifier, MissionEventID, State)
    end
end

function MutableActorSubsystem:SyncAddMissionActDialogueRecord(ActorID, MissionActID, DialogueRecord)
    local MissionAvatarComponent = self:GetMissionAvatarComponentByID(ActorID)
    if MissionAvatarComponent ~= nil then
        MissionAvatarComponent:SyncAddMissionActDialogueRecord(MissionActID, DialogueRecord)
    end
end

function MutableActorSubsystem:GetHostPlayer()
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        -- FIXME(hangyuewang): 服务端目前只适用于单人环境
        return G.GetPlayerCharacter(UE.UHiUtilsFunctionLibrary.GetGWorld(), 0)
    else
        return G.GetPlayerCharacter(UE.UHiUtilsFunctionLibrary.GetGWorld(), 0)
    end
end

function MutableActorSubsystem:GetHostPlayerController()
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        -- FIXME(hangyuewang): 服务端目前只适用于单人环境
        return UE.UGameplayStatics.GetPlayerController(UE.UHiUtilsFunctionLibrary.GetGWorld(), 0)
    else
        return UE.UGameplayStatics.GetPlayerController(UE.UHiUtilsFunctionLibrary.GetGWorld(), 0)
    end
end

function MutableActorSubsystem:GetHostPlayerState()
    return self:GetHostPlayerController().PlayerState
end

MutableActorSubsystem.RunTimeActorGidType = "RunTimeActor"
MutableActorSubsystem.RunTimeActorGidApplyNum = 100
--还剩10%个可用的gid时就重新申请
MutableActorSubsystem.PreApplyRemainFreeNum = MutableActorSubsystem.RunTimeActorGidApplyNum * 0.1

function MutableActorSubsystem:ApplyAllocateFreeGidSection(Callback)
    if Callback then
        table.insert(self.AllocateApplyCallbackList, Callback)
    end
    if self.bIsGidAllocateApplying then
        return
    end
    self.bIsGidAllocateApplying = true
    
    local MSConfig = require("micro_service.ms_config")
    local RPCStubFactory = require("micro_service.rpc_stub_factory")
    local IRPCLog = require("micro_service.irpc.irpc_log")
    local AsyncGidRPCStub = RPCStubFactory:GetRPCStub(MSConfig.GidRPCServiceName)
    
    local function AsyncCallback(Context, Response)
        self.bIsGidAllocateApplying = false
        
        local Status = Context:GetStatus()
        if (not Status:OK()) then
            IRPCLog.LogError("MutableActorSubsystem ApplyAllocateFreeGidSection failed2, frame: %d, func: %d, msg: %s",
                    Status:GetFrameworkRetCode(), Status:GetFuncRetCode(), Status:ErrorMessage())
            return
        end
        self.__LastGid = Response.GidEnd 
        self.__NextFreeGid = Response.GidEnd - Response.Num + 1
        IRPCLog.LogInfoFormat("MutableActorSubsystem ApplyAllocateFreeGidSection succ, self.__NextFreeGid:%d self.__LastGid:%d", self.__NextFreeGid, self.__LastGid)
        
        for Index, ApplyCallback in ipairs(self.AllocateApplyCallbackList) do
            if Index <= Response.Num then
                ApplyCallback()
            else
                --正常情况下，应该不会走到这里，不会出现一次申请不够用的情况
                IRPCLog.LogErrorFormat("MutableActorSubsystem ApplyAllocateFreeGidSection succ, but apply gid num:%d, need num:%s", 
                        Response.Num, #self.AllocateApplyCallbackList)
                
                self.AllocateApplyCallbackList = {table.unpack(self.AllocateApplyCallbackList, Index)}
                --不够用重新申请一次
                self:ApplyAllocateFreeGidSection()
                break
            end
        end
    end

    -- 防止一次性申请不够用，直接乘2
    if MutableActorSubsystem.RunTimeActorGidApplyNum <= #self.AllocateApplyCallbackList then
        MutableActorSubsystem.RunTimeActorGidApplyNum = MutableActorSubsystem.RunTimeActorGidApplyNum * 2
    end
    local ApplyGidRequest = {
        GidType = MutableActorSubsystem.RunTimeActorGidType,
        Num = MutableActorSubsystem.RunTimeActorGidApplyNum
    }

    local bResult, ClientStatus = AsyncGidRPCStub:AsyncCallRPCFunction("GetGid", ApplyGidRequest, AsyncCallback)
    if not bResult or not ClientStatus:OK() then
        IRPCLog.LogError("MutableActorSubsystem ApplyAllocateFreeGidSection fail1, result: %s, frame: %d, func: %d, msg: %s",
                bResult, ClientStatus:GetFrameworkRetCode(), ClientStatus:GetFuncRetCode(), ClientStatus:ErrorMessage())
        return
    end
end

--获取下一个可用的gid
function MutableActorSubsystem:GetNextFreeActorGid()
    if self.__NextFreeGid == 0 or self.__NextFreeGid > self.__NextFreeGid then
        self:ApplyAllocateFreeGidSection()
        return nil
    end
    local FreeGid = self.__NextFreeGid
    self.__NextFreeGid = self.__NextFreeGid + 1
    -- 提前申请一批
    if self.__NextFreeGid >= self.__LastGid - self.PreApplyRemainFreeNum then
        self:ApplyAllocateFreeGidSection()
    end
    return FreeGid
end



return MutableActorSubsystem
