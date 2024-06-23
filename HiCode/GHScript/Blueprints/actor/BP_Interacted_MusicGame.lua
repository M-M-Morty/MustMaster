
local G = require('G')
local ActorBase = require("actors.common.interactable.base.interacted_item")

local M = Class(ActorBase)
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
end

function M:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    local playerState = UE.UGameplayStatics.GetPlayerState(self, 0)
    local playerActor = self:GetPlayerActor(OtherActor)
    if playerActor and playerActor.EdRuntimeComponent then
        if playerActor.EdRuntimeComponent.bInAreaAbility then
            return
        end
        playerActor.EdRuntimeComponent:AddNearbyActor(self)
    end
end

function M:DoClientInteractAction(actor)
    local tb = {}
    tb[1] = self.songList
    tb[2] = self.CountMode
    UIManager:OpenUI(UIDef.UIInfo.UI_MiniGames_AudioGames_MusicalSelection,tb)
end

return M
