--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")


---@type SwitchSimulatePhysicsComponent
local SwitchSimulatePhysicsComponent = Component(ComponentBase)
local decorator = SwitchSimulatePhysicsComponent.decorator


function SwitchSimulatePhysicsComponent:Start()
    Super(SwitchSimulatePhysicsComponent).Start(self)
    self.TimerHandle = nil    
end

function SwitchSimulatePhysicsComponent:Stop()
    Super(SwitchSimulatePhysicsComponent).Stop(self)
    self:StopCheckTimer()
end


decorator.message_receiver()
function SwitchSimulatePhysicsComponent:AddBlastEventListener(BlastDelegate)
    if BlastDelegate then       
        BlastDelegate:Add(self, self.OnStartBlastHappen)        
    end
end

decorator.message_receiver()
function SwitchSimulatePhysicsComponent:RemoveBlastEventListener(BlastDelegate)
    if BlastDelegate then    
        BlastDelegate:Remove(self, self.OnStartBlastHappen)    
    end
end


decorator.message_receiver()
function SwitchSimulatePhysicsComponent:OnActorDropEvent()
    if self.actor and self.actor:GetComponentByClass(UE.USkeletalMeshComponent) then
        local Mesh = self.actor:GetComponentByClass(UE.USkeletalMeshComponent)
        --G.log:debug("hycoldrain", "OnStartBlastHappen %s ", G.GetDisplayName(Mesh))       
        Mesh:SetSimulatePhysics(true)
        self:StartCheckTimer()
    end  
end

function SwitchSimulatePhysicsComponent:OnStartBlastHappen()    
    self:OnActorDropEvent()
end


function SwitchSimulatePhysicsComponent:StartCheckTimer()
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnCheckingHitEvent}, 0.01, true)
    self:OnCheckingHitEvent()
end

function SwitchSimulatePhysicsComponent:StopCheckTimer()
    if self.TimerHandle ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
        self.TimerHandle = nil
    end
end

function SwitchSimulatePhysicsComponent:OnCheckingHitEvent()
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)
    local ActorsToIgnore = UE.TArray(UE.AActor)    

    local Start = self.actor.SkeletalMesh:K2_GetComponentLocation()
    local End = Start - UE.FVector(0.0, 0.0, 0.05)    
    local Origin, HalfSize = self.actor:GetActorBounds()
    local Orientation = UE.FRotator()

    local HitResult = UE.FHitResult()
    UE.UKismetSystemLibrary.BoxTraceSingleForObjects(self.actor, Start, End, HalfSize, Orientation, ObjectTypes, false, ActorsToIgnore,  UE.EDrawDebugTrace.ForDuration, HitResult, true)
    G.log:debug("hycoldrain", "OnCheckingHitEvent ")
    if HitResult.bBlockingHit then
        G.log:debug("hycoldrain", "OnCheckingHitEvent ")
        self:StopCheckTimer()
        local Location = HitResult.Location
        local Direction = HitResult.Normal
        self.actor.InstaDeform:OnHitByLine(Location, Direction)
    end
end

return SwitchSimulatePhysicsComponent