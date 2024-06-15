local PicUtil = {}

local G = require("G")
local BlueprintConst = require("common.const.blueprint_const")


---@param PicKey string
---@return UObject
function PicUtil.GetPicResource(PicKey)
    local ConstPicDataTable = UE.UDataTable.Load(BlueprintConst.ConstPicDataTablePath)
    ---@type FBPS_Resource_Pic
    -- 2024.4.22 此处原local Row = Struct.BPS_Resource_Pic()的struct过段时间会被gc，故修改为重新获取
    local path  = BlueprintConst.Resource_Pic_Structure
    if path then
        local ret = UE.UObject.Load(path)
        local Row = ret()
        UE.UDataTableFunctionLibrary.GetDataTableRowFromName(ConstPicDataTable, PicKey, Row)
        if Row then
            if Row.PicSprite.AssetPath.PackageName ~= "None" then
                return UE.UObject.Load(Row.PicSprite.AssetPath.PackageName)
            end
            if Row.PicTexture.AssetPath.PackageName ~= "None" then
                return UE.UObject.Load(Row.PicTexture.AssetPath.PackageName)
            end
        end
    end
    G.log:error("PicConst", "Cannot find const pic %s", PicKey)
    return nil
end

-- ---@param PicKey string
-- ---@return UObject
-- function PicUtil.GetPicResource(PicKey)
--     local ConstPicDataTable = UE.UDataTable.Load(BlueprintConst.ConstPicDataTablePath)
--     ---@type FBPS_Resource_Pic
--     -- 2024.4.22 此处原local Row = Struct.BPS_Resource_Pic()的struct过段时间会被gc，故修改为重新获取
--     local path  = BlueprintConst.Resource_Pic_Structure
--     if path then
--         local ret = UE.UObject.Load(path)
--         local Row = ret()
--         UE.UDataTableFunctionLibrary.GetDataTableRowFromName(ConstPicDataTable, PicKey, Row)
--         G.log:debug("hangyuewang1", "PicKey=%s, Sprite=%s Texture=%s", PicKey, UE.UKismetSystemLibrary.IsValidSoftObjectReference(Row.PicTexture), UE.UKismetSystemLibrary.IsValidSoftObjectReference(Row.PicSprite))
--         if Row then
--             if UE.UKismetSystemLibrary.IsValidSoftObjectReference(Row.PicTexture) then
--                 return UE.UKismetSystemLibrary.LoadAsset_Blocking(Row.PicTexture)
--             end
--             if UE.UKismetSystemLibrary.IsValidSoftObjectReference(Row.PicSprite) then
--                 return UE.UKismetSystemLibrary.LoadAsset_Blocking(Row.PicSprite)
--             end
--         end
--     end
--     G.log:error("PicConst", "Cannot find const pic %s", PicKey)
--     return nil
-- end

---@param Image UImage
---@param PicKey string
---@param bMatchSize boolean
function PicUtil.SetImageBrush(Image, PicKey, bMatchSize)
    local PicResource = PicUtil.GetPicResource(PicKey)
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


return PicUtil