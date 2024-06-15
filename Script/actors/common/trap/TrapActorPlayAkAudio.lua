--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR PanZiBin
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local TrapActorBase = require("actors.common.trap.TrapActorBase")

---@type TrapActor_PlayAkAudio_C
local TrapActor_PlayAkAudio = Class(TrapActorBase)

function TrapActor_PlayAkAudio:OverlapByOtherActor(OtherActor)
    if not OtherActor.CharIdentity or OtherActor.CharIdentity ~= Enum.Enum_CharIdentity.Player then   --暂定玩家触碰在有所反映
        return
    end

    for i = 1, self.AkAudioEventList:Length() do
        OtherActor:SendMessage("PlayAkAudioEvent", self.AkAudioEventList:Get(i), self.bFollow, self.PlayMode)
    end
end

return TrapActor_PlayAkAudio