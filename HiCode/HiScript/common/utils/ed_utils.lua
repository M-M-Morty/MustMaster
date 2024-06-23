require "UnLua"
local table = require("table")
local G = require("G")
local json = require("thirdparty.json")
local BPConst = require("common.const.blueprint_const")
local SubsystemUtils = require("common.utils.subsystem_utils")
local DataTableUtils = require("common.utils.data_table_utils")

local AreaAbilityTypeDataTablePath = "/Game/Data/Datatable/DT_AreaAbilityType.DT_AreaAbilityType"
local AreaAbilityTypeDataStructurePath = "/Game/Data/Struct/S_AreaAbilityType.S_AreaAbilityType"

local EdUtils = {}
EdUtils.mapEdActors = {}
EdUtils.AreaAbilityPrefix = "AreaAbility@"

function EdUtils:SplitPath(inputstr, sep)
    if type(inputstr) ~= "string" then
        return {}
    end
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function EdUtils:GetFileExtension(url)
    return url:match("^.+(%..+)$")
end

function EdUtils:IsWayPoint(source)
    return source == "puzzle_initial_data@10100"
end

function EdUtils:IsCP001(source)
    return source == "puzzle_initial_data@20000"
end

function EdUtils:IsFaithClock(source)
    return source == "puzzle_initial_data@20014"
end

