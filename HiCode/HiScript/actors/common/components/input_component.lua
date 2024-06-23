--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local DataTableUtils = require("common.utils.data_table_utils")
local G = require("G")

local DEBUG_ENABLE = true

---@class InputHandler
local InputHandler = Class()
function InputHandler:ctor(EnableIMCKeys, MaskIMCist)
    self.EnableIMCKeys = EnableIMCKeys
    self.MaskIMCList = MaskIMCist
end

---@class InputHandler
local IMCSpec = Class()
function IMCSpec:ctor(IMC, Priority)
    self.IMC = IMC
    self.Priority = Priority
end

---@type BP_InputManagerComponent_C
local InputManager = Component(ComponentBase)
local decorator = InputManager.decorator

function InputManager:Initialize(...)
    Super(InputManager).Initialize(self, ...)
    self.IMCMaps = {}
    self.ActivityRefs = {}
    self.MaskRefs = {}


    self.Handlers = {}
end


function InputManager:ReceiveBeginPlay()
    Super(InputManager).ReceiveBeginPlay(self)
    self.__TAG__ = string.format("InputMgr(%s, server: %s)", G.GetObjectName(self), self.actor:IsServer())
    self.CacheIMC:Clear()
    self.ActivityIMCList:Clear()
    if self.actor:IsServer() then
        self.actor:RemoveBlueprintComponent(self)
    end
end

decorator.message_receiver()
function InputManager:RegisterIMC(RegisterKey, EnableIMCKeys, MaskIMCs)
    if self.Handlers[RegisterKey] then
        G.log:info(self.__TAG__, "RegisterKey (%s) has register twice", RegisterKey)
        return
    end
    G.log:info(self.__TAG__, "RegisterIMC %s", RegisterKey)
    --MaskIMCs有明确的需求才建议使用，如UI界面打开后需要屏蔽所有其他基础InputMapContext,一般情况还是建议使用按键优先级来屏蔽
    for _, IMC in pairs(EnableIMCKeys) do
        self:EnableIMCImp(IMC)
    end
    for _, MaskIMCKey in pairs(MaskIMCs) do
        self:MaskIMCImp(MaskIMCKey)
    end
    self.Handlers[RegisterKey] = InputHandler.new(EnableIMCKeys, MaskIMCs)
end 

decorator.message_receiver()
function InputManager:UnregisterIMC(RegisterKey)
    G.log:info(self.__TAG__, "UnregisterIMC %s", RegisterKey)
    local Handler = self.Handlers[RegisterKey]
    if Handler then
        for _, IMC in pairs(Handler.EnableIMCKeys) do
            self:DisableIMCImp(IMC)
        end
        for _, MaskIMCKey in pairs(Handler.MaskIMCList) do
            self:UnMaskIMCImp(MaskIMCKey)
        end
        self.Handlers[RegisterKey] = nil
    else 
        -- G.log:error(self.__TAG__, "HandlerID (%s) not exist!", HandlerID)
    end
end

function InputManager:LoadIMCImp(IMCKey)
    local IMCConfig = DataTableUtils.GetInputConfigDataByDataTableID(IMCKey)
    if not IMCConfig then
        G.log:error(self.__TAG__, "input key (%s) not config!", IMCKey)
        return
    end
    local IMC = nil

    if self.CacheIMC:Find(IMCKey) ~= -1 then
        IMC = self.CacheIMC:Find(IMCKey)
    end

    if not IMC then
        local IMCPath = UE.UKismetSystemLibrary.BreakSoftObjectPath(IMCConfig.IMCPath)
        IMC = UE.UObject.Load(IMCPath)
        self.CacheIMC:Add(IMCKey, IMC)
    end

    if IMC then
        return IMCSpec.new(IMC, IMCConfig.Priority)
    else
        return
    end
end

