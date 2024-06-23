--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@class WBP_TaskPopUp_Window_C
local UITaskPopUp = Class(UIWindowBase)

---@param MissionItem MissionItem
function UITaskPopUp:AddPopUpWindow(MissionItem)
    local WidgetClass = UIManager:ClassRes("UI_Task_PopUp")

    if WidgetClass then
        ---@type WBP_Task_PredecessorTaskPopup_C
        local NewWidget = UE.NewObject(WidgetClass, self)
        local NewSlot = self.PopUpContainer:AddChildToCanvas(NewWidget)
        self:ScaleSlotValue(NewSlot)
        NewWidget:InitPopUpWidget(MissionItem)
        self:PlayAkEventOnShow()

        self.PredecessorWidgetArray:Add(NewWidget)
    end
end

function UITaskPopUp:ScaleSlotValue(NewSlot)
    local Offset = self.SlotValue.Offset
    local Anchors = self.SlotValue.Anchors
    local Alignment = self.SlotValue.Alignment
    NewSlot:SetAutoSize(true)
    NewSlot:SetOffsets(Offset)
    NewSlot:SetAnchors(Anchors)
    NewSlot:SetAlignment(Alignment)
end

---@param item WBP_Task_PredecessorTaskPopup_C
function UITaskPopUp:RemovePopUpWindow(item)
    item:RemoveFromParent()
    self.PredecessorWidgetArray:RemoveItem(item)
end

function UITaskPopUp:ClearPopUpWindow()
    if self.PredecessorWidgetArray then
        local Num = self.PredecessorWidgetArray:Length()
        for i = 1, Num do
            local Widget = self.PredecessorWidgetArray:Get(i)
            Widget:RemoveFromParent()
        end
        self.PredecessorWidgetArray:Clear()
        self:PlayAkEventOnHide()
    end
end

function UITaskPopUp:ClosePopUpWindow()
    self:CloseMyself()
end

return UITaskPopUp
