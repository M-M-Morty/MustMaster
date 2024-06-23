--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type ControlTips_C
local G = require("G")
local ActorBase = require("actors.common.interactable.base.base_item")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local GuideTextTable = require("common.data.guide_text_data").data

---@type ControlTips_C
local ControlTipsTrap = Class(ActorBase)

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function ControlTipsTrap:ReceiveBeginPlay()
    Super(ControlTipsTrap).ReceiveBeginPlay(self)
    if self:IsClient() then
        self.DisplaySphere = self:AddComponentByClass(UE.USphereComponent, false, UE.FTransform.Identity, false)
        self.DisplaySphere.OnComponentBeginOverlap:Add(self, self.OnDisplaySphereBeginOverlap)
        self.DisplaySphere.OnComponentEndOverlap:Add(self, self.OnDisplaySphereEndOverlap)
        self.DisplaySphere:SetCollisionProfileName("TrapActor", true)
        self.DisplaySphere:SetSphereRadius(self.DisplayRange, true)
        if not self:IsGameplayVisible() then
            self.DisplaySphere:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
            self.DisplaySphere:SetVisibility(false, false)
        end
    end
end

-- client
function ControlTipsTrap:OnDisplaySphereBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    G.log:debug("xaelpeng", "ControlTipsTrap:OnDisplaySphereBeginOverlap %s %s", OtherActor:GetName(), OtherComp:GetName())
    if OtherActor.IsPlayer ~= nil and OtherActor:IsPlayer() then
        self.InteractPlayer = OtherActor

        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        if HudMessageCenterVM then
            local Callback = function()
                self:HideControlTips()
            end

            HudMessageCenterVM:ShowControlTips(GuideTextTable[self.ControllDescriptionID].Content, G.GetObjectName(self.ControlKey), Callback)
        end

    end
end

-- client
function ControlTipsTrap:OnDisplaySphereEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    G.log:debug("xaelpeng", "ControlTipsTrap:OnInteractSphereEndOverlap %s", OtherActor:GetName())
    if self.InteractPlayer == OtherActor then
        self.InteractPlayer = nil
        self:HideControlTips()
    end
end

-- client
function ControlTipsTrap:HideControlTips()
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:HideControlTips()
    end

end

-- client
function ControlTipsTrap:OnClientUpdateGameplayVisibility()
    if self:IsGameplayVisible() then
        self.DisplaySphere:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        self.DisplaySphere:SetVisibility(true, false)
    else
        self.DisplaySphere:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        self.DisplaySphere:SetVisibility(false, false)
    end

end




-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return ControlTipsTrap
