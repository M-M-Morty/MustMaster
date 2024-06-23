local _M = {}

---@class ConstPicConfig
---@field pic_path string

local G = require("G")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

---@param PicKey string
---@return UObject
function _M.GetPicResource(PicKey)
    local FunctionLib = FunctionUtil:GlobalUClass('GH_FunctionLib')
    if FunctionLib then
        local bExit, Row = FunctionLib.GetPicResource(PicKey)
        if bExit and Row then
            local PicTexturePath = tostring(Row.PicTexture)
            local PicSpritePath = tostring(Row.PicSprite)
            if PicTexturePath ~= "" then
                return UE.UObject.Load(PicTexturePath)
            end
            if PicSpritePath ~= "" then
                return UE.UObject.Load(PicSpritePath)
            end
        end
    end
    G.log:error("PicConst", "Cannot find const pic %s", PicKey)
    return nil
end

---@param Image UImage
---@param PicKey string
---@param bMatchSize boolean
function _M.SetImageBrush(Image, PicKey, bMatchSize)
    local PicResource = _M.GetPicResource(PicKey)
    if PicResource == nil then
        G.log:error("PicConst", "PicResource is nil %s", PicKey)
        return
    end
    if bMatchSize then
        ---UPaperSprite
        if PicResource.SourceDimension then
            Image:SetBrushResourceObject(PicResource)
            Image.Brush.ImageSize = PicResource.SourceDimension
        else---UTexture2D
            Image:SetBrushFromTexture(PicResource, true)
        end
    else
        Image:SetBrushResourceObject(PicResource)
    end
end


return _M
