--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local Actor = require("common.actor")

---@type BP_AkRadialMultiPositionEmitter_C
local AkRadialMultiPositionEmitter = Class(Actor)

function AkRadialMultiPositionEmitter:RecieveInsideCullingRange()
    if self:IsClient() then
        G.log:info("[hycoldrain]", "AkRadialMultiPositionEmitter:RecieveInsideCullingRange---")
        if self.SourcePositions:Length() > 0 then
            --self.AkComponent:SetGameObjectRadius(self.InnerRadius + 500, self.InnerRadius)
            UE.UAkGameplayStatics.SetMultiplePositions(self.AkComponent, self.SourcePositions)
            local ExternalSources = UE.TArray(UE.FAkExternalSourceInfo)
            self.AkComponent:PostAssociatedAkEvent(0, nil, ExternalSources)   
        end
    end
end

function AkRadialMultiPositionEmitter:RecieveOutsideCullingRange()
    if self:IsClient() then
        G.log:info("[hycoldrain]", "AkRadialMultiPositionEmitter:RecieveOutsideCullingRange---")
        UE.UAkGameplayStatics.StopActor(self)
    end
end

return RegisterActor(AkRadialMultiPositionEmitter)