--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

local tb = {}

-- 基础的UI层级，对应WBP_Ingame_LayerManager中的同名Canvas
-- TODO 详细注释

---@class UILayer
---初始化时会自动填充对应着Enum.Enum_UILayer
tb.UILayer = {}

---@class InteractUIType
tb.InteractUIType = {
    Dialogue = 1,           -- 对话选项
    Interact = 2,           -- 互动选项
}

--- 定义UIInfoClass给提供EmmyLua提示
---在UIInfo中配置的UIInfoClass，配置文件/Script/Engine.DataTable'/Game/CP0032305_GH/Blueprints/DT/UIInfo.UIInfo'
---UIManager初始化是会自动转换成UIInfoClass
---@class UIInfoClass
---@field UIName string
---@field UILayerIdent Enum.Enum_UILayer
---@field WidgetClassPath ObjectPath
---@field ZOrder number
---@field DefaultOpen boolean       
---@field ReleaseMouse boolean       @释放鼠标
---@field InputUIOnly boolean        @SetInputMode_UIOnly 一般用于全屏UI
---@field IMC boolean      @是否使用IMC_UI
---@field AutoCloseUI table          @打开UI时自动关闭某些UI
---@field DestroyClose boolean       @关闭时默认的销毁模式
---@field HideOtherLayer boolean     @是否隐藏除了自身层的其他层
---@field HideLayerWhiteList table   @隐藏层白名单(隐藏其他层操作时不隐藏的层)
---@field PageLevel Enum.Enum_UILevel           @UI的页面层级
local UIInfoClass = {}


-- UI的相关数据定义
-- TODO 详细注释

---@class UIInfoPromptClass
---@field UI_GMPanel UIInfoClass
---@field UI_TaskMain UIInfoClass
---@field UI_CommunicationNPC UIInfoClass
---@field UI_MissionTrack UIInfoClass
---@field UI_HudTrack UIInfoClass
---@field UI_Common_SecondTextConfirm UIInfoClass
---@field UI_Knapsack_UsePopup UIInfoClass
---@field UI_Knapsack_Main UIInfoClass
---@field UI_Common_PropTips UIInfoClass
---@field UI_Knapsack_ViewText UIInfoClass
---@field UI_Knapsack_ViewImg UIInfoClass
---@field UI_LevelDisplayTips UIInfoClass
---@field UI_LocationTips UIInfoClass
---@field UI_GetPropTips UIInfoClass
---@field UI_AwardTips UIInfoClass
---@field UI_CommonTips UIInfoClass
---@field UI_ImportantTips UIInfoClass
---@field UI_ControlTips UIInfoClass
---@field UI_BattleResultTips UIInfoClass
---@field UI_PreviewAnimation UIInfoClass
---@field UI_TimerDisplay UIInfoClass
---@field UI_GuideMain UIInfoClass
---@field UI_BossHP UIInfoClass
---@field UI_NaggingHUD UIInfoClass
---@field UI_DamageText UIInfoClass
---@field UI_StaminaHUD UIInfoClass
---@field UI_MainInterfaceHUD UIInfoClass
---@field UI_SkillState UIInfoClass
---@field UI_SquadList UIInfoClass
---@field UI_PlayerHP UIInfoClass
---@field UI_InteractPickup UIInfoClass
---@field UI_InteractionNote UIInfoClass
---@field UI_InteractionTelephone UIInfoClass
---@field UI_Interaction_Tombstone UIInfoClass
---@field UI_FirmLoading UIInfoClass
---@field UI_FirmMap UIInfoClass
---@field UI_BlackCurtain UIInfoClass
---@field UI_PlotText UIInfoClass
---@field UI_Second_TaskCompleted UIInfoClass
---@field UI_Interaction_Jar UIInfoClass
---@field UI_MadukLamp_Main UIInfoClass
---@field UI_Interaction_Emitter UIInfoClass
---@field UI_PreBarrage UIInfoClass
---@field UI_Barrage UIInfoClass
---@field UI_ScreenCreditList UIInfoClass
---@field UI_Task_PlotReview UIInfoClass
---@field UI_Task_PopUp_Window UIInfoClass
local UIInfoPromptClass = {}

