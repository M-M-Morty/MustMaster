local string = require("string")
local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local DestructComponent = Component(ComponentBase)
local decorator = DestructComponent.decorator

function DestructComponent:Initialize(...)
    Super(DestructComponent).Initialize(self, ...)
end

function DestructComponent:ReceiveBeginPlay()
    Super(DestructComponent).ReceiveBeginPlay(self)
    self.__TAG__ = string.format("DestructComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
    self.CurDurability = self.Durability
end

---Hit this destructible, run on server.
---@param Instigator AActor hit instigator
---@param Causer AActor hit causer (weapon .etc.)
---@param Hit FHitResult including hit info
---@param Durability number hit durability, if < defend hit will be ignored.
function DestructComponent:Hit(Instigator, Causer, Hit, Durability)
    if not self.actor or not self.actor:IsServer() then
        return
    end

    if Durability < self.Defend then
        return
    end

    self.CurDurability = math.max(0, self.CurDurability - Durability)

    if self.CurDurability <= 0 then
        self:Multicast_OnBreak(Instigator, Causer, Hit, Durability)
    else
        self:Multicast_OnHit(Instigator, Causer, Hit, Durability, self.CurDurability)
    end
end

function DestructComponent:Multicast_OnHit_RPC(Instigator, Causer, Hit, Durability, RemainDurability)
    --G.log:debug(self.__TAG__, "OnHit instigator: %s, Causer: %s, Durability: %f, Remain: %f", G.GetObjectName(Instigator), G.GetObjectName(Causer), Durability, RemainDurability)

    local DestructibleInterface = UE.UClass.Load("/Game/Blueprints/Destructible/BPI_Destructible.BPI_Destructible_C")
    if UE.UKismetSystemLibrary.IsValid(self.actor) and  UE.UKismetSystemLibrary.DoesImplementInterface(self.actor, DestructibleInterface) then
        self.actor:OnHit(Instigator, Causer, Hit, Durability, RemainDurability)
    else
        G.log:warn(self.__TAG__, "OnHit %s not implement destructible interface", G.GetObjectName(self))
    end
end

function DestructComponent:Multicast_OnBreak_RPC(Instigator, Causer, Hit, Durability)
    -- G.log:debug(self.__TAG__, "OnBreak instigator: %s, Causer: %s, Durability: %f", G.GetObjectName(Instigator), G.GetObjectName(Causer), Durability)

    local DestructibleInterface = UE.UClass.Load("/Game/Blueprints/Destructible/BPI_Destructible.BPI_Destructible_C")
    if UE.UKismetSystemLibrary.IsValid(self.actor) and UE.UKismetSystemLibrary.DoesImplementInterface(self.actor, DestructibleInterface) then
        self.actor:OnBreak(Instigator, Causer, Hit, Durability)
    else
        G.log:warn(self.__TAG__, "OnBreak %s not implement destructible interface", G.GetObjectName(self))
    end
end

return DestructComponent
