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
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local HudTrackVMModule = require('CP0032305_GH.Script.viewmodel.ingame.hud.hud_track_vm')

---@type InteractTrackArrowComponent_C
local InteractTrackArrowComponent = Component(ComponentBase)

function InteractTrackArrowComponent:Initialize(Initializer)
    Super(InteractTrackArrowComponent).Initialize(self, Initializer)
    self.DisplaySphere = nil    -- client
    self.DisplayPlayer = nil    -- client
    self.TrackWrapper = nil     -- client
end

function InteractTrackArrowComponent:ReceiveBeginPlay()
    Super(InteractTrackArrowComponent).ReceiveBeginPlay(self)
    if self.actor:IsClient() then
        if self.bTrapEnabled and self.actor:IsGameplayVisible() then
            self:EnableDisplayTrap()
        end
    end
end

-- server
function InteractTrackArrowComponent:EnableTrack()
    if self.bShowTrack then
        self.bTrapEnabled = true
    end
end

-- server
function InteractTrackArrowComponent:DisableTrack()
    if self.bShowTrack then
        self.bTrapEnabled = false
    end
end

-- client
function InteractTrackArrowComponent:EnableDisplayTrap()
    if self.DisplaySphere == nil then
        self.DisplaySphere = self.actor:AddComponentByClass(UE.USphereComponent, false, UE.FTransform.Identity, false)
        self.DisplaySphere.OnComponentBeginOverlap:Add(self, self.OnDisplaySphereBeginOverlap)
        self.DisplaySphere.OnComponentEndOverlap:Add(self, self.OnDisplaySphereEndOverlap)
        self.DisplaySphere:SetCollisionProfileName("TrapActor", true)
        self.DisplaySphere:SetSphereRadius(self.ShowRadius, true)
    else
        self.DisplaySphere:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        self.DisplaySphere:SetVisibility(true, false)
    end
end

-- client
function InteractTrackArrowComponent:DisableDisplayTrap()
    if self.DisplaySphere ~= nil then
        self.DisplaySphere:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        self.DisplaySphere:SetVisibility(false, false)
    end
end

-- client
function InteractTrackArrowComponent:OnRep_bTrapEnabled()
    if self.enabled then
        if self.bTrapEnabled and self.actor:IsGameplayVisible() then
            self:EnableDisplayTrap()
        else
            self:DisableDisplayTrap()
        end
    end
end

-- client
function InteractTrackArrowComponent:OnDisplaySphereBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    G.log:debug("xaelpeng", "InteractTrackArrowComponent:OnDisplaySphereBeginOverlap %s", OtherActor:GetName())
    if OtherActor.IsPlayer ~= nil and OtherActor:IsPlayer() then
        self.DisplayPlayer = OtherActor
        if self.ShowType == Enum.Enum_TrackArrowType.TreasureBox then
            self.TrackWrapper = HudTrackVMModule.TreasureBoxTrackTargetWrapper.new(self.actor)
        elseif self.ShowType == Enum.Enum_TrackArrowType.Badieta then
            self.TrackWrapper = HudTrackVMModule.BadietaTrackTargetWrapper.new(self.actor)
        elseif self.ShowType == Enum.Enum_TrackArrowType.SpecialIcon then
            self.TrackWrapper = HudTrackVMModule.SpecialIconTrackTargetWrapper.new(self.actor, self.ShowIcon)
        else
            return
        end
        local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
        if HudTrackVM then
            HudTrackVM:AddTrackActor(self.TrackWrapper)
        end
    end
end

-- client
function InteractTrackArrowComponent:OnDisplaySphereEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    G.log:debug("xaelpeng", "InteractTrackArrowComponent:OnDisplaySphereEndOverlap %s", OtherActor:GetName())
    if self.DisplayPlayer == OtherActor then
        self.DisplayPlayer = nil
        if self.TrackWrapper == nil then
            return
        end
        local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
        if HudTrackVM then
            HudTrackVM:RemoveTrackActor(self.TrackWrapper)
        end
        self.TrackWrapper = nil
    end
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

return InteractTrackArrowComponent