---@type UIInfoPromptClass
tb.UIInfo = {}
function tb:InitUIDef()
    local MaxValue = Enum.Enum_UILayer:GetMaxValue()
    for i = 1, MaxValue do
        local LayerName = Enum.Enum_UILayer:GetDisplayNameTextByValue(i - 1)
        tb.UILayer[i] = LayerName
    end
    local FunctionLib = FunctionUtil:GlobalUClass('GH_FunctionLib')
    if FunctionLib then
        local UINames = FunctionLib.GetAllUINames():ToTable()
        for _, Name in pairs(UINames) do
            local bExist, RawUIInfo = FunctionLib.GetUIInfoContent(Name)
            if bExist then
                local info = {}
                info.UIName = Name
                info.UILayerIdent = RawUIInfo.UILayerIdent
                info.WidgetClassPath = UE.UKismetSystemLibrary.BreakSoftObjectPath(RawUIInfo.WidgetClassPath)..'_C'
                info.ZOrder = RawUIInfo.ZOrder
                info.DefaultOpen = RawUIInfo.DefaultOpen
                info.ReleaseMouse = RawUIInfo.ReleaseMouse
                info.InputUIOnly = RawUIInfo.InputUIOnly
                info.IMC = RawUIInfo.IMC
                info.AutoCloseUI = RawUIInfo.AutoCloseUI:ToTable()
                info.DestroyClose = RawUIInfo.DestroyClose
                info.HideOtherLayer = RawUIInfo.HideOtherLayer
                info.HideLayerWhiteList = RawUIInfo.HideLayerWhiteList:ToTable()
                info.PageLevel = RawUIInfo.PageLevel
                info.OpenAkEvent = RawUIInfo.OpenAkEvent
                info.CloseAkEvent = RawUIInfo.CloseAkEvent
                tb.UIInfo[Name] = info
            end
        end
    end
end


---@class LGUIInfoClass
---@field UIName string
---@field WidgetClassPath ObjectPath
---@field IMC boolean      @是否使用IMC_UI
local LGUIInfoClass = {}


-- UI的相关数据定义
-- TODO 详细注释

---@class LGUIInfoPromptClass
---@field UI_GMPanel LGUIInfoClass

tb.LGUIInfo = {}
function tb:InitLGUIDef()
    local FunctionLib = FunctionUtil:GlobalUClass('GH_FunctionLib')
    if FunctionLib then
        local LGUINames = FunctionLib.GetAllLGUINames():ToTable()
        for _, Name in pairs(LGUINames) do
            local bExist, RawLGUIInfo = FunctionLib.GetLGUIInfoContent(Name)
            if bExist then
                local info = {}
                info.LGUIName = Name
                info.LguiClassPath = UE.UKismetSystemLibrary.BreakSoftObjectPath(RawLGUIInfo.LguiClassPath)
                info.IMC = RawLGUIInfo.IMC
                info.UseLguiCamera = RawLGUIInfo.UseLguiCamera
                info.ReleaseMouse = RawLGUIInfo.ReleaseMouse
                info.LguiCameraTransOffset = RawLGUIInfo.LguiCameraTransOffset
                info.LguiTransformOffset = RawLGUIInfo.LguiTransformOffset
                info.OffsetLocation, info.OffsetRotation, info.OffsetScale = UE.UKismetMathLibrary.BreakTransform(RawLGUIInfo.LguiTransformOffset)
                info.CameraLocation, info.CameraRotation, info.CameraScale = UE.UKismetMathLibrary.BreakTransform(RawLGUIInfo.LguiCameraTransOffset)
                info.RootActorComponent = RawLGUIInfo.RootActorComponent
                info.LguiRenderingType = RawLGUIInfo.LguiRenderingType
                tb.LGUIInfo[Name] = info
            end
        end
    end
end

return tb
