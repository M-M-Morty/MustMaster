--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local VMdef = require('ui.viewmodel.vm_defines_const')

---@class ViewModelCollection
local ViewModelCollection = {}

ViewModelCollection.tbUniqueViewModel = {}
ViewModelCollection.tbViewModelInstance = {}

function ViewModelCollection:InitGlobalVM()
    ---@param VMInfo VMUniqueInfoClass
    for _, VMDefitem in pairs(VMdef.tbVMDefine) do
        local success, VMDef = pcall(require, VMDefitem)
        if success then
            for _, VMInfo in pairs(VMDef.UniqueVMInfo) do
                local VMClass = require(VMInfo.ViewModelClassPath)
                if VMClass then
                    self:CreateUniqueViewModel(VMClass, VMInfo.UniqueName)
                end
            end
        end
    end
end

function ViewModelCollection:CreateUniqueViewModel(ViewModelClass, ViewModelName)
    local VMInstance = self:FindUniqueViewModel(ViewModelName)
    if VMInstance then
        return
    end
    VMInstance = self:CreateViewModelInstance(ViewModelClass, ViewModelName)
    if VMInstance then
        self.tbUniqueViewModel[ViewModelName] = VMInstance
    end
    return VMInstance
end

function ViewModelCollection:FindUniqueViewModel(ViewModelName)
    if ViewModelName then
        return self.tbUniqueViewModel[ViewModelName]
    end
end

function ViewModelCollection:CreateViewModelInstance(ViewModelClass, ViewModelName)
    if ViewModelClass and type(ViewModelName) == 'string' and #ViewModelName > 0 then
        local ViewModelInstance = ViewModelClass.new(ViewModelName)
        ViewModelInstance:SetInCollection(self)
        table.insert(self.tbViewModelInstance, ViewModelInstance)
        return ViewModelInstance
    end
end

function ViewModelCollection:FindViewModelInstance(ViewModelClass, ViewModelName)
    for i, Instance in pairs(self.tbViewModelInstance) do
        if Instance:GetViewModelClass() == ViewModelClass and Instance:GetViewModelName() == ViewModelName then
            return Instance
        end
    end
end

function ViewModelCollection:RemoveViewModelInstance(ViewModelInstance)
    TableUtil:ArrayRemoveIf(self.tbViewModelInstance, function(Instance)
        if Instance == ViewModelInstance then
            local VMName = Instance:GetViewModelName()
            if VMName then
                self.tbUniqueViewModel[VMName] = nil
            end
            Instance:SetInCollection(nil)
            Instance:ReleaseVMObj()
            return true
        end
    end)
end

function ViewModelCollection:RemoveViewModelClass(ViewModelClass)
    TableUtil:ArrayRemoveIf(self.tbViewModelInstance, function(Instance)
        if Instance:GetViewModelClass() == ViewModelClass then
            local VMName = Instance:GetViewModelName()
            if VMName then
                self.tbUniqueViewModel[VMName] = nil
            end
            Instance:SetInCollection(nil)
            Instance:ReleaseVMObj()
            return true
        end
    end)
end

function ViewModelCollection:TickUniqueViewModels()
    for _, VM in pairs(self.tbUniqueViewModel) do
        if VM.OnTickVM then
            VM:OnTickVM()
        end
    end
end

return ViewModelCollection
