--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")

---@type AN_PlayMedia_C
local AN_PlayMedia = Class()

function AN_PlayMedia:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    G.log:info("yb", "anim_notify play anim %s %s", self.MediaKey, Owner:IsServer())
    if Owner:IsServer() then
        return true
    end

    --local Media = Owner:_GetComponent("MediaPlayComponent", false)\
    local Media = Owner.MediaPlayComponent
    if Media then
        Media:PlayMedia(self.MediaKey)
    end
    return true
end

return AN_PlayMedia
