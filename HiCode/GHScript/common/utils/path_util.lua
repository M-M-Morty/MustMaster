local _M = {}

---@param softClassPtr TSoftClassPtr
---@return string
function _M.getFullPathString(softClassPtr)
    local PackageName = softClassPtr:GetLongPackageName()
    local AssetName = softClassPtr:GetAssetName()
    return PackageName.."."..AssetName
end

return _M