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
local utils = require("common.utils")

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
    if self:HasAuthority() then
        return
    end
    local AnimInstance = self.SkeletalMesh:GetAnimInstance()
    if AnimInstance then
        AnimInstance:SetOpen(bIsOpen)
    end
    if bIsOpen then
        self.NS_AreaLightTenMang_Close:SetVisibility(false)
        self.NS_AreaLightTenMang_Close:SetActive(false, false)
        self.NS_AreaLightTenMang_Light:SetActive(true, true)
        self.NS_AreaLightTenMangSmoke_Burst:SetActive(true, true)
    else
        self.NS_AreaLightTenMang_Close:SetVisibility(true)
        self.NS_AreaLightTenMang_Close:SetActive(true, true)
        self.NS_AreaLightTenMang_Light:SetActive(false, false)
        self.NS_AreaLightTenMangSmoke_Burst:SetActive(false, false)
    end
    self:SwitchMaterial(bIsOpen)
end

function M:TryClose()
    --timerhandle管理的delegant function在K2_ClearTimerHandle之后还会执行一次，原因未知
    if self.TimerHandle == nil then
        return
    end
    
    local bEffectLasting = self:CheckEffectLasting(Enum.E_AreaAbility.Light)
    self:LogWarn("ys","delay %d, bEffectLasting %s",self.bCloseDelay,bEffectLasting)
    self:Multicast_PlayAnimLighting(bEffectLasting, self.bPlaying)

    if bEffectLasting == false then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self,self.TimerHandle)
        self.TimerHandle = nil
    end
end

function M:Multicast_PlayAnimLighting_RPC(bUsing, bPlaying)
    --self:LogInfo("zsf", "dougzhang88 SetCollisionEnabled %s %s %s %s %s", bUsing, bPlaying, G.GetDisplayName(self), self.bPlaying, self.bAnimOpen ~= bUsing )
    self:LogWarn("ys","Multicast_PlayAnimLighting : %s %s",bUsing,bPlaying)
    if not bPlaying and self.bAnimOpen ~= bUsing then
        self.bPlaying = true
        self.bAnimOpen = bUsing
        local Montage = self.AnimOpen
        if bUsing then
            Montage = self.AnimClose
        end
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.SkeletalMesh, Montage, 1.0)
        local updateStatue = function()
            self.bPlaying = false
            local OverlappedActors = UE.TArray(UE.AActor)

            if self:HasAuthority() then
                --self:LogInfo("zsf", "dougzhang88 SetCollisionEnabled 22 %s %s %s", bEffectLasting, bUsing, G.GetDisplayName(self))
                if (self.bCloseDelay == -1 and bEffectLasting) or -- 永远不关只接受，开的指令
                    (self.bCloseDelay ~= -1) then
                    local DelayTime = self.bCloseDelay == -1 and 0 or self.bCloseDelay
                    
                    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TryClose}, DelayTime, true)
                end
            end
        end

        if bUsing then
            self.BoxCollision:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        else
            self.BoxCollision:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        end

        local AnimInstance = self.SkeletalMesh:GetAnimInstance()
        if AnimInstance then
            local CurrentActiveMontage = AnimInstance:GetCurrentActiveMontage()
            if CurrentActiveMontage then
                local MontageLength = CurrentActiveMontage:GetPlayLength()
                utils.DoDelay(self:GetWorld(), MontageLength, function()
                    updateStatue()
                end)
            end
        end
        self.bIsOpen = bUsing
        self:SetOpen(bUsing)
        if not self:HasAuthority() then
            if bUsing then
                HiAudioFunctionLibrary.PlayAKAudio("Scn_Itm_TreeRoot_Open", self)
            else
                HiAudioFunctionLibrary.PlayAKAudio("Scn_Itm_TreeRoot_Close", self)
            end
        end
        if self:HasAuthority() then
            self.Event_AreaAbilityDarkThronsLighting:Broadcast(self:GetEditorID())
        end
    end
end

function M:ResponseAreaAbility_Light(bUsing)
    if self:HasAuthority() then
        self:Multicast_PlayAnimLighting(bUsing, self.bPlaying)
    end
end

return M
