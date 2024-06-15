local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local SplineTrackComponent = Component(ComponentBase)
local decorator = SplineTrackComponent.decorator

function SplineTrackComponent:Initialize(...)
    Super(SplineTrackComponent).Initialize(self, ...)
    self.Actors = UE.TArray(UE.AActor)
end

function SplineTrackComponent:Start()
    Super(SplineTrackComponent).Start(self)
end

function SplineTrackComponent:ReceiveBeginPlay()
    Super(SplineTrackComponent).ReceiveBeginPlay(self)
end

function SplineTrackComponent:OnJumpToTrack(IsHead)
    G.log:info_obj(self, "SplineTrackComponent", "OnJumpToTrack %s", IsHead)
    local Player = G.GetPlayerCharacter(self, 0)
    Player:SendMessage("EnterSplineTrack", self, IsHead)
end

function SplineTrackComponent:ActorEnterTrack(Actor)
    G.log:info_obj(self, "SplineTrackComponent", "OnActorEnterTrack, %s, %s", self, Actor)
    if self.Actors:Find(Actor) == 0 then
        self.Actors:AddUnique(Actor)
    end
end

function SplineTrackComponent:ActorLeaveTrack(Actor)
    local index = self.Actors:Find(Actor)
    if index ~= 0 then
        self.Actors:RemoveItem(Actor)
    end
end

function SplineTrackComponent:IsActorInTrack(Actor)
    G.log:info_obj(self, "SplineTrackComponent", "Actors %d, %d",self.Actors:Length(), self.Actors:Find(Actor))
    for i = 1, self.Actors:Length() do
        G.log:info_obj(self, "SplineTrackComponent", "IsActorInTrack %d, %s",i, self.Actors[i])
    end
    return self.Actors:Find(Actor) ~= 0
end

return SplineTrackComponent