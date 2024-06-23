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
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local MissionUtil = require('Script.mission.mission_utils')
local ConstTextTable = require("common.data.const_text_data").data

---@class WBP_Task_PredecessorTaskPopup_Item_C
local UITaskPopUpItem = Class(UIWidgetListItemBase)

--function UITaskPopUpItem:Initialize(Initializer)
--end

--function UITaskPopUpItem:PreConstruct(IsDesignTime)
--end

-- function UITaskPopUpItem:Construct()
-- end

--function UITaskPopUpItem:Tick(MyGeometry, InDeltaTime)
--end

function UITaskPopUpItem:OnConstruct()
    self:InitWidget()
    self:InitViewModel()
end

---@param ListItemObject UICommonItemObj_C
function UITaskPopUpItem:OnListItemObjectSet(ListItemObject)
    ---@type MissionItem
    self.MissionItem = ListItemObject.ItemValue
    if self.TaskMainVM then
        self.Mission, self.MissionType, self.MissionId = self.TaskMainVM:GetPopUpMission(self.MissionItem)
        if self.MissionType == self.TaskMainVM.MissionListType.Act then
            self.ActId = self.MissionId
            self.MissionId = self.TaskMainVM:GetPopUpMissionIdByActID(self.ActId)
        end
    end
    self:SetListData()
end

function UITaskPopUpItem:InitWidget()
    self.WBP_MissionButton.OnClicked:Add(self, self.MissionButton_OnClicked)
end

function UITaskPopUpItem:InitViewModel()
    ---@type TaskMainVM
    self.TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
end

---@param SelectMission MissionItem
function UITaskPopUpItem:OnOpenNextDetailPanel(SelectMission)
    if self.TaskMainVM then
        ---@type WBP_TaskPopUp_Window_C
        local PopUpWindowInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_Task_PopUp_Window.UIName)
        PopUpWindowInstance:AddPopUpWindow(SelectMission)
    end
end

function UITaskPopUpItem:LocateOnSelectedTask()
    if self.TaskMainVM then
        self.TaskMainVM.CurrentSelectTaskField:SetFieldValue(self.MissionId)
        ---@type WBP_TaskPopUp_Window_C
        local PopUpWindowInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_Task_PopUp_Window.UIName)
        PopUpWindowInstance:ClearPopUpWindow()
    end
end

function UITaskPopUpItem:MissionButton_OnClicked()
    if self.MissionItem then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
        local MissionAvatarComponent = PlayerController.PlayerState.MissionAvatarComponent
        if self.MissionType == self.TaskMainVM.MissionListType.Mission then
            if MissionUtil.GetBlockReason(self.MissionId, MissionAvatarComponent) == 0 then
                if not self.TaskMainVM:GetUIMissionNode(self.MissionId) then
                    return
                end
                self:LocateOnSelectedTask()
            else
                self.TaskMainVM:AddMissionTreeNode(self.MissionId)
                ---@type MissionItem
                local Item = self.TaskMainVM:GetMissionItem(self.MissionId, self.MissionType)
                self:OnOpenNextDetailPanel(Item)
            end
        else
            if not self.TaskMainVM:GetUIMissionNode(self.MissionId) then
                return
            end
            self:LocateOnSelectedTask()
        end
    end
end

function UITaskPopUpItem:SetListData()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    local MissionAvatarComponent = PlayerController.PlayerState.MissionAvatarComponent
    local BlockReasonType = MissionUtil.GetBlockReason(self.MissionId, MissionAvatarComponent)
    if self.MissionItem.ListType == self.TaskMainVM.MissionListType.Mission then
        self.Txt_ChapterName:SetText(self.Mission.Name)    -- 任务章节名称
    else
        self.Txt_ChapterName:SetText(self.Mission.Subname) -- 任务章节名称
    end
    if self.MissionType == self.TaskMainVM.MissionListType.Mission then
        if BlockReasonType == 0 then
            self.Txt_RestrictionDescription:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.Switch_ListIcon:SetActiveWidgetIndex(0)
        else
            local BlockReason = ConstTextTable[self.TaskMainVM.MissionBlockReason[BlockReasonType]].Content
            self.Txt_RestrictionDescription:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.Txt_RestrictionDescription:SetText(BlockReason)
            self.Switch_ListIcon:SetActiveWidgetIndex(1)
        end
    else
        self.Txt_RestrictionDescription:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Switch_ListIcon:SetActiveWidgetIndex(0)
    end
end

return UITaskPopUpItem
