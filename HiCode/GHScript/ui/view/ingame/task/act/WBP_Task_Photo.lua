--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local PicConst = require("CP0032305_GH.Script.common.pic_const")
local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local G = require("G")
local MissionActUtil = require("CP0032305_GH.Script.mission.mission_act_utils")
local TaskActType = MissionActUtil.TaskActType

---@class WBP_Task_Photo : WBP_Task_Photo_C
---@field bNotComplete boolean

---@type WBP_Task_Photo
local WBP_Task_Photo = UnLua.Class()

local MAX_INDEX = 5
local SCALE = 0.65

---@param PicKey string
function WBP_Task_Photo:SetOnlyPhoto(PicKey)
    PicConst.SetImageBrush(self.Img_Picture, PicKey)
    self.Switch_CasePhotos:SetActiveWidgetIndex(0)
    self.Switch_FrameBG:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Img_Badge:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Txt_PictureName:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Switch_Thumbtack:SetVisibility(UE.ESlateVisibility.Collapsed)
end

---@param self WBP_Task_Photo
---@param MissionActID integer
local function ShowCompleteMission(self, MissionActID)
    self.Switch_CasePhotos:SetActiveWidgetIndex(0)
    self.bNotComplete = false
    local MissionActConfig = MissionActUtils.GetMissionActConfig(MissionActID)
    if MissionActConfig == nil then
        G.log:warn("WBP_Task_Photo", "ShowCompleteMission failed! Invalid act ID: %d", MissionActID)
        return
    end
    PicConst.SetImageBrush(self.Img_Picture, MissionActConfig.MissionBoard_Pic)
    self.Switch_FrameBG:SetActiveWidgetIndex(MissionActConfig.MissionBoard_Bg - 1)
    self.Switch_Thumbtack:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switch_Thumbtack:SetActiveWidgetIndex(MissionActConfig.MissionBoard_Bg - 1)
    if MissionActConfig.Type == MissionActUtils.TaskActType.Main then
        self.Img_Badge:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Img_Badge:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self.Txt_PictureName:SetText(MissionActConfig.Name)
end

---@param self WBP_Task_Photo
---@param MissionActID integer
local function ShowStartMission(self, MissionActID)
    self.Switch_CasePhotos:SetActiveWidgetIndex(1)
    self.bNotComplete = true
    local MissionActConfig = MissionActUtils.GetMissionActConfig(MissionActID)
    if MissionActConfig == nil then
        G.log:warn("WBP_Task_Photo", "ShowCompleteMission failed! Invalid act ID: %d", MissionActID)
        return
    end
    self.Txt_PhotoThumbnailName:SetText(MissionActConfig.Name)
    self.Switch_Thumbtack:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Switch_Thumbtack:SetActiveWidgetIndex(MAX_INDEX)
end

---@param MissionActID integer
---@param bIgnoreState boolean
function WBP_Task_Photo:SetMissionActID(MissionActID, bIgnoreState)
    self.MissionActID = MissionActID
    self.bIgnoreState = bIgnoreState
    if bIgnoreState then
        ShowCompleteMission(self, MissionActID)
    else
        ---@type EMissionActState
        local EMissionActState = Enum.EMissionActState
        ---@type TaskActVM
        local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
        if TaskActVM then
            local MissionActData = TaskActVM:GetMissionAct(MissionActID)
            if MissionActData then
                if MissionActData.State == EMissionActState.RewardReceived then
                    ShowCompleteMission(self, MissionActID)
                else
                    local MissionActConfig = MissionActUtil.GetMissionActConfig(MissionActData.MissionActID)
                    if MissionActConfig and MissionActConfig.Type == TaskActType.Side and MissionActData.State == EMissionActState.Complete then
                        ShowCompleteMission(self, MissionActID)
                    else
                        ShowStartMission(self, MissionActID)
                    end
                end
            else
                G.log:warning("WBP_Task_Photo", "MissionActData nil, MissionActID:%d", MissionActID)
            end
        end
    end
end

---@return FVector2D
function WBP_Task_Photo:GetThumbtackSlotCenterPos()
    local Index = self.Switch_Thumbtack:GetActiveWidgetIndex() + 1
    ---@type UImage
    local ThumbtackWidget = self["Img_Thumbtack0"..Index]
    ---@type UCanvasPanelSlot
    local ImageSlot = ThumbtackWidget.Slot
    local SlotSize = ImageSlot:GetSize()
    local SlotPosition = ImageSlot:GetPosition()

    local CenterSlotPos = UE.FVector2D((SlotPosition.X + SlotSize.X / 2) * SCALE, (SlotPosition.Y + SlotSize.Y / 2) * SCALE)

    return CenterSlotPos
end

---这个方法废弃了
---@return FVector2D
function WBP_Task_Photo:GetThumbtackAbsoluteCenterPos()
    local Index = self.Switch_Thumbtack:GetActiveWidgetIndex() + 1
    ---@type UImage
    local ThumbtackWidget = self["Img_Thumbtack0"..Index]
    local AbsoluteSize = UE.USlateBlueprintLibrary.GetAbsoluteSize(ThumbtackWidget:GetCachedGeometry())
    local ThumbtackWidgetAbsolutePos = UE.USlateBlueprintLibrary.LocalToAbsolute(ThumbtackWidget:GetCachedGeometry(), UE.FVector2D(0, 0))
    return UE.FVector2D(ThumbtackWidgetAbsolutePos.X + AbsoluteSize.X / 2, ThumbtackWidgetAbsolutePos.Y + AbsoluteSize.Y / 2)
end

return WBP_Task_Photo
