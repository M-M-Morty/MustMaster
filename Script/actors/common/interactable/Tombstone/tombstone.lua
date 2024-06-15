--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR KyainZhang
-- @DATE 2023/11/7
--

---@type

require "UnLua"
local G = require("G")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local ActorBase = require("actors.common.interactable.base.interacted_item")

local M = Class(ActorBase)


function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:Show_Interaction_UI()

    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    TombstoneWidget = UIManager:OpenUI(UIDef.UIInfo.UI_Interaction_Tombstone)


    local OnMouseButtonDownCallback = function()
      print("gmopentombstone OnMouseButtonDownCatiback")
      self:OnMouseButtonDown()
    end

    local OnMouseButtonUpCallback = function()
      print("gmopentombstone OnMouseButtonUpCallback")
      self:OnMouseButtonUp()
    end

    local OnCloseCallback = function()
      print("gmopentombstone oncloseCatiback")
      self:out()
    end


    TombstoneWidget:RegCloseCallBack(OnCloseCallback)
    TombstoneWidget:RegMouseButtonDownCallBack(OnMouseButtonDownCallback)
    TombstoneWidget:RegMouseButtonUpCallBack(OnMouseButtonUpCallback)
  

end

function M:End_Wipe()
  TombstoneWidget:TombstoneCleanComplete()
end








return M