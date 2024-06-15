--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")


---@type VisibilityManagementComponent_C
local VisibilityManagementComponent = Component(ComponentBase)

-- function M:Initialize(Initializer)
-- end

function VisibilityManagementComponent:ReceiveBeginPlay()
    Super(VisibilityManagementComponent).ReceiveBeginPlay(self)
    if self.actor:IsServer() then
        self.actor:SetActorHiddenInGame(not self.bVisibilityInGameplay)
    end
    if not self.bVisibilityInGameplay then
        self:DisableMovement()
        self.actor:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    end
end

-- client
function VisibilityManagementComponent:OnRep_bVisibilityInGameplay()
    if self.enabled then
        if self.bVisibilityInGameplay then
            self.actor:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        else
            self:DisableMovement()
            self.actor:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        end
        self.actor:OnClientUpdateGameplayVisibility()
        self:SendMessage("OnClientUpdateGameplayVisibility")
    end
end

function VisibilityManagementComponent:GetGameplayVisibility()
    return self.bVisibilityInGameplay
end

-- server
function VisibilityManagementComponent:SetGameplayVisibility(Visibility)
    G.log:debug("xaelpeng", "SetGameplayVisibility %s", self.actor:GetName(), Visibility)
    self.bVisibilityInGameplay = Visibility
    if self.enabled then
        self.actor:SetActorHiddenInGame(not self.bVisibilityInGameplay)
        if self.bVisibilityInGameplay then
            self.actor:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        else
            self:DisableMovement()
            self.actor:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        end
    end
end

function VisibilityManagementComponent:DisableMovement()
    local MovementComponent = self.actor:GetComponentByClass(UE.UCharacterMovementComponent)
    if MovementComponent then
        MovementComponent:DisableMovement()
    end
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

return VisibilityManagementComponent
