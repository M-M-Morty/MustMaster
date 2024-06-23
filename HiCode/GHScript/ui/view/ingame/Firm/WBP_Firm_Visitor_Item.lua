--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Firm_Visitor_Item : WBP_Firm_Visitor_Item_C

---@type WBP_Firm_Visitor_Item
local WBP_Firm_Visitor_Item = UnLua.Class()

local PicConst = require("CP0032305_GH.Script.common.pic_const")

---@param PicKey string
function WBP_Firm_Visitor_Item:SetIconByPicKey(PicKey)
    local Texture = PicConst.GetPicResource(PicKey)
    self:SetIconByTexture(Texture)
end

---@param IconTexture UTexture2D
function WBP_Firm_Visitor_Item:SetIconByTexture(IconTexture)
    local DynamicMaterial = self.Img_Visitor:GetDynamicMaterial()
    DynamicMaterial:SetTextureParameterValue("Texture", IconTexture)
end

return WBP_Firm_Visitor_Item
