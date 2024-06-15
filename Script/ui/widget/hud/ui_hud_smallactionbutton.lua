--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--


local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ConstPic = require("CP0032305_GH.Script.common.pic_const")



---@class WBP_HUD_Track_C
local UIHudSmallActionButton = Class(UIWindowBase)

function UIHudSmallActionButton:ShowCancelImg()
    self.Cvs_Unse:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:PlayCancelInAnim()
end

function UIHudSmallActionButton:SetIcon(PicKey)
    if PicKey ~= nil then
        ConstPic.SetImageBrush(self.Img_Skill_Icon, PicKey)
    end
end

function UIHudSmallActionButton:PlayInAnim(callBack)
    if callBack then
        local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
            UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
        PlayAnimProxy.Finished:Add(self, callBack)
    else
        self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
end

function UIHudSmallActionButton:PlayOutAnim(callBack)
    if callBack then
        local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(
        UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    PlayAnimProxy.Finished:Add(self, callBack)
    else
        self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
end

function UIHudSmallActionButton:PlayClickDownAnim()
    self:PlayAnimation(self.DX_ClickDown, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function UIHudSmallActionButton:PlayClickUpAnim()
    self:PlayAnimation(self.DX_ClickUp, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function UIHudSmallActionButton:PlayCancelInAnim()
    self:PlayAnimation(self.DX_CancelIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function UIHudSmallActionButton:PlayPropChangeAnim()
    self:PlayAnimation(self.DX_PropChange, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function UIHudSmallActionButton:PlayAreaPowerInAnim()
    self:PlayAnimation(self.DX_AreaPowerIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end
return UIHudSmallActionButton
