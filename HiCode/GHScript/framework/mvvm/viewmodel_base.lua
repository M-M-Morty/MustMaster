--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local ViewmodelField = require('CP0032305_GH.Script.framework.mvvm.viewmodel_field')
local ViewmodelFieldArray = require('CP0032305_GH.Script.framework.mvvm.viewmodel_field_array')
local ViewModelInterface = require('CP0032305_GH.Script.framework.mvvm.viewmodel_interface')

---@class ViewModelBase : ViewModelInterface
local ViewModelBase = Class(ViewModelInterface)

function ViewModelBase:ctor(InName)
    self.ViewModelName = InName
end

function ViewModelBase:IsViewModel()
    return true
end

function ViewModelBase:GetViewModelClass()
    return self.__class__
end

function ViewModelBase:GetViewModelName()
    return self.ViewModelName
end

function ViewModelBase:SetInCollection(InCollection)
    ---@type ViewModelCollection
    self.ViewModelCollection = InCollection
end

function ViewModelBase:OnReleaseViewModel()
end

function ViewModelBase:ReleaseVMObj()
    if self.ViewModelCollection then
        self.ViewModelCollection:RemoveViewModelInstance(self)
    else
        self:OnReleaseViewModel()
        ViewModelBinder:UnBindByViewModel(self)
    end
end

---@param InFieldValue any
function ViewModelBase:CreateVMField(InFieldValue)
    return ViewmodelField.new(self, InFieldValue)
end

---@param InFieldValue table
function ViewModelBase:CreateVMArrayField(InFieldValue)
    return ViewmodelFieldArray.new(self, InFieldValue)
end

return ViewModelBase
