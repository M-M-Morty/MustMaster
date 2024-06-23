local G = require("G")
local json = require("thirdparty.json")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local DialogueData = require("common.data.dialogue_data").data
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

local MissionComponent = Component(ComponentBase)
local decorator = MissionComponent.decorator

function MissionComponent:GetDialogueDataForDetail(DialogueID)
    local DialogueInfo = DialogueData[DialogueID]
    if not DialogueInfo then
        G.log:warn("seekerma", "Learn Dialogue id: %d not found in Dialogue datatable", DialogueID)
        return
    end

    return DialogueInfo["detail"]
end

function MissionComponent:GetDialogueDataForOwner(DialogueID)
    local DialogueInfo = DialogueData[DialogueID]
    if not DialogueInfo then
        G.log:warn("seekerma", "Learn Dialogue id: %d not found in Dialogue datatable", DialogueID)
        return
    end

    return DialogueInfo["owner"]
end

function MissionComponent:Client_PrintLog_RPC(LogJson)
    local Param = json.decode(LogJson)

    local Verbosity = Param.Verbosity
    if Verbosity == Enum.EFlowLogVerbosity.Error then
        G.log:error("MissionLog", "%s", Param.Message)
    elseif Verbosity == Enum.EFlowLogVerbosity.Warning then
        G.log:warn("MissionLog", "%s", Param.Message)
    elseif Verbosity == Enum.EFlowLogVerbosity.Display or Verbosity == Enum.EFlowLogVerbosity.Log then
        G.log:info("MissionLog", "%s", Param.Message)
    elseif Verbosity == Enum.EFlowLogVerbosity.Verbose or Verbosity == Enum.EFlowLogVerbosity.VeryVerbose then
        G.log:debug("MissionLog", "%s", Param.Message)
    end

    -- Print message on screen
    local color = UE.FLinearColor(Param.TextColorR, Param.TextColorG, Param.TextColorB, Param.TextColorA)
    UE.UKismetSystemLibrary.PrintString(nil, Param.Message, Param.bPrintToScreen, false, color, Param.Duration)
end

function MissionComponent:SetWidgetVisibility()
    self.HiddenLayerContext = UIManager:SetOtherLayerHiddenExcept({Enum.Enum_UILayer.SequnceLayer})
    --UIManager:ResetHiddenLayerContext(HiddenLayerContext)
end

function MissionComponent:ResetWidgetVisibility()
    UIManager:ResetHiddenLayerContext(self.HiddenLayerContext)
end

function MissionComponent:ShowSubtitleBlackWidget(detail, playSpeed)
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:ShowSubtitleBlackWidget(detail)
    end
end

function MissionComponent:SetSubtitleBlackWidget(detail)
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:SetSubtitleBlackWidget(detail)
    end
end

function MissionComponent:CloseSubtitleBlackWidget(playSpeed)
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:CloseSubtitleBlackWidget(playSpeed)
    end
end

function MissionComponent:CloseSubtitleBlackImmediately()
    local UIBlackCurtain = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_BlackCurtain.UIName)
    if UIBlackCurtain then
        UIBlackCurtain:DXEventMissionFinishEnd()
    end
end

function MissionComponent:ShowSubtitleWidget(detail, playSpeed)
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:ShowSubtitleWidget(detail)
    end
end

function MissionComponent:SetSubtitleWidget(detail)
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:SetSubtitleWidget(detail)
    end
end

function MissionComponent:CloseSubtitleWidget(playSpeed)
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:CloseSubtitleWidget()
    end
end

return MissionComponent