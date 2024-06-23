

local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local BagModule = require('CP0032305_GH.Script.system_simulator.bag.bag_sim_module')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')


---@class DagVM : ViewModelBase
local BagVM = Class(ViewModelBaseClass)

function BagVM:ctor()
    BagModule:RegisterBagItemChanged(function(...)
        self:OnBagItemsChanged(...)
    end)
    self.ItemAddQueueField = self:CreateVMArrayField({})
end

function BagVM:OnBagItemsChanged(item)
    -- self.ItemAddQueueField:AddItem(item)

    local ui = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_GetPropTips.UIName)
    ui:OnBagItemsChanged(item)
end


return BagVM