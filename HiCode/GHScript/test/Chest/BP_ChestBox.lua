--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local ActorBase = require("actors.common.interactable.base.interacted_item")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@type BP_ChestBox_C
local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
end

---@param InvokerActor AActor
function M:DoClientInteractAction(InvokerActor)
    UIManager:OpenUI(UIDef.UIInfo.UI_InteractionNote, 100)
end

return M
