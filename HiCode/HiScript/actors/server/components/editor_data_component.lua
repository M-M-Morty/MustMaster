local G = require("G")
local SubsystemUtils = require("common.utils.subsystem_utils")
local EdUtils = require("common.utils.ed_utils")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")

local M = Component(ComponentBase)

local decorator = M.decorator

function M:LogInfo(...)
    G.log:info_obj(self, ...)
end

function M:LogDebug(...)
    G.log:debug_obj(self, ...)
end

function M:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function M:LogError(...)
    G.log:error_obj(self, ...)
end

-- function M:Initialize(Initializer)
-- end

-- function M:ReceiveBeginPlay()
-- end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

function M:GetMutableActorSubSystem()
    return SubsystemUtils.GetMutableActorSubSystem(self)
end

function M:Initialize(Initializer)
    Super(M).Initialize(self, Initializer)
    self.InitializeComponentCallbacks = {}
    self.StatusFlow_FuncMap = {}
    self.bComponentInitialized = false
end

function M:SplitSuiteName(SuiteName)
    local Data = EdUtils:SplitPath(SuiteName, "@")
    if #Data == 2 then
        self.EditorId = Data[1]
        self.SuiteDir = Data[2]
        local MutableActorSubSystem = self:GetMutableActorSubSystem()
        local level_name = MutableActorSubSystem:GetRealLevelName()
        -- In case of Replicate all the property from server, Client initilize Property Via EditorId to get local json data
        local json_path = table.concat({MutableActorSubSystem.data_root, level_name, '/', self.SuiteDir, '/', self.EditorId, '.json'})
        MutableActorSubSystem:LoadFileToJsonWrapper(self.EditorId, json_path)
    end
end

function M:SetInit(bInit)
    self.bInit = bInit
end

function M:SetUE5Property()
    local Owner = self:GetOwner()
    self:SplitSuiteName(Owner.EditorID)
    if not self.bInit and self.SuiteDir then
        local haveJsonWrapperDatas = self:GetMutableActorSubSystem():ContainsInJsonObjectWrapperDatas(self.EditorId)
        if haveJsonWrapperDatas then
            local JsonWrapper = self:GetMutableActorSubSystem():GetJsonObjectWrapper(self.EditorId)
            local bClient = Owner.IsClient and Owner:IsClient() or false
            local Pattern = table.concat({tostring(self.SuiteDir), tostring(self.EditorId)}, "_")
            if Owner.CallLowLevelRename then
                Owner:CallLowLevelRename(Pattern, nil)
            end
            EdUtils:SetUE5Property(Owner, JsonWrapper, bClient, self.EditorId)
            self.bInit = true
            Owner.JsonObject = JsonWrapper
        end
    end
end

function M:OnInitializeComponent()
    self.bComponentInitialized = true

    self:SetUE5Property()
    self:InitializeStatusFlow()

    -- todo initilize other components from editor data
    for i = 1, #self.InitializeComponentCallbacks do
        self.InitializeComponentCallbacks[i]()
    end
    self.InitializeComponentCallbacks = {}
end

function M:AddInitializeCallback(Callback)
    if self.bComponentInitialized then
        Callback()
        return
    end
    table.insert(self.InitializeComponentCallbacks, Callback)
end


function M:ReceiveBeginPlay()
    local Owner = self:GetOwner()
    local bClient = Owner.IsClient and Owner:IsClient() or false
    --if bClient then
    --    Owner:SetActorHiddenInGame(false)
    --end
    self.Overridden.ReceiveBeginPlay(self)
end

---- Status Flow Begin ------------------
function M:InitializeStatusFlow()
    local Owner = self:GetOwner()
    if not Owner then
        return
    end
    if Owner.StatusFlowEffect == nil then
        return
    end
    ---@param Key E_StatusFlow
    ---@param Val S_StatusFlowEffect
    for Key,Val in pairs(Owner.StatusFlowEffect:ToTable()) do
        local KeyName = Enum.E_StatusFlow.GetDisplayNameTextByValue(Key)
        local KeyNameData = EdUtils:SplitPath(KeyName, "2")
        if #KeyNameData > 1 then -- len == 1 only when KeyName=Appear; which means don't have SpawnEffect; defalut have no SpawnEffect
            self.StatusFlow_FuncMap[KeyName] = function(EnumKey, Callback)
                -- Call StatusFLow Stage Behavior
                --self:LogInfo("zsf", "[StatusFlow] FuncMap Call %s %s", EnumKey, KeyName)
                local StatusFlowEffect = Owner.StatusFlowEffect
                local Value = StatusFlowEffect:Find(EnumKey)
                if Owner:IsServer() then
                    self:Call_StatusFlow_FuncMap_Server(EnumKey, Value, Callback)
                else
                    self:Call_StatusFlow_FuncMap_Client(EnumKey, Value, Callback)
                end
                if Owner:IsServer() then
                    if Owner.Multicast_CallStatusFlow and EnumKey~=Enum.E_StatusFlow.Sapwn2Appear then
                        Owner:Multicast_CallStatusFlow(EnumKey)
                    end
               end
            end
        end
    end
end

function M:Call_StatusFlow_FuncMap_Client(EnumKey, Value, Callback)
    local Owner = self:GetOwner()
    local KeyName = Enum.E_StatusFlow.GetDisplayNameTextByValue(EnumKey)
    if Callback then
        self:LogInfo("zsf", "[StatusFlow] FuncMap Call Client %s %s %s", EnumKey, KeyName, Value)
        Callback(Owner:IsServer(), EnumKey, Value)
    end
end

function M:Call_StatusFlow_FuncMap_Server(EnumKey, Value, Callback)
    local Owner = self:GetOwner()
    local KeyName = Enum.E_StatusFlow.GetDisplayNameTextByValue(EnumKey)
    if Callback then
        self:LogInfo("zsf", "[StatusFlow] FuncMap Call Server %s %s %s", EnumKey, KeyName, Value)
        Callback(Owner:IsServer(), EnumKey, Value)
    end
end

-- deal with old without statusflow fashion
function M:Check_StatusFlow_Func_NIL(EnumKey)
    local KeyName = Enum.E_StatusFlow.GetDisplayNameTextByValue(EnumKey)
    return self.StatusFlow_FuncMap[KeyName] == nil
end

--@param EnumKey Enum from E_StatusFlow
function M:Call_StatusFlow_Func(EnumKey, Callback)
    if self:Check_StatusFlow_Func_NIL(EnumKey) then -- No Register this func, check config
        return
    end
    local KeyName = Enum.E_StatusFlow.GetDisplayNameTextByValue(EnumKey)
    self.StatusFlow_FuncMap[KeyName](EnumKey, Callback)
end
---- Status Flow End ------------------

return M