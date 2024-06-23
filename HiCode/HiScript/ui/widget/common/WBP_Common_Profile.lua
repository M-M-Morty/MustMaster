--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_Common_Profile : WBP_Common_Profile_C
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

---@type WBP_Common_Profile_C
local WBP_Common_Profile = Class(UIWindowBase)
local G = require('G')
local ConstPic = require("CP0032305_GH.Script.common.pic_const")

---@param PicKey string
function WBP_Common_Profile:UpdateProfile(PicKey)
    ---@type WBP_Common_Tab
    if PicKey ~= nil then
        ConstPic.SetImageBrush(self.Img_Profile, PicKey)
    end
end

function WBP_Common_Profile:Construct()

end

function WBP_Common_Profile:Destruct()

end

return WBP_Common_Profile
