
--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local FirmMapLegendTypeTableConst = require("common.data.firm_map_legend_type_data")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local FirmUtil = require("CP0032305_GH.Script.ui.view.ingame.Firm.FirmUtil")
local MissionConst = require('Script.mission.mission_const')
local FirmMapTable = require("common.data.firm_map_data").data

local G = require('G')

---@class WBP_HUD_MiniMap : WBP_HUD_MiniMap_C
---@type WBP_HUD_MiniMap
---@field MissionTrackData MissionObject
local WBP_HUD_MiniMap = Class(UIWindowBase)

---@param self WBP_HUD_MiniMap
local function OnClickMiniMapButton(self)
    ---@type WBP_Firm_Map
    local currentMapId = FirmUtil.GetCurrentMapId(self)
    if not FirmMapTable[currentMapId] then
        return
    end
    
    local UI_FirmMap = UIManager:OpenUI(UIDef.UIInfo.UI_FirmMap)
    UI_FirmMap.WBP_Firm_Content:GetMiniMap(self)
    if self.MissionTrackData then
        UI_FirmMap:TransferMissionData(self.MissionTrackData)
    end
end

---@param Mission MissionObject
function WBP_HUD_MiniMap:ReceiveMissionData(Mission)

    if Mission then
        self.MissionTrackData = Mission
        local MissionTrackList = Mission:GetTrackTargetList()
        self.WBP_HUD_MiniMap_Content:CheckMissionUI()
        if Mission:IsTracking() and MissionTrackList then
            for i = 1, MissionTrackList:Length() do
                self.MissionItem = MissionTrackList[i]
                if self.MissionItem then
                    self:WidgetAddLabel(Mission,self.MissionItem)
                    self:CustomUIPlayAnimation(self.WBP_HUD_MiniMap_Content.CustomUI)
                 end
            end
        end

        local PlayerLoc2D = self.WBP_HUD_MiniMap_Content.PlayerLoc2D
        self.WBP_HUD_MiniMap_Content:MoveToLocation2D(PlayerLoc2D)
        self.WBP_HUD_MiniMap_Content:CheckIfOutCircle()
        --local MissionId = Mission:GetMissionID()
        --local MissionPosition = Mission:GetFirstTrackTargetPosition()
        --if MissionPosition and self.WBP_HUD_MiniMap_Content:LegendIsOwningMap(TypeId) then
        --    self.WBP_HUD_MiniMap_Content:AddLabel(MissionPosition, TypeId, false, FirmMapLegendTypeTableConst.Task, nil, Mission)
        --end
        
    end
end
function WBP_HUD_MiniMap:RemoveMissionUI()
    self.WBP_HUD_MiniMap_Content:CheckMissionUI()
end

function WBP_HUD_MiniMap:CustomUIPlayAnimation(CustomUI)
    -- body
   
    if CustomUI then
      
        local AnimationObj =self:GetWidgetAnimationObj(CustomUI)  
        CustomUI.WBP_HUD_Task_Icon:PlayAnimation(AnimationObj, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false) 
                
    end
end

function WBP_HUD_MiniMap:GetWidgetAnimationObj(CustomUI)
    -- body
    local AnimationObj=nil
    local CustomUIChild=CustomUI.WBP_HUD_Task_Icon
    if CustomUI.Mission then
        if CustomUI.Mission:GetMissionType() == MissionConst.EMissionType.Main then
            AnimationObj=CustomUIChild.DX_IconTrackMainLoop
        end
        if CustomUI.Mission:GetMissionType() == MissionConst.EMissionType.Activity then
           AnimationObj=CustomUIChild.DX_IconTrackDailyLoop
        end
     else
        if CustomUI.IsTrace then
              AnimationObj=CustomUIChild.DX_IconTrackNormalLoop
        end
    end 
    return AnimationObj
end

