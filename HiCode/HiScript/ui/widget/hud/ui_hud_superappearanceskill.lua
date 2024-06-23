--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local G = require('G')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@type WBP_HUD_SuperAppearanceSkill_C
local UIHudSuperAppearanceSkill = Class(UIWindowBase)

function UIHudSuperAppearanceSkill:UpdateParams(CharInd, QTETime)
    self.CharInd = CharInd
    self.QTETime = QTETime
end

function UIHudSuperAppearanceSkill:OnConstruct()
    self:InitWidget()

    local controller = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    controller:SendMessage("RegisterIMC", UIDef.UIInfo.UI_SuperAppearanceSkill.UIName,{"SuperAppearanceSkill",},{"SwitchPlayer"})
end

function UIHudSuperAppearanceSkill:InitWidget()
    self.QteItems = {self.SuperAppearanceSkill_Item_1, self.SuperAppearanceSkill_Item_2,
     self.SuperAppearanceSkill_Item_3, self.SuperAppearanceSkill_Item_4}
    self.QteItemLines = {self.Image_Line_1, self.Image_Line_2, self.Image_Line_3}
    self.QteItemsAnims = {self.DX_Skill1To2, self.DX_Skill2To3, self.DX_Skill3To4}
end

--显示第一个QTE并显示动画后开启进度条
function UIHudSuperAppearanceSkill:OnShow()
    if not self.CharInd or not self.QTETime then
        G.log:debug("UIHudSuperAppearanceSkill:", "self.CharInd is nil or self.QTETime is nil ")
        return
    end

    self.ItemIndex = 1
    self.QteItems[self.ItemIndex]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.QteItems[self.ItemIndex]:Init(self.CharInd, self.QTETime, self)
    self:StartCountDown()
    self.QteItems[self.ItemIndex]:PlayInAnim()
    UIManager:CloseUIByName(UIDef.UIInfo.UI_MainInterfaceHUD.UIName, false)
end

--加载并显示下一个qte，播放切换动画
function UIHudSuperAppearanceSkill:ShowNextQTE(CharInd, QTETime)
    self.ItemIndex = self.ItemIndex + 1
    if self.ItemIndex > #self.QteItems then
        return
    end
    self.CharInd = CharInd
    self.QTETime = QTETime
    self.QteItems[self.ItemIndex]:Init(self.CharInd, self.QTETime, self)
    self:StartCountDown()
    self:PlayQteItemDxIn(self.ItemIndex)
end

--播放两个qteItem之间的切换动画
function UIHudSuperAppearanceSkill:PlayQteItemDxIn(index)
    if index > #self.QteItems then
        return
    end
    self.QteItems[index]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.QteItemLines[index - 1]:SetVisibility(UE.ESlateVisibility.Hidden)
    self:PlayAnimation(self.QteItemsAnims[index - 1], 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

--切换动画完成后，播放item的出现动画
function UIHudSuperAppearanceSkill:PlayQteItemDxInFinished()
    self.QteItems[self.ItemIndex]:PlayInAnim()
end

--倒计时
function UIHudSuperAppearanceSkill:StartCountDown()
    if self.QTETimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.QTETimer)
        self.QTETimer = nil
    end
    self.QTETimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.EndQte}, self.QTETime, false)
end

--停止倒计时
function UIHudSuperAppearanceSkill:StopCountDown()
    if self.QTETimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.QTETimer)
        self.QTETimer = nil
    end
end

function UIHudSuperAppearanceSkill:OnDestroy()
    self:StopCountDown()
    local controller = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    controller:SendMessage("UnregisterIMC", UIDef.UIInfo.UI_SuperAppearanceSkill.UIName)
end

--获取倒计时的剩余时间用于进度条显示
function UIHudSuperAppearanceSkill:GetRemainingTime()
    if self.QTETimer ~= nil then
        return UE.UKismetSystemLibrary.K2_GetTimerRemainingTimeHandle(self, self.QTETimer)
    end
    return 0
end

--imc快捷键执行换人和超级登场
function UIHudSuperAppearanceSkill:DoPlayerSwitch(index)
    if index == self.CharInd then
        ---触发下一次qte后停止倒计时，防止倒计时结束但技能没放完导致ui消失
        self:StopCountDown()
        self.QteItems[self.ItemIndex]:ClickBtn()
    end
end

function UIHudSuperAppearanceSkill:EndQte()
    local controller = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    controller:SendMessage("EndQTE")
end

function UIHudSuperAppearanceSkill:EndSuperAppearanceSkill()
    self.QteItems[self.ItemIndex]:PlayOutAnim()
    UIManager:CloseUI(self, true)
    UIManager:OpenUI(UIDef.UIInfo.UI_MainInterfaceHUD)
end

return UIHudSuperAppearanceSkill
