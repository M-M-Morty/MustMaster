--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local G = require("G")
local UIDef = require('CP0032305_GH.Script.ui.ui_define')


local WBP_Common_CharacterDeath = Class(UIWindowBase)

function WBP_Common_CharacterDeath:UpdateParams(DeadPoint, DeadReasonInfo)
    self.DeadPoint = DeadPoint
    self.DeadReasonInfo = DeadReasonInfo
end

function WBP_Common_CharacterDeath:OnConstruct()
    self:InitWidget()
end

function WBP_Common_CharacterDeath:InitWidget()
    self.WBP_ComBtn_Resurrection.OnClicked:Add(self, self.ClickRevive)
end

function WBP_Common_CharacterDeath:OnShow()
    if self.DeadReasonInfo then
        self.Txt_DeathTitle:SetText(self.DeadReasonInfo.Title)
        self.Txt_TipsText:SetText(self.DeadReasonInfo.Content)
    end
    self:PlayAnim()
end

function WBP_Common_CharacterDeath:PlayAnim()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self:PlayAnimation(self.DX_Loop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_Common_CharacterDeath:ClickRevive()
    ---增加复活时loading界面，未来loading正式接入后需要重构
    UIManager:OpenUI(UIDef.UIInfo.UI_FirmLoading, 1)
    local Controller = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    Controller:SendMessage("ReliveInRelivePoint", self.DeadPoint)
    UIManager:CloseUI(self)
end

return WBP_Common_CharacterDeath