function InputManager:EnableIMCImp(IMCKey)
    local count = self.ActivityRefs[IMCKey]
    if count == nil then count  = 0 end
    self.ActivityRefs[IMCKey] = count + 1
    local Spec = self.IMCMaps[IMCKey]
    if Spec == nil then
        Spec = self:LoadIMCImp(IMCKey)
        if Spec then
            self.IMCMaps[IMCKey] = Spec
            G.log:info(self.__TAG__, "load IMC success! key: %s", IMCKey)
        else
            G.log:error(self.__TAG__, "load IMC failed! key: %s", IMCKey)
        end
    end

    if Spec and (self.MaskRefs[IMCKey] == 0 or self.MaskRefs[IMCKey] == nil) then
        self:AddMappingContextWrap(Spec)
        return true
    else 
        if Spec then
            G.log:info(self.__TAG__, "IMC(key: %s) can not enable immediately! Mask Count %d", IMCKey, self.MaskRefs[IMCKey])
            return true
        else
            return false 
        end
    end
end

function InputManager:DisableIMCImp(IMCKey)
    local count = self.ActivityRefs[IMCKey]
    if count ~= nil and count > 0 then
        count = count -1
        self.ActivityRefs[IMCKey] = count
        G.log:info(self.__TAG__, "imc key (%s) also enable by others, reference count: %s", IMCKey, self.ActivityRefs[IMCKey])
    end
    if count == 0 or count == nil then
        self.ActivityRefs[IMCKey] = nil
        local Spec = self.IMCMaps[IMCKey]
        if Spec then
            self:RemoveMappingContextWrap(Spec)
        end
        self.IMCMaps[IMCKey] = nil
    end
end

function InputManager:MaskIMCImp(IMCKey)
    local count = self.MaskRefs[IMCKey]
    if count == nil then count  = 0 end
    self.MaskRefs[IMCKey] = count + 1
    if count == 0 then
        local Spec = self.IMCMaps[IMCKey]
        if Spec then
            self:RemoveMappingContextWrap(Spec)
        end
    end
end

function InputManager:UnMaskIMCImp(IMCKey)
    local count = self.MaskRefs[IMCKey]
    if count ~= nil and count > 0 then
        count = count -1
        self.MaskRefs[IMCKey] = count
    end
    if count == 0 or count == nil then
        self.MaskRefs[IMCKey] = nil
        if self.ActivityRefs[IMCKey] ~= nil and self.ActivityRefs[IMCKey] > 0 then
            local Spec = self.IMCMaps[IMCKey]
            if Spec then
                G.log:info(self.__TAG__, "imc key (%s) reenable", IMCKey)
                self:AddMappingContextWrap(Spec)
            end
        end
    end
end

function InputManager:AddMappingContextWrap(IMCSpec)
    local EnhancedInputLocalPlayerSubsystem = UE.USubsystemBlueprintLibrary.GetLocalPlayerSubsystem(self.actor, UE.UEnhancedInputLocalPlayerSubsystem)
    if not EnhancedInputLocalPlayerSubsystem then
        G.log:info(self.__TAG__, "Get EnhancedInputLocalPlayerSubsystem failed %s", UE.UKismetSystemLibrary.GetObjectName(self.actor))
        return
    end

    if EnhancedInputLocalPlayerSubsystem:HasMappingContext(IMCSpec.IMC) then
        G.log:info(self.__TAG__, "HasMappingContext %s", G.GetObjectName(IMCSpec.IMC))
    end

    if EnhancedInputLocalPlayerSubsystem then
        G.log:info(self.__TAG__, "AddMappingContextWrap %s %s", IMCSpec.IMC:GetName(), IMCSpec.Priority)
        EnhancedInputLocalPlayerSubsystem:AddMappingContext(IMCSpec.IMC, IMCSpec.Priority, UE.FModifyContextOptions())
        if DEBUG_ENABLE then
            self.ActivityIMCList:AddUnique(IMCSpec.IMC)
        end
    end
end

function InputManager:RemoveMappingContextWrap(IMCSpec)
    local EnhancedInputLocalPlayerSubsystem = UE.USubsystemBlueprintLibrary.GetLocalPlayerSubsystem(self.actor, UE.UEnhancedInputLocalPlayerSubsystem)
    if EnhancedInputLocalPlayerSubsystem and EnhancedInputLocalPlayerSubsystem:HasMappingContext(IMCSpec.IMC) then
        EnhancedInputLocalPlayerSubsystem:RemoveMappingContext(IMCSpec.IMC, UE.FModifyContextOptions())
        if DEBUG_ENABLE then
            self.ActivityIMCList:RemoveItem(IMCSpec.IMC)
        end
    end
end

return InputManager
