--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/05/15
--

---@type

require "UnLua"
local G = require("G")
local ActorBase = require("actors.common.interactable.base.base_item")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:UserConstructionScript()
    Super(M).UserConstructionScript(self)
end

function M:ReceiveBeginPlay()
    self:SetInteractedItemCollisionAll()
    Super(M).ReceiveBeginPlay(self)
    if self.Sphere then
        self.Sphere.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap_Sphere)
        self.Sphere.OnComponentEndOverlap:Add(self, self.OnEndOverlap)
    end
    if self.Box then
        self.Box.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap_Box)
        self.Box.OnComponentEndOverlap:Add(self, self.OnEndOverlap)
    end
end

function M:GetInteractable()
    return self.eInteractedItemStatus == Enum.E_InteractedItemStatus.Interactable
end

function M:SetInteractable(bInteractable)
    self:LogInfo('zsf', '[interacted_item] %s SetInteractable %s', G.GetDisplayName(self), bInteractable)
    -- Enum.E_InteractedItemStatus.Interactable
    -- Enum.E_InteractedItemStatus.UnInteractable
    self.eInteractedItemStatus = bInteractable
end

function M:OnBeginOverlap_Box(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    self:LogInfo('zsf', '[interacted_item] OnBeginOverlap_Box %s', G.GetDisplayName(self))
    self:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
end

function M:OnBeginOverlap_Sphere(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    self:LogInfo('zsf', '[interacted_item] OnBeginOverlap_Sphere %s', G.GetDisplayName(self))
    self:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
end

function M:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    self:LogInfo('zsf', '[interacted_item] %s %s %s %s', OverlappedComponent, G.GetDisplayName(OtherActor), G.GetDisplayName(OtherComp), self.Sphere:GetCollisionEnabled())
    --self:Client_AddInitationScreenUI_RPC()
    if self:IsClient() or UE.UKismetSystemLibrary.IsStandalone(self) then
        if OtherComp and OtherComp.ComponentTags then
            for Ind = 1, OtherComp.ComponentTags:Length() do
                local Tag = OtherComp.ComponentTags:Get(Ind)
                if Tag == "AreaAbilityCollisionComp" then -- 区域能力不参与交互物逻辑
                    return
                end
            end
        end
        if self.eInteractedItemStatus ~= Enum.E_InteractedItemStatus.UnInteractable then -- 交互物设置为不可交互
            local playerActor = self:GetPlayerActor(OtherActor)
            if playerActor and playerActor.EdRuntimeComponent then
                if playerActor.EdRuntimeComponent.bInAreaAbility then
                    return
                end
                playerActor.EdRuntimeComponent:AddNearbyActor(self)
            end
        end
    end
    -- If have InActive2Active, when overlap triggered active this status
    if self.Call_StatusFlow_Func then
        if not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.InActive2Active) then
            self:Call_StatusFlow_Func(Enum.E_StatusFlow.InActive2Active)
        end
    end
end

function M:OnEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    self:LogInfo('zsf', '[interacted_item] OnEndOverlap %s', G.GetDisplayName(self))
    --self:Client_RemoveInitationScreenUI()
    if self:IsClient() or UE.UKismetSystemLibrary.IsStandalone(self) then
        local playerActor = self:GetPlayerActor(OtherActor)
        if playerActor then
            playerActor.EdRuntimeComponent:RemoveNearbyActor(self)
        end
    end
    -- If have InActive2Active, when overlap triggered active this status
    if self.Call_StatusFlow_Func then
        if not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.Active2InActive) then
            self:Call_StatusFlow_Func(Enum.E_StatusFlow.Active2InActive)
        end
    end
end

---@param InvokerActor AActor
---@param InteractLocation Vector
function M:DoClientInteractActionWithLocation(InvokerActor, Damage, InteractLocation)
    self:LogInfo('zsf', '[interacted_item] %s Interact with %s %s %s', G.GetDisplayName(InvokerActor), G.GetDisplayName(self), Damage, InteractLocation)
    if not self:HasAuthority() and self:GetInteractable() and InvokerActor then
        ---@type BP_ThirdPersonCharacter_C
        local playerActor = self:GetPlayerActor(InvokerActor)
        if playerActor then
            Damage = Damage and Damage or 100.0
            playerActor.EdRuntimeComponent:Server_InteractEvent(self, Damage, InteractLocation)
        end
    end
end

---@param InvokerActor AActor
function M:DoClientInteractAction(InvokerActor)
   self:DoClientInteractActionWithLocation(InvokerActor, 100.0, UE.FVector(0.0, 0.0, 0.0))
end

-- called by ServerInteractEvent
---@param InvokerActor AActor
---@param Damage float
---@param InteractLocation Vector
function M:DoServerInteractAction(InvokerActor, Damage, InteractLocation)
    if self:HasAuthority() and self:GetInteractable() then
        ---@type BP_ThirdPersonCharacter_C
        local PlayerActor = self:GetPlayerActor(InvokerActor)
        if PlayerActor then
            self:LogInfo('zsf', '[interacted_item] %s Interact with %s', G.GetDisplayName(PlayerActor), G.GetDisplayName(self))
            self:TriggerInteractedItem(PlayerActor, Damage, InteractLocation)
        end
    end
