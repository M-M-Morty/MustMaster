--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Common_Popup_Big : WBP_Common_Popup_Big_C

---@type WBP_Common_Popup_Big
local WBP_Common_Popup_Big = UnLua.Class()

---需要父Window调用播放，建议在OnShow调用
function WBP_Common_Popup_Big:PlayInAnim()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

---需要父Window调用播放，建议在父Window播放DX_Out的时候播放
---UUserWidget:OnAnimationStarted(Animation)可以在父Window Override这个接口，判断Animation是否为DX_Out
function WBP_Common_Popup_Big:PlayOutAnim()
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

return WBP_Common_Popup_Big
