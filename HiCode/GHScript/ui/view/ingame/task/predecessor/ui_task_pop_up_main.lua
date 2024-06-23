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

---@class WBP_Task_PredecessorTaskPopup_C
local UITaskPopUpMain = Class(UIWindowBase)

--function UITaskPopUpMain:Initialize(Initializer)
--end

--function UITaskPopUpMain:PreConstruct(IsDesignTime)
--end

-- function UITaskPopUpMain:Construct()
-- end

--function UITaskPopUpMain:Tick(MyGeometry, InDeltaTime)
--end

function UITaskPopUpMain:OnConstruct()
    ---@type TaskMainVM
    self.TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    self:InitWidget()
    self:BuildWidgetProxy()
end

---@param MissionItem MissionItem
function UITaskPopUpMain:InitPopUpWidget(MissionItem)
    ---@type MissionItem
    self.MissionItem = MissionItem
    ---@type Mission|MissionAct
    self.SelectMission = nil
    ---@type number
    self.MissionType = 0

    if self.TaskMainVM then
        self.SelectMission, self.MissionType = self.TaskMainVM:GetPopUpMission(self.MissionItem)
    end
    self.MissionIdList = self.TaskMainVM:GetMissionDependenciesNodes(MissionItem)
    self:SetMissionData()
    self:OnPlayEnterAnimation()
end

function UITaskPopUpMain:InitWidget()
    self.WBP_Common_Popup_Medium.WBP_MedPopupClose.OnClicked:Add(self, self.ButtonClose_OnClicked)
end

function UITaskPopUpMain:BuildWidgetProxy()
    ---@type UListViewProxy
    self.ListView_TaskTargetProxy = WidgetProxys:CreateWidgetProxy(self.List_Task)
end

function UITaskPopUpMain:SetMissionData()
    local ChapterName
    if self.MissionType == self.TaskMainVM.MissionListType.Mission then
        ChapterName = self.SelectMission.Name
    else
        ChapterName = self.SelectMission.Subname
    end
    self.Txt_ChapterName:SetText(ChapterName)
    self.ListView_TaskTargetProxy:SetListItems(self.MissionIdList)
end

function UITaskPopUpMain:ButtonClose_OnClicked()
    ---@type WBP_TaskPopUp_Window_C
    local PopUpWindowInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_Task_PopUp_Window.UIName)
    PopUpWindowInstance:PlayAkEventOnHide()
    self:UnbindAllFromAnimationFinished(self.DX_Out)
    self:BindToAnimationFinished(self.DX_Out, { self, self.OnClosePopUpWindow })
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function UITaskPopUpMain:OnClosePopUpWindow()
    self:OnPlayOutBackgroundAnimation(self.DX_Out)
    if self.TaskMainVM then
        ---@type WBP_TaskPopUp_Window_C
        local PopUpWindowInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_Task_PopUp_Window.UIName)
        PopUpWindowInstance:RemovePopUpWindow(self)
    end
end

---@param Animation UWidgetAnimation
function UITaskPopUpMain:OnPlayOutBackgroundAnimation(Animation)
    if Animation == self.DX_Out then
        ---@type WBP_Common_Popup_Medium
        local WBP_Common_Popup_Medium = self.WBP_Common_Popup_Medium
        WBP_Common_Popup_Medium:PlayOutAnim()
    end
end

function UITaskPopUpMain:OnPlayEnterAnimation()
    -- self:UnbindAllFromAnimationFinished(self.DX_In)
    -- self:BindToAnimationFinished(self.DX_In, { self, self.OnPlayInBackgroundAnimation })
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self:OnPlayInBackgroundAnimation()
end

function UITaskPopUpMain:OnPlayInBackgroundAnimation()
    ---@type WBP_Common_Popup_Medium
    local WBP_Common_Popup_Medium = self.WBP_Common_Popup_Medium
    WBP_Common_Popup_Medium:PlayInAnim()
end

return UITaskPopUpMain