end

function M:AddInitationScreenUIOnClient()
    --G.log:debug("zsf", "Client_AddInitationScreenUI_RPC %s %s", Enum.E_InteractedItemStatus.UnInteractable, self.eInteractedItemStatus)
    --if self:IsClient() or UE.UKismetSystemLibrary.IsStandalone(self) then
    --    if self.eInteractedItemStatus ~= Enum.E_InteractedItemStatus.UnInteractable then -- 交互物设置为不可交互
    --        local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    --        Player:SendControllerMessage("AddInitationScreenUI", self)
    --    end
    --end
    local localPlayerActor = G.GetPlayerCharacter(self, 0)
    if localPlayerActor then
        localPlayerActor.EdRuntimeComponent:AddNearbyActor(self)
    end
end

function M:RemoveInitationScreenUIOnClient()
    --if self:IsClient() or UE.UKismetSystemLibrary.IsStandalone(self) then
    --    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    --    Player:SendControllerMessage("RemoveInitationScreenUI", self)
    --end
    local localPlayerActor = G.GetPlayerCharacter(self, 0)
    if localPlayerActor then
        localPlayerActor.EdRuntimeComponent:RemoveNearbyActor(self)
    end
end

function M:ReceiveEndPlay()
    if self.Sphere then
        self.Sphere.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_Sphere)
        self.Sphere.OnComponentEndOverlap:Remove(self, self.OnEndOverlap)
    end
    if self.Box then
        self.Box.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_Box)
        self.Box.OnComponentEndOverlap:Remove(self, self.OnEndOverlap)
    end
    Super(M).ReceiveEndPlay(self)
end

---@param Damage float
function M:TriggerInteractedItem(PlayerActor, Damage, InteractLocation, bAttack)
    -- 这个交互的伤害先写死，表示交互一次就完成；之后可能存在攻击交互物按照血量来完成
    --local Damage = 100.0
    if PlayerActor and PlayerActor.EdRuntimeComponent then
        self:LogInfo("zsf", "TriggerInteractedItem %s %s %s", G.GetDisplayName(PlayerActor), Damage, InteractLocation)
        PlayerActor.EdRuntimeComponent:Server_ReceiveDamage(self, Damage, InteractLocation, bAttack)
    end
end

function M:GetUIShowActors()
    return {self}
end

function M:ReceiveDamageOnMulticast(PlayerActor, InteractLocation, bAttack)
    if self.Call_StatusFlow_Func then
        if not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.InActive2Complete) then
            self:Call_StatusFlow_Func(Enum.E_StatusFlow.InActive2Complete)
        elseif not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.Active2Complete) then
            self:Call_StatusFlow_Func(Enum.E_StatusFlow.Active2Complete)
        end
    end
    if not self:IsClient() then
        return
    end
    self:Client_RemoveInitationScreenUI()
end

function M:ReceiveDestroyed()
    --self:LogInfo("zsf", "ReceiveDestroyed")
    if self:IsClient() then
        if self.Client_RemoveInitationScreenUI then
            self:Client_RemoveInitationScreenUI()
        end
    end
    Super(M).ReceiveDestroyed(self)
end

function M:SetInteractedItemCollisionSingle(bIsShow, Collision)
    if bIsShow then
        Collision:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
        Collision:SetVisibility(true, false)
    else
        Collision:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        Collision:SetVisibility(false, false)
    end
end

function M:SetInteractedItemCollision(eInteractedItemCollision)
    self.eInteractedItemCollision = eInteractedItemCollision
end

function M:GetInteractedItemCollision()
    return self.eInteractedItemCollision
end

function M:SetInteractedItemCollisionAll()
    if self.eInteractedItemCollision ==  Enum.E_InteractedItemCollision.Sphere then
        self:SetInteractedItemCollisionSingle(true, self.Sphere)
        self:SetInteractedItemCollisionSingle(false, self.Box)
    elseif self.eInteractedItemCollision == Enum.E_InteractedItemCollision.Box then
        self:SetInteractedItemCollisionSingle(false, self.Sphere)
        self:SetInteractedItemCollisionSingle(true, self.Box)
    elseif self.eInteractedItemCollision == Enum.E_InteractedItemCollision.None then
        self:SetInteractedItemCollisionSingle(false, self.Sphere)
        self:SetInteractedItemCollisionSingle(false, self.Box)
    end
end

function M:OnClientUpdateGameplayVisibility()
    Super(M).OnClientUpdateGameplayVisibility(self)
    if self:IsGameplayVisible() then
        self:SetInteractedItemCollision(Enum.E_InteractedItemCollision.Sphere)
    else
        self:SetInteractedItemCollision(Enum.E_InteractedItemCollision.None)
    end
    self:SetInteractedItemCollisionAll()
end

function M:GetBillboardComponent()
    return self.BillboardComponent
end

return M