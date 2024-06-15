--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

---@type BP_AkComponent_C

local BeamFxAudioComponent = Component(ComponentBase)
local decorator = BeamFxAudioComponent.decorator

function BeamFxAudioComponent:Initialize(...)
    Super(BeamFxAudioComponent).Initialize(self, ...)
    self.LastCollidedActor = nil
    self.LoopAkComponent = nil
    self.CollideLoopAkComponent = nil
end

function BeamFxAudioComponent:Start()
    Super(BeamFxAudioComponent).Start(self)
    self.LastCollidedActor = nil    
end

function BeamFxAudioComponent:Stop()
    Super(BeamFxAudioComponent).Stop(self)
    self.LastCollidedActor = nil    
    self:StopBeamLoopAudio()
    self:StopBeamCollideLoopAudio()
end

function BeamFxAudioComponent:FilterCollidedActorClass(CollidedActor)
    return true
end


-- collide actor audio
decorator.message_receiver()
function BeamFxAudioComponent:OnCollideActor(CollidedActor, HitLocation)

    if self:FilterCollidedActorClass(CollidedActor) then
        --G.log:debug("hycoldrain", "collide Actor %s", tostring(CollidedActor), tostring(HitLocation))

        --4. collide loop audio
        if not(CollidedActor and self.LastCollidedActor) then

            if CollidedActor then
                -- start loop               
                G.log:info("[hycoldrain]", "BeamFxAudioComponent:start loop collide actor--- 【%s】", G.GetDisplayName(CollidedActor))
                if self.CollideLoopAkComponent then
                    self.CollideLoopAkComponent:K2_DestroyComponent(self.CollideLoopAkComponent)
                end
                self.CollideLoopAkComponent = UE.UAkGameplayStatics.SpawnAkComponentAtLocation(self.actor, self.CollideLoopAkEvent, HitLocation, UE.FRotator(0, 0, 0), true, "")

            elseif self.LastCollidedActor then
                -- end loop                
                G.log:info("[hycoldrain]", "BeamFxAudioComponent:end loop--- collide actor ")
                self:StopBeamCollideLoopAudio()
            end
        end

        --3. on collide audio
        if CollidedActor ~= self.LastCollidedActor then
            local PostEventAtLocationAsyncNode =  UE.UPostEventAtLocationAsync.PostEventAtLocationAsync(self.actor, self.CollideAkEvent, HitLocation, UE.FRotator(0, 0, 0))
            PostEventAtLocationAsyncNode:Activate()
            self.LastCollidedActor = CollidedActor
        end
    end
end


decorator.message_receiver()
function BeamFxAudioComponent:OnSwitchActivateState(value)
    if value then
        self:StartBeamLoopAudio()
    else
        self:StopBeamLoopAudio()
        self:StopBeamCollideLoopAudio()
    end
end


function BeamFxAudioComponent:StartBeamLoopAudio()
    local SpawnLocation = self.actor:K2_GetActorLocation()
    -- 1. start audio
    local PostEventAtLocationAsyncNode =  UE.UPostEventAtLocationAsync.PostEventAtLocationAsync(self.actor, self.StartAkEvent, SpawnLocation, UE.FRotator(0, 0, 0))
    PostEventAtLocationAsyncNode:Activate()
    -- 2. loop audio
    if self.LoopAkComponent then
        self.LoopAkComponent:K2_DestroyComponent(self.LoopAkComponent)
    end
    self.LoopAkComponent = UE.UAkGameplayStatics.SpawnAkComponentAtLocation(self.actor, self.LoopAkEvent, SpawnLocation, UE.FRotator(0, 0, 0), true, "")
end

function BeamFxAudioComponent:StopBeamLoopAudio()
    if self.LoopAkComponent then
        self.LoopAkComponent:K2_DestroyComponent(self.LoopAkComponent)
        self.LoopAkComponent = nil
    end
end

function BeamFxAudioComponent:StopBeamCollideLoopAudio()
    if self.CollideLoopAkComponent then
        self.CollideLoopAkComponent:K2_DestroyComponent(self.CollideLoopAkComponent)
        self.CollideLoopAkComponent = nil
    end
end

decorator.message_receiver()
function BeamFxAudioComponent:OnRecieveCollideUpdate(StartLocation , EndLocation, HitLocation)
    if self.CollideLoopAkComponent and self.CollideLoopAkComponent:IsValid() then
        local HitResult = UE.FHitResult() 
        self.CollideLoopAkComponent:K2_SetWorldLocation(HitLocation, false, HitResult, false)
    end
    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    if CameraManager then
        local ListenerLocation = CameraManager:GetCameraLocation()
        self:UpdateBeamLoopAudioEmitterLocation(ListenerLocation, StartLocation, EndLocation)
    end
end


function BeamFxAudioComponent:UpdateBeamLoopAudioEmitterLocation(ListenerLocation, StartLocation, EndLocation )    
    if self.LoopAkComponent and self.LoopAkComponent:IsValid() then       
        local EmitterLocation = UE.UKismetMathLibrary.FindClosestPointOnSegment(ListenerLocation, StartLocation, EndLocation)
        local HitResult = UE.FHitResult() 
        self.LoopAkComponent:K2_SetWorldLocation(EmitterLocation, false, HitResult, false)
    end
end


return BeamFxAudioComponent
