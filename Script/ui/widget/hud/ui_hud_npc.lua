--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local IconUtility = require('CP0032305_GH.Script.common.utils.icon_util')
local UIData = require("common.data.ui_const_data").data

local curDisState = {
    None = -1,
    MissionPointDis = 0,
    AllUIDis = 1,
    AllDis = 2,
    HideAll = 3,
}
---@class WBP_HUD_NPC_C
local WBP_HUD_NPC = Class(UIWidgetBase)
WBP_HUD_NPC.DisState = curDisState.None
WBP_HUD_NPC.InValidText = ''

--function WBP_HUD_NPC:Initialize(Initializer)
--end

--function WBP_HUD_NPC:PreConstruct(IsDesignTime)
--end

function WBP_HUD_NPC:OnConstruct()
end

---@param name string
---@param bubble string
---@param position string
---@param NpcIconType number
---@param bShowIcon boolean
function WBP_HUD_NPC:OpenHudNPC(name, bubble, position, NpcIconType, bShowIcon)
    self.isShow = true
    self.position = position or self.InValidText
    self.name = name or self.InValidText
    self.bubble = bubble or self.InValidText
    self.NpcIconType = NpcIconType
    -- self.TaskIconType = 1
    -- self.TaskIconState = 0
    self.NpcHudDuration = self.NpcHudDuration or 10000000
    if self.OnConstructDelegate then
        self.OnConstructDelegate(self)
        self.isInit = true
    end
    self:SetDisInfo(UIData.TOPLOGO_BRIEF_DISTANCE.FloatValue, UIData.TOPLOGO_NORMAL_DISTANCE.FloatValue,
        UIData.TOPLOGO_DETAIL_DISTANCE.FloatValue)
    if not bShowIcon then
        self:HideIcon()
    end
    if self.bTopLogo == nil then
        self.bTopLogo = true
    end
    self:SetInfo()
end

function WBP_HUD_NPC:SetInfo()
    self:SetBubble(self.bubble)
    self:SetName(self.name)
    self:SetPosition(self.position)
    self:ShowIcon()
end

function WBP_HUD_NPC:UpdateDistance(Distance, InDeltaTime)
    if not self.isShow then
        return
    end
    if Distance <= self.AllDis then
        self:ShowUI(curDisState.AllDis)
    elseif Distance <= self.AllUIDis then
        self:ShowUI(curDisState.AllUIDis)
    elseif Distance <= self.MissionPointDis then
        self:ShowUI(curDisState.MissionPointDis)
    else
        self:ShowUI(curDisState.HideAll)
    end
end

