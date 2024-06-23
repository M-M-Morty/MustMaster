--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local hero_initial_data = require("common.data.hero_initial_data").data
local G = require('G')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

---@type WBP_HUD_SuperAppearanceSkill_C
local UIHudSuperAppearanceSkillItem = Class(UIWindowBase)

function UIHudSuperAppearanceSkillItem:Init(CharInd, QTETime, ownerWidget)
    self.ownerWidget = ownerWidget
    self.CharInd = CharInd
    self.QTETime = QTETime
    self.bCanClick = false
    self.bInQteSkill = false
    self.bClicked = false
    local PlayerState = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0)
    local charType = PlayerState:GetPlayerController().ControllerSwitchPlayerComponent.TeamInfo[CharInd]

    if hero_initial_data[charType].icon_path then
        self.Img_Avatar:GetDynamicMaterial():SetTextureParameterValue('Texture',
            UE.UObject.Load(hero_initial_data[charType].icon_path))
    end
    self.WBP_Common_PCkey_1:SetPCkeyText("Normal", "Text", CharInd)

    self.StateSwitcher:SetActiveWidgetIndex(0)

    self.SuperShow_Btn.OnClicked:Add(self, self.ClickBtn)

end

function UIHudSuperAppearanceSkillItem:PlayInAnim()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UIHudSuperAppearanceSkillItem:PlayOutAnim()
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

--播完Dx_In后开始播放倒计时动画，允许点击,蓝图中调用
function UIHudSuperAppearanceSkillItem:SetCountDown()
    self.bCanClick = true
    local remainingTime = self.ownerWidget:GetRemainingTime()
    self:PlayAnimation(self.DX_Progress, 0, 1, UE.EUMGSequencePlayMode.Forward, 1/remainingTime, false)
end

function UIHudSuperAppearanceSkillItem:ClickBtn()
    if self.bClicked then
        return
    end
    self.bClicked = true
    self.StateSwitcher:SetActiveWidgetIndex(1)
    self:DoQTE()
    self:PlayClickAnim()
end

function UIHudSuperAppearanceSkillItem:PlayClickAnim()
    self:PlayAnimation(self.DX_Click, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

--点击动画播放完后，显示持续动画
function UIHudSuperAppearanceSkillItem:ClickAnimFinish()
    self:PlayAnimation(self.DX_AfterClick, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UIHudSuperAppearanceSkillItem:DoQTE()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    PlayerController:SendMessage("DoSuperAppearQTE")

    if PlayerController and self.bCanClick then
        PlayerController:SendMessage("Input_SwitchPlayer", self.CharInd, false)
        self.bCanClick = false
    end
end

return UIHudSuperAppearanceSkillItem
