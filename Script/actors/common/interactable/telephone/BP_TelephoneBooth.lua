--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local ActorBase = require("actors.common.interactable.base.interacted_item")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local MonoLogueUtils = require("common.utils.monologue_utils")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

---@type BP_TelephoneBooth_C
local M = Class(ActorBase)

local NO_CARD_MONOLOGUE_ID = 1009

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
end

---@param InvokerActor AActor
function M:DoClientInteractAction(InvokerActor)
    if not self:HasAuthority() and self:GetInteractable() and InvokerActor then
        local Cards = ItemUtil.GetAllPhoneCards(self)
        if #Cards > 0 then
            UIManager:OpenUI(UIDef.UIInfo.UI_InteractionTelephone)
        else
            local MonologueData = MonoLogueUtils.GenerateMonologueData(NO_CARD_MONOLOGUE_ID)
            local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
            if HudMessageCenterVM and MonologueData ~= nil then
                HudMessageCenterVM:ShowNagging(MonologueData)
            end
        end
    end
end

return M