function WBP_HUD_NPC:ShowUI(DisState)
    if self.DisState == DisState then
        return
    end
    if self.DisState == curDisState.HideAll then
        self:HideAllUI()
        self.DisState = DisState
        return
    end
    self:ShowIcon()
    self:StopAnimationsAndLatentActions()
    if DisState == curDisState.MissionPointDis then
        self:ShowIcon()
    end
    if DisState == curDisState.AllUIDis then
        self:SetBubble(self.bubble)
        self:ShowIcon()
        if DisState < self.DisState then
            if self.bTopLogo then
                self:PlayAnimation(self.DX_MoveDown, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
            end
        end
    end
    if DisState == curDisState.AllDis then
        self:SetBubble(self.bubble)
        self:ShowIcon()
        self:SetName(self.name)
        self:SetPosition(self.position)
        if self.bTopLogo then
            self:PlayAnimation(self.DX_MoveUp, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
        end
    end
    if self.bTopLogo then
        self:SetName(self.name)
        self:SetPosition(self.position)
    end
    if DisState == curDisState.HideAll then
        self:HideAllUI()
    end
    self.DisState = DisState
end

function WBP_HUD_NPC:HideAllUI()
    self.NPC_title:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.IconContainer:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.NPCName:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.NPCposition:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self:PlayAnimation(self.DX_AllOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_NPC:SetMissionState(state)
    self.IconContainer:SetActiveWidgetIndex(state)
end

function WBP_HUD_NPC:SetDisInfo(MissionPointDis, AllUIDis, AllDis)
    self.MissionPointDis = MissionPointDis or 0
    self.AllUIDis = AllUIDis or 0
    self.AllDis = AllDis or 0
end

function WBP_HUD_NPC:OpenTopLogo()
    self.bTopLogo = true
    self:SetName(self.name)
    self:SetPosition(self.position)
    self:PlayAnimation(self.DX_MoveUp, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_NPC:CloseTopLogo()
    self.bTopLogo = false
    self.NPCName:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.NPCposition:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function WBP_HUD_NPC:SetName(Content)
    if not Content or Content == self.InValidText then
        self.NPCName:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.NPCName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self.NPCName:SetText(Content)
    self.name = Content
end

function WBP_HUD_NPC:SetPosition(Content)
    if not Content or Content == self.InValidText then
        self.NPCposition:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.NPCposition:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self.NPCposition:SetText(Content)
    self.position = Content
end

---@param Content string@讲述内容
function WBP_HUD_NPC:SetBubble(Content)
    -- self:StopAnimationsAndLatentActions()
    -- self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    if not Content or Content == self.InValidText then
        self.TextBubble.TextBubble:SetText(self.InValidText)
        self.NPC_title:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TextBubble.TextBubble:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.NPC_title:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.TextBubble.TextBubble:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.TextBubble.TextBubble:SetText(Content)
        self.TextBubble.TextBubble:SetRenderOpacity(1.0)
    end
    self.bubble = Content
end

---@param DurationTime number@显示时长, 为0则常驻
function WBP_HUD_NPC:SetNpcHudDuration(DurationTime)
    if DurationTime < 0 then
        return
    end
    self.StartHUDTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnStartHUDTimer }, DurationTime, false)
end

function WBP_HUD_NPC:SetOnConstructDelegate(fnDelegate)
    self.OnConstructDelegate = fnDelegate
    if self.isInit then
        self.OnConstructDelegate(self)
    end
end

function WBP_HUD_NPC:ShowIcon()
    if self.TaskIconType and self.TaskIconState then
        self:ShowTaskIcon(self.TaskIconType, self.TaskIconState)
    else
        self:ShowNpcIcon(self.NpcIconType)
    end
end

function WBP_HUD_NPC:HideIcon()
    self.IconContainer:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function WBP_HUD_NPC:ShowTaskIcon(MissionType, MissionState)
    if not MissionType or not MissionState then
        self.IconContainer:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.IconContainer:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WBP_HUD_Task_Icon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.TaskIconType = MissionType
    self.TaskIconState = MissionState
    IconUtility:SetTaskIcon(self.WBP_HUD_Task_Icon, self.TaskIconType, self.TaskIconState - 1)
end

function WBP_HUD_NPC:HideTaskIcon()
    self.TaskIconType = nil
    self.TaskIconState = nil
    if self.NpcIconType == nil then
        self.IconContainer:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function WBP_HUD_NPC:ShowNpcIcon(NpcIconType)
    --TODO 还未有功能图标
    if NpcIconType == nil then
        return
    end
    self.NpcIconType = NpcIconType
    self:HideTaskIcon()
end

function WBP_HUD_NPC:HideNpcIcon()
    --TODO 还未有功能图标
    self.NpcIconType = nil
    if self.TaskIconType == nil then
        self.IconContainer:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.IconContainer:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

function WBP_HUD_NPC:OnFadeOut()
end

function WBP_HUD_NPC:Tick(MyGeometry, InDeltaTime)
end

function WBP_HUD_NPC:OnStartHUDTimer()
    self.StartHUDTimer = nil
    self.isShow = false
    self:PlayAnimation(self.DX_out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_NPC:CancelStartHUDTimer()
    if self.StartHUDTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.StartHUDTimer)
        self.isShow = true
        self.StartHUDTimer = nil
    end
end

return WBP_HUD_NPC