function EdUtils:GetEditorID(full_json_path)
    local data = self:SplitPath(full_json_path, "/")
    local suite_name = data[#data]
    local editor_id = tonumber(self:SplitPath(suite_name, ".")[1])
    return editor_id
end

function EdUtils:GetSuiteActorLabel(suite_dir_name, suite_id)
    return suite_dir_name .. '@' .. suite_id
end

function EdUtils:GetGroupActorLabel(group_id)
    local data = self:SplitPath(group_id, "_")
    return group_id .. '@' .. data[#data]
end

function EdUtils:GetUE5ObjectPath(DataTableID)
    if DataTableID:sub(1,5) == "/Game" then -- 兼容 DataTable 里边没有配置，导出直接存的路径
        return DataTableID
    end
    --local AssetReg = UE.UAssetRegistryHelpers.GetAssetRegistry()
    --local AssetData = AssetReg:GetAssetByObjectPath(datatable_path, false)
    local Data = DataTableUtils.GetDataTableRow(DataTableUtils.ResourceIndexMainTable, DataTableID)
    if Data then
        return tostring(Data.Asset)
    end
    return ""
end

function EdUtils:GetUE5ObjectClass(DataTableID, bStruct)
    local Path = self:GetUE5ObjectPath(DataTableID)
    if Path == nil or Path == "" then
        G.log:error("xaelpeng", "GetUE5ObjectClass DataTableID %s not exist", DataTableID)
        return nil
    end
    if not bStruct then
        Path = Path .. "_C"
        local Class = UE.UClass.Load(Path)
        return Class
    else
        local Class = UE.UObject.Load(Path)
        return Class
    end
end

EdUtils.EDIT_UE5_Type = {Set="Set",Array="Array", Map="Map", Transform="Transform", Actor="Actor",
                       Object="Object", Vector="Vector", Boolean="Boolean", Float="Float", String="String",
                       Int="Int", Unknow="Unknow", Enum="Enum", SplineNodeLocation="SplineNodeLocation", ChildActorsTransform="ChildActorsTransform", UE5Comps="UE5Comps",
                       GameplayTag = "GameplayTag",HiBTSwitchInfo = "HiBTSwitchInfo", NAME="NAME", StructBase="StructBase"}
function EdUtils:CheckConActor(T)
    return T == self.EDIT_UE5_Type.Actor
end

function EdUtils:MergeActorIDList(ActorIDList, rActorIDList)
    if rActorIDList and #rActorIDList > 0 then
        for ind = 1, #rActorIDList do
            table.insert(ActorIDList, rActorIDList[ind])
        end
    end
    return ActorIDList
end

function EdUtils:GetUE5PropertyBase(Actor, Object, PropertyName, PropertyValue, PropertyDefaultValue)
    local PropertyDataType = UE.UHiEdRuntime.GetUE5DataType(PropertyValue)
    local PropertyDataType_data = self:SplitPath(PropertyDataType, "@")
    if PropertyDataType == self.EDIT_UE5_Type.Array or PropertyDataType == self.EDIT_UE5_Type.Set or PropertyDataType == self.EDIT_UE5_Type.SplineNodeLocation then
        local PropertyDefaultValue0 = nil
        if PropertyDefaultValue and PropertyDataType == self.EDIT_UE5_Type.Array then
            PropertyDefaultValue:AddDefault()
            PropertyDefaultValue0 = PropertyDefaultValue:Get(1)
            PropertyDefaultValue:Clear()
        elseif PropertyDefaultValue and PropertyDataType == self.EDIT_UE5_Type.Set then
            PropertyDefaultValue:AddDefault()
            local Arr = PropertyDefaultValue:ToArray()
            PropertyDefaultValue0 = Arr:Get(1)
            PropertyDefaultValue:Clear()
        end
        local Array = UE.UHiEdRuntime.GetUE5DataArray(PropertyValue)
        local Data, ActorIDList = {}, {}
        for Ind = 1, Array:Length() do
            local JsonWrapper = Array[Ind]
            local Val, rActorIDlist = self:GetUE5PropertyBase(Actor, Object, PropertyName, JsonWrapper, PropertyDefaultValue0)
            ActorIDList = self:MergeActorIDList(ActorIDList, rActorIDlist)
            if Val then
                table.insert(Data, Val)
            end
        end
        return Data, ActorIDList
    elseif PropertyDataType == self.EDIT_UE5_Type.Map or PropertyDataType == self.EDIT_UE5_Type.ChildActorsTransform then
        local PropertyDefaultKeyValue, PropertyDefaultValueValue = nil, nil
        if PropertyDefaultValue and PropertyDataType == self.EDIT_UE5_Type.Map then
            PropertyDefaultValue:AddDefault()
            PropertyDefaultKeyValue = PropertyDefaultValue:Keys()[1]
            PropertyDefaultValueValue = PropertyDefaultValue:Find(PropertyDefaultKeyValue)
            PropertyDefaultValue:Clear()
        end
        local PropertyValues = HiBlueprintFunctionLibrary.GetJsonObjectField(PropertyValue, "Value")
        local PropertyNames = UE.TArray(UE.FString)
        local Succ = UE.UJsonBlueprintFunctionLibrary.GetFieldNames(PropertyValues, PropertyNames)
        local Data, ActorIDList = {}, {}
        if Succ then
            for Ind = 1, PropertyNames:Length() do
                local PropertyName = PropertyNames[Ind]
                if UE.UJsonBlueprintFunctionLibrary.HasField(PropertyValues, PropertyName) then
                    local PropertyValue0 = HiBlueprintFunctionLibrary.GetJsonObjectField(PropertyValues, PropertyName)
                    local KeyType = UE.UHiEdRuntime.GetStringField(PropertyValue0, "KeyType")
                    local KeyJsonWrapper = UE.UHiEdRuntime.GenerateJsonWrapperForUE5Map(KeyType, PropertyName)
                    local KeyValue, rActorIDlist = self:GetUE5PropertyBase(Actor, Object, PropertyName, KeyJsonWrapper, PropertyDefaultKeyValue)
                    ActorIDList = self:MergeActorIDList(ActorIDList, rActorIDlist)
                    local DataValue = HiBlueprintFunctionLibrary.GetJsonObjectField(PropertyValue0, "Value")
                    local ValueValue
                    ValueValue, rActorIDlist = self:GetUE5PropertyBase(Actor, Object, PropertyName, DataValue, PropertyDefaultValueValue)
                    ActorIDList = self:MergeActorIDList(ActorIDList, rActorIDlist)
                    if KeyValue and ValueValue then
                        Data[KeyValue] = ValueValue
                    end
                end
            end
        end
        return Data, ActorIDList
    elseif PropertyDataType == self.EDIT_UE5_Type.Transform then
        return UE.UHiEdRuntime.GetUE5DataTransform(PropertyValue)
    elseif PropertyDataType == self.EDIT_UE5_Type.Actor then -- 引用编辑器中已经配置的
        local EditorID = UE.UHiEdRuntime.GetUE5DataString(PropertyValue)
        local Data = utils.StrSplit(EditorID, "_")
        local EdActor = nil
        if Data and #Data >1 and Actor.GetEditorActor then
            EditorID = tonumber(Data[2])
            local Actor = Actor:GetEditorActor(Data[2])
            if Actor then
                EdActor = UE.FSoftObjectPtr(Actor)
                --EdActor = Actor
            end
        end
        return EdActor, {EditorID}
    elseif PropertyDataType == self.EDIT_UE5_Type.Object then -- /Game/Data/Datatable/DT_ResourceIndex.DT_ResourceIndex 从这个表里读取配置的资源
        local ID = UE.UHiEdRuntime.GetUE5DataString(PropertyValue)
        local Path = self:GetUE5ObjectPath(ID)
        if Path == "" then
            Path = ID
        end
        local Obj = UE.UObject.Load(Path)
        return Obj
    elseif PropertyDataType == self.EDIT_UE5_Type.GameplayTag then
        if Actor == nil then
            local s = UE.UHiEdRuntime.GetUE5DataString(PropertyValue)
            s = s:sub(11, -3)
            return UE.UHiEdRuntime.RequestGameplayTag(s)
        else
            local StructBaseProperty = PropertyDefaultValue
            if StructBaseProperty then
                local ret = StructBaseProperty:Copy()
                local s = UE.UHiEdRuntime.GetUE5DataString(PropertyValue)
                ret:ImportText(Actor, s)
                return ret
            end
        end
    elseif PropertyDataType == self.EDIT_UE5_Type.Vector then
        return UE.UHiEdRuntime.GetUE5DataVector(PropertyValue)
    elseif PropertyDataType == self.EDIT_UE5_Type.Boolean then
        return UE.UHiEdRuntime.GetUE5DataBoolean(PropertyValue)
    elseif PropertyDataType == self.EDIT_UE5_Type.Float then
        return UE.UHiEdRuntime.GetUE5DataFloat(PropertyValue)
    elseif PropertyDataType == self.EDIT_UE5_Type.String then
        return UE.UHiEdRuntime.GetUE5DataString(PropertyValue)
    elseif PropertyDataType == self.EDIT_UE5_Type.Int then
        return UE.UHiEdRuntime.GetUE5DataInt(PropertyValue)
    elseif PropertyDataType == self.EDIT_UE5_Type.Enum or (#PropertyDataType_data > 1 and PropertyDataType_data[1] == self.EDIT_UE5_Type.Enum)then
        local V = UE.UHiEdRuntime.GetUE5DataString(PropertyValue)
        local Data = utils.StrSplit(V, "@")
        return tonumber(Data[2])
    elseif (#PropertyDataType_data > 1 and PropertyDataType_data[1] == self.EDIT_UE5_Type.StructBase) and Actor then
        local StructBaseProperty = PropertyDefaultValue
        if StructBaseProperty then
            local ActorIDList = {}
            local ret = StructBaseProperty:Copy()
            local s = UE.UHiEdRuntime.GetUE5DataString(PropertyValue)
            --local pattern = '%.EdActor_(%w+)_(%d+)_%"'
            --local ss, ee, cnt = 0, 0, 0
            --local replace_map = {}
            --for suit_dir,actor_id in string.gmatch(s, pattern) do
            --    local EdActor = Actor:GetEditorActor(actor_id)
            --    local Name = "None"
            --    if EdActor then
            --        Name = G.GetDisplayName(EdActor)
            --    end
            --    table.insert(ActorIDList, tonumber(actor_id))
            --    if Actor.CallGetPathName then
            --        local Name = string.format("EdActor_%s_%s_", suit_dir, actor_id)
            --        local PathName = Actor:CallGetPathName()
            --        local PathData = utils.StrSplit(PathName, "%.")
            --        if PathData and #PathData > 1 then
            --            local P = "\"(.-:.-%."..Name..")\""
            --            local ss1, ee1, v = string.find(s, P, ee+3)
            --            if ss1 ~= nil then
            --                local NewPath = table.concat({PathData[1], PathData[2], Name}, ".")
            --                replace_map[v] = NewPath
            --                ee = ee1 + 1
            --            end
            --        end
            --    end
            --    cnt = cnt + 1
            --end
            --local function do_replace()
            --    for old, new in pairs(replace_map) do
            --        s = string.gsub(s, old, new)
            --    end
            --end
            --pcall(do_replace)
            ret:ImportText(Actor, s)
            return ret, ActorIDList
        end
    end
end

function EdUtils:SetUE5ChildActorComponet(Actor, Value)
    local ChildActorComponents = Actor:K2_GetComponentsByClass(UE.UChildActorComponent)
    if ChildActorComponents then
        for ind=1, ChildActorComponents:Length() do
            local ChildActorComp = ChildActorComponents[ind]
            local CompName = G.GetObjectName(ChildActorComp)
            local Transform = Value[CompName]
            --G.log:debug("zsf", "SetUE5ChildActorComponet %s %s %s %s %s %s %s", Value, type(Value), Actor:IsServer(), G.GetDisplayName(Actor), ChildActorComp, G.GetDisplayName(ChildActorComp), G.GetObjectName(ChildActorComp))
            if Transform then
                local HitResult = UE.FHitResult()
                ChildActorComp:K2_SetRelativeTransform(Transform, false, HitResult, false)
            end
        end
    end
end

function EdUtils:SetUE5SplineComponet(Actor, Value, EditorId)
    local SplineComponent = Actor:GetComponentByClass(UE.USplineComponent)
    --G.log:debug("zsf", "[waypoint_lua] ReceiveBeginPlay %s %s %s %s %s %s", EditorId, SplineComponent, #Value, type(Value), Actor:IsServer(), G.GetDisplayName(Actor))
    if SplineComponent and Value then
        if type(Value)=="table" then
            SplineComponent:ClearSplinePoints()
            for _,location in ipairs(Value) do
                SplineComponent:AddSplinePoint(location, UE.ESplineCoordinateSpace.Local, true)
            end
        end
        return true
    else
        return false
    end
end

local CompTypeMp = {
    {UE.UNiagaraComponent, {
        Asset=function(Object, Value)
            Object:SetAsset(Value, true)
        end,
    }},
    {UE.ULightComponent, {
        LightColor=function(Object, Value)
            local Color = UE.UKismetMathLibrary.Conv_ColorToLinearColor(Value)
            Object:SetLightColor(Color, true)
        end,
    }},
    {UE.UStaticMeshComponent, {
        StaticMesh=function(Object, Value)
            Object:SetStaticMesh(Value)
        end,
    }},
    {UE.USkeletalMeshComponent, {
        SkeletalMeshAsset=function(Object, Value)
            Object:SetSkeletalMeshAsset(Value)
        end,
        SkeletalMesh=function(Object, Value)
            Object:SetSkeletalMeshAsset(Value)
        end,
        AnimationMode=function(Object, Value)
            Object:SetAnimationMode(Value)
        end,
       AnimClass= function(Object, Value)
           Object:SetAnimClass(Value)
       end,
    }},
    {UE.UActorComponent, { -- All Components have a base of ActorComponent, this must be at last
        RelativeLocation=function(Object, Value)
            Object:K2_SetRelativeLocation(Value, false, UE.FHitResult(), true)
        end,
        RelativeScale3D=function(Object, Value)
            Object:SetRelativeScale3D(Value)
        end,
        RelativeRotation=function(Object, Value)
            Object:K2_SetRelativeRotation(Value, false, UE.FHitResult(), true)
        end,
    }}
}
function EdUtils:SetUE5Property_Object(Actor, Object, PropertyName, PropertyValue)
    local PropertyDefaultValue = Object[PropertyName]
    local Value, ActorIDList = self:GetUE5PropertyBase(Actor, Object, PropertyName, PropertyValue, PropertyDefaultValue)
    if ActorIDList and #ActorIDList > 0 then
        local sActorIDList = {}
        for ind=1,#ActorIDList do
            table.insert(sActorIDList, tostring(ActorIDList[ind]))
        end

        local CompName = "" -- Default is Actor
        local bActorComponent = Object:IsA(UE.UActorComponent)
        if bActorComponent then
            CompName = G.GetObjectName(Object)
        end
        -- deal with actorcomponent reference editor actor
        Actor[PropertyName.."@Container"] = sActorIDList
        if Actor.MergeToActorIdList then
            Actor:MergeToActorIdList(sActorIDList, CompName)
        end
    end
    local bCheckComp = false
    for _,data in ipairs(CompTypeMp) do
        local CompType = data[1]
        if Object:IsA(CompType) then
            local CompKeyMap = data[2]
            if CompKeyMap[PropertyName] then
                bCheckComp  = true
                CompKeyMap[PropertyName](Object, Value)
            end
        end
    end
    if not bCheckComp then -- Actor Property or ActorComponent Property not in CompTypeMp
        Object[PropertyName] = Value
    end
    if PropertyName == "ActorGuid" then -- Set ActorGuid For LevelSequence, and so on
        if Actor.SetActorGuid then
            local ActorGuid, bSuccess = UE.UKismetGuidLibrary.Parse_StringToGuid(Value)
            Actor:SetActorGuid(ActorGuid)
        end
    end
end

function EdUtils:SetUE5Property(Actor, Jsonwrapper, bClient, EditorId)
    if UE.UJsonBlueprintFunctionLibrary.HasField(Jsonwrapper, "UE5") then
        local UE5Propery = HiBlueprintFunctionLibrary.GetJsonObjectField(Jsonwrapper, "UE5")
        local PropertyNames = UE.TArray(UE.FString)
        local Succ = UE.UJsonBlueprintFunctionLibrary.GetFieldNames(UE5Propery, PropertyNames)
        if Succ then
            --local UEComps = Actor:K2_GetComponentsByClass(UE.UActorComponent)
            --G.GetObjectName(UEComp)
            local CompsMap = {}
            local Comps = Actor:K2_GetComponentsByClass(UE.UActorComponent)
            for Ind = 1, Comps:Length() do -- Make Map of All the Components of this Actor with it's name; Actor[CompName] May be nil
                local Comp = Comps[Ind]
                local Name = G.GetObjectName(Comp)
                CompsMap[Name] = Comp
            end
            for Ind = 1, PropertyNames:Length() do
                local PropertyName = tostring(PropertyNames[Ind])
                if PropertyName == EdUtils.EDIT_UE5_Type.UE5Comps then
                    local UE5CompsPropery = HiBlueprintFunctionLibrary.GetJsonObjectField(UE5Propery, EdUtils.EDIT_UE5_Type.UE5Comps)
                    local CompsPropertyNames = UE.TArray(UE.FString)
                    local Succ = UE.UJsonBlueprintFunctionLibrary.GetFieldNames(UE5CompsPropery, CompsPropertyNames)
                    if Succ then
                        for Indj = 1, CompsPropertyNames:Length() do
                            local CompPropertyName = tostring(CompsPropertyNames[Indj])
                            local Comp = CompsMap[CompPropertyName]
                            if Comp and UE.UJsonBlueprintFunctionLibrary.HasField(UE5CompsPropery, CompPropertyName) then
                                local UE5CompProperty = HiBlueprintFunctionLibrary.GetJsonObjectField(UE5CompsPropery, CompPropertyName)
                                local UE5CompPropertyNames = UE.TArray(UE.FString)
                                local Succ = UE.UJsonBlueprintFunctionLibrary.GetFieldNames(UE5CompProperty, UE5CompPropertyNames)
                                if Succ then
                                    for Indk = 1, UE5CompPropertyNames:Length() do
                                        local SubCompPropertyName = UE5CompPropertyNames[Indk]
                                        local SubCompPropertyValue = HiBlueprintFunctionLibrary.GetJsonObjectField(UE5CompProperty, SubCompPropertyName)
                                        self:SetUE5Property_Object(Actor, Comp, SubCompPropertyName, SubCompPropertyValue)
                                    end
                                end
                            end
                        end
                    end
                else
                    -- if current is Client and this property is not Replicated, then must set this property via exported json data
                    if not (bClient and UE.UHiEdRuntime.IsReplicated(Actor, PropertyName)) then
                        if UE.UJsonBlueprintFunctionLibrary.HasField(UE5Propery, PropertyName) then
                            local PropertyValue = HiBlueprintFunctionLibrary.GetJsonObjectField(UE5Propery, PropertyName)
                            self:SetUE5Property_Object(Actor, Actor, PropertyName, PropertyValue)
                        end
                    end
                end
            end
        end
    end
    -- 设置下 Splie 的 points; 需要等待 UE5 Property 设置完成; Server 和 Client 都是这里设置
    local arrLocation = Actor[EdUtils.EDIT_UE5_Type.SplineNodeLocation]
    if arrLocation then
        EdUtils:SetUE5SplineComponet(Actor, arrLocation, EditorId)
    end
    -- 设置蓝图中嵌套 ChildActorCompent 的场景支持记录 Transform
    local mapChildActorsTransform = Actor[EdUtils.EDIT_UE5_Type.ChildActorsTransform]
    if mapChildActorsTransform then
        EdUtils:SetUE5ChildActorComponet(Actor, mapChildActorsTransform)
    end
end

function EdUtils:GetUE5Property(Actor, JsonWrapper, PropertyName)
    if UE.UJsonBlueprintFunctionLibrary.HasField(JsonWrapper, "UE5") then
        local UE5Propery = HiBlueprintFunctionLibrary.GetJsonObjectField(JsonWrapper, "UE5")
        if UE.UJsonBlueprintFunctionLibrary.HasField(UE5Propery, PropertyName) then
            local PropertyValue = HiBlueprintFunctionLibrary.GetJsonObjectField(UE5Propery, PropertyName)
            local PropertyDefaultValue = Actor and Actor[PropertyName] or nil
            return self:GetUE5PropertyBase(Actor, Actor, PropertyName, PropertyValue, PropertyDefaultValue)
        end
    end
end

function EdUtils:GetMutableActorSubSystem(ContextObject)
    return SubsystemUtils.GetMutableActorSubSystem(ContextObject)
end

function EdUtils:GetJsonData(ContextObject, Actor)
    local HiEditorDataCompClass = UE.UClass.Load(BPConst.HiEditorDataComp)
    local HiEditorDataComp = Actor:GetComponentByClass(HiEditorDataCompClass)
    if HiEditorDataComp then
        local EditorID = HiEditorDataComp.EditorId
        local JsonString = HiEditorDataComp.JsonString
        if JsonString ~= nil and JsonString ~= "" then
            self:GetMutableActorSubSystem(ContextObject):DecodeStringToJson(EditorID, JsonString)
            if self:GetMutableActorSubSystem(ContextObject):ContainsInJsonObjectWrapperDatas(EditorID) then
                local JsonObject = self:GetMutableActorSubSystem(ContextObject):GetJsonObjectWrapper(EditorID)
                return JsonObject
            end
        end
    end
end

function EdUtils:ReceiveBeginPlay(self)
    -- 为关联的Actor注册回调
    if self.ActorIdList then
        for ActorId,_ in pairs(self.ActorIdList) do
            ActorId = tostring(ActorId)
            local ChildActor = self:GetMutableActorSubSystem():GetActor(ActorId)
            if ChildActor then
                if self.CheckChildReady then
                    self:CheckChildReady()
                end
            end
            --self:LogInfo("zsf", "ListenActorSpawnOrDestroy %s %s %s", self:GetEditorID(), ActorId, ChildActor)
            self:GetMutableActorSubSystem():ListenActorSpawnOrDestroy(ActorId, self, self.ListenActorSpawnOrDestroy)
        end
    end
end

function EdUtils:ReceiveEndPlay(self, Reson)
    -- 为关联的Actor卸载回调
    if self.ActorIdList then
        for ActorId,_ in pairs(self.ActorIdList) do
            --self:LogInfo("zsf", "UnListenActorSpawnOrDestroy %s", ActorId)
            self:GetMutableActorSubSystem():UnlistenActorSpawnOrDestroy(ActorId, self, self.ListenActorSpawnOrDestroy)
        end
    end
end
---- Editor --------
function EdUtils:IsEditor()
    return UE.UHiEdRuntime.IsEditor() == true
end

function EdUtils:GetActorLabel(Actor)
    if Actor then
        if self:IsEditor() then
            local ActorLabel = Actor:GetActorLabel()
            return ActorLabel
        else
            -- TODO: 这个在游戏中不靠谱
            local DisplayName = G.GetDisplayName(Actor)
            return DisplayName
        end
    else
        return 'Unknow Actor'
    end
end

function EdUtils:SetActorLabel(Actor, Label)
    if self:IsEditor() then
        Actor:SetActorLabel(Label)
    end
end

function EdUtils:SetFolderPath(Actor, Path)
    if self:IsEditor() then
        Actor:SetFolderPath(Path)
    end
end
---- Editor --------

---@param InvokerActor AActor 检测表示区域能力的 ChildActor Spawn 出来
function EdUtils:CheckAreaAbilitChildActors(InvokerActor)
    local ChildActors = UE.TArray(UE.AActor)
    InvokerActor:GetAttachedActors(ChildActors)
    local CreatedMap, Cnt = {}, 0
    for Ind=1,ChildActors:Length() do
        local ChildActor = ChildActors[Ind]
        if ChildActor.AreaAbilityTag then
            local Tag = ChildActor.AreaAbilityTag
            if Tag:sub(1, #self.AreaAbilityPrefix) == self.AreaAbilityPrefix then
                CreatedMap[Tag] = true
                Cnt = Cnt + 1
            end
        end
    end
    return CreatedMap, Cnt
end

--获取Area Ability DT中的Row，@param AreaAbility 对应的Key
function EdUtils:GetAreaAbilityDataTableRow(AreaAbility)
    local AreaAbilityType = AreaAbility
    local RowName = Enum.E_AreaAbility.GetDisplayNameTextByValue(AreaAbilityType)

    local AreaAbilityConstDataTable = UE.UDataTable.Load(AreaAbilityTypeDataTablePath)
    local ret = UE.UObject.Load(AreaAbilityTypeDataStructurePath)
    local Row = ret()
    UE.UDataTableFunctionLibrary.GetDataTableRowFromName(AreaAbilityConstDataTable,RowName,Row)
    return Row
end

return EdUtils
