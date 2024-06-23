--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@class WBP_Interaction_Tombstone : WBP_Interaction_Tombstone_C
---@field OnCloseCallback function
---@field OnMouseButtonDownCallback function
---@field OnMouseButtonUpCallback function
---@field HideLayerNode UIHideLayerNode

---@type WBP_Interaction_Tombstone_C
local WBP_Interaction_Tombstone = Class(UIWindowBase)

local DEFAULT_MONOLOGUE_ID = 1016
local COMPLETE_MONOLOGUE_ID = 1017

---@param self WBP_Interaction_Tombstone
local function OnClickedCloseButton(self)
    local OnAnimFinish = function()
        UIManager:CloseUI(self, true)
    end
    if self.OnCloseCallback then
        self.OnCloseCallback()
    end
    self.WBP_Interaction_Secondary:PlayTitleOutAnim(OnAnimFinish)
    self.WBP_Interaction_Secondary:PlayBottonOutAnim()
end

function WBP_Interaction_Tombstone:RegCloseCallBack(CallBack)
    self.OnCloseCallback = CallBack
end

function WBP_Interaction_Tombstone:RegMouseButtonDownCallBack(CallBack)
    self.OnMouseButtonDownCallback = CallBack
end

function WBP_Interaction_Tombstone:RegMouseButtonUpCallBack(CallBack)
    self.OnMouseButtonUpCallback = CallBack
end

function WBP_Interaction_Tombstone:TombstoneCleanComplete()
    self.WBP_Interaction_Secondary:SetSimpleBottomContentByMonoLogueID(COMPLETE_MONOLOGUE_ID)
end

function WBP_Interaction_Tombstone:Construct()
    self.OnCloseCallback = nil
    self.OnMouseButtonDownCallback = nil
    self.OnMouseButtonUpCallback = nil
    self.WBP_Interaction_Secondary.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, OnClickedCloseButton)
end

function WBP_Interaction_Tombstone:Destruct()
    self.WBP_Interaction_Secondary.WBP_Common_TopContent.CommonButton_Close.OnClicked:Remove(self, OnClickedCloseButton)
end

function WBP_Interaction_Tombstone:OnShow()
    self.WBP_Interaction_Secondary:PlayTitleInAnim()
    self.WBP_Interaction_Secondary:SetBottomMonoLogue(DEFAULT_MONOLOGUE_ID)
end

function WBP_Interaction_Tombstone:OnHide()
end

---The system calls this method to notify the widget that a mouse button was release within it. This event is bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Interaction_Tombstone:OnMouseButtonUp(MyGeometry, MouseEvent)
    if self.OnMouseButtonUpCallback then
        self.OnMouseButtonUpCallback()
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

---The system calls this method to notify the widget that a mouse button was pressed within it. This event is bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Interaction_Tombstone:OnMouseButtonDown(MyGeometry, MouseEvent)
    if self.OnMouseButtonDownCallback then
        self.OnMouseButtonDownCallback()
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

---The system will use this event to notify a widget that the cursor has left it. This event is NOT bubbled.
---@param MouseEvent FPointerEvent
---@return void
function WBP_Interaction_Tombstone:OnMouseLeave(MouseEvent)
    if self.OnMouseButtonUpCallback then
        self.OnMouseButtonUpCallback()
    end
end

return WBP_Interaction_Tombstone