function WBP_HUD_MiniMap:WidgetAddLabel(InMission,InMissionItem)
    -- body
    
    local Type=FirmMapLegendTypeTableConst.Task
    local TypeId = FirmUtil.GetMapLegendIdByType(Type)
    self.MissionPosition = InMission:GetTrackTargetPosition(InMissionItem)
    if self.MissionPosition then
        local LableData={}
        LableData.Location=self.MissionPosition
        LableData.ShowId=TypeId
        LableData.IsGuide=false
        LableData.Type=Type
        LableData.MissionItem=InMissionItem
        LableData.Mission=InMission
        
        --self.WBP_HUD_MiniMap_Content:AddLabel(self.MissionPosition, TypeId, false, Type, nil, InMissionItem, InMission)
        self.WBP_HUD_MiniMap_Content:AddLabel(LableData)
    end
  
end


---@param self WBP_HUD_MiniMap
local function OnHoveredMiniMapButton(self)
    self.Switch_Decoration:SetActiveWidgetIndex(1)
end

---@param self WBP_HUD_MiniMap
local function OnUnHoveredMiniMapButton(self)
    self.Switch_Decoration:SetActiveWidgetIndex(0)
end

function WBP_HUD_MiniMap:OnConstruct()
    self.WBP_CommonButton.Button.OnClicked:Add(self, OnClickMiniMapButton)
    self.WBP_CommonButton.Button.OnHovered:Add(self, OnHoveredMiniMapButton)
    self.WBP_CommonButton.Button.OnUnhovered:Add(self, OnUnHoveredMiniMapButton)
    self.Time = 0
    self.TickInterval = 0.06
    self.ChangeMode = false

    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    TaskActVM:RegOnActStateChangeCallBack(self, self.OnActStateChanged)
    local MapId = FirmUtil.GetCurrentMapId(self)
    ---@type WBP_HUD_MiniMap_Content
    self.WBP_HUD_MiniMap_Content:Init(self, MapId)

end

function WBP_HUD_MiniMap:OnActStateChanged(MissionActID, State)
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    --G.log:debug("xuexiaoyu", "WBP_HUD_MiniMap:OnActStateChanged %s %s",tostring(TaskActVM:HasCompleteMainAct()),tostring(TaskActVM.AlreadyMissionCompleted))
    if State == Enum.EMissionActState.Initialize then
        self:PlayAnimation(self.DX_New, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
end


--function WBP_HUD_MiniMap:Tick(MyGeometry, InDeltaTime)
--    self.Time = self.Time + InDeltaTime
--    if self.Time >= self.TickInterval then
--        self.Time = 0
--        if not self.ChangeMode then
--            self:PlayerRotate()
--        end
--        self:CameraRotate()
--    end
--
--end

function WBP_HUD_MiniMap:PlayerRotate()
    local player = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
    if player then
        local Rotation = player:K2_GetActorRotation().Yaw
        self.Img_PositionArrow:SetRenderTransformAngle(Rotation)
    end
end

function WBP_HUD_MiniMap:CameraRotate()
    local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
    local Rotation = Controller:K2_GetActorRotation().Yaw
    self.Img_DirectionRange:SetRenderTransformAngle(Rotation + 90)
    if self.ChangeMode then
        self.CanvasPanel_Map:SetRenderTransformAngle(Rotation)
    end
end

function WBP_HUD_MiniMap:OnDestruct()
    self.WBP_CommonButton.Button.OnClicked:Remove(self, OnClickMiniMapButton)
    self.WBP_CommonButton.Button.OnHovered:Remove(self, OnHoveredMiniMapButton)
    self.WBP_CommonButton.Button.OnUnhovered:Remove(self, OnUnHoveredMiniMapButton)
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    TaskActVM:UnRegOnActStateChangeCallBack(self, self.OnActStateChanged)
    if self.DelayTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.DelayTimer)
        self.DelayTimer = nil
    end
end

return WBP_HUD_MiniMap
