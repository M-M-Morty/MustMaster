--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/04/19
--

---@type BP_SightPillar_C
local G = require("G")
local os = require("os")
local table = require("table")

require "UnLua"
local ActorBase = require("actors.common.interactable.base.base_item")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:ReceiveBeginPlay()
    self:SetOpen(self.bIsOpen)
    Super(M).ReceiveBeginPlay(self)
end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
end

function M:SetOpen(bIsOpen)
    local AnimInstance = self.SkeletalMesh:GetAnimInstance()
    AnimInstance:SetOpen(bIsOpen)
    if bIsOpen then
        self.NS_AreaLightFlower_Open:SetVisibility(true)
        self.NS_AreaLightFlower_Close:SetVisibility(false)
        self.NS_AreaLightFlower_Open:SetActive(true, true)
    else
        self.NS_AreaLightFlower_Open:SetVisibility(false)
        self.NS_AreaLightFlower_Close:SetVisibility(true)
        self.NS_AreaLightFlower_Close:SetActive(true, true)
    end
end

---@param eAreaAbility ENUM
---@param bUsing bool
function M:UseAreaAbility(eAreaAbility, bUsing)
    Super(M).UseAreaAbility(self, eAreaAbility, bUsing)
    self:LogInfo("zsf", "UseAreaAbility %s %s %s", eAreaAbility, bUsing, G.GetDisplayName(self))
    if eAreaAbility == Enum.E_AreaAbility.Lighting then
        --local AnimLength = self:AreaAbility_Lighting_PlayAnim(bUsing)
        if not self.bAlwaysOpen or (self.bAlwaysOpen and bUsing) then
            if self:HasAuthority() then
                self.Event_AreaAbilityFlowLighting:Broadcast(self:GetEditorID())
            end
            self.bIsOpen = bUsing
            self:SetOpen(self.bIsOpen)
            if bUsing then
                if not self:HasAuthority() then
                    HiAudioFunctionLibrary.PlayAKAudio("Scn_Itm_Flower_Open", self)
                end
            else
                if not self:HasAuthority() then
                    HiAudioFunctionLibrary.PlayAKAudio("Play_Scn_Itm_Flower_Close", self)
                end
            end
        end
    end
end

return M
