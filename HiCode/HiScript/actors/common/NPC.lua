--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BPA_NPCBase_C
require "UnLua"
local G = require("G")


local BPConst = require("common.const.blueprint_const")
local ActorBase = require("actors.common.interactable.base.base_character")

local NPC = Class(ActorBase)
local utils = require("common.utils")

NPC.EntityServiceName = ""
NPC.EntityPropertyMessageName = "Npc"

function NPC:GetSaveDataClass()
    return BPConst.GetNPCBaseSaveDataClass()
end

-- function NPC:LoadFromSaveData(SaveData)
--     self.VisibilityManagementComponent.bVisibilityInGameplay = not SaveData.bHiddenInGame
-- end

-- function NPC:SaveToSaveData(SaveData)
--     SaveData.bHiddenInGame = not self.VisibilityManagementComponent.bVisibilityInGameplay
-- end

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function NPC:ReceiveBeginPlay()
    Super(NPC).ReceiveBeginPlay(self)
    if self.AudioLoop and self.AudioLoop ~= "" then
        if self:IsClient() then
            self.AudioTickHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.AudioTick}, self.AudioDuration, true)
        end
    end
    -- Wait Components BeginPlay
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.PostBeginPlay}, 0.01, false)
end

function NPC:PostBeginPlay()
    self:SendMessage("PostBeginPlay")
end

function NPC:AudioTick()
    HiAudioFunctionLibrary.PlayAKAudio(self.AudioLoop, self)
end

function NPC:GetActorID()
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local MutableActorComponent = self:GetComponentByClass(MutableActorComponentClass)
    return MutableActorComponent:GetActorID()
end

function NPC:GetNpcId()
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local MutableActorComponent = self:GetComponentByClass(MutableActorComponentClass)
    return MutableActorComponent:GetActorTypeID()
end

function NPC:GetNpcDisplayName()
    return self.DisplayName
end

-- server
function NPC:SetNpcDisplayName(DisplayName)
    -- todo 根据正式需求修改为ID
    self.DisplayName = DisplayName
    self:SendMessage("OnNpcDisplayNameUpdate")
end

function NPC:GetNpcDisplayIdentity()
    return self.DisplayIdentity
end

-- client
function NPC:OnRep_DisplayName()
    self:SendMessage("OnNpcDisplayNameUpdate")
end

function NPC:SetToplogoImgPath(ToplogoImagePath)
end

function NPC:GetNpcSelfTalkingID()
    return self.SelfTalkingID
end


function NPC:GetDialogueComponent()
    return self.DialogueComponent
end

function NPC:GetNpcBehaviorComponent()
    return self.NpcBehaviorComponent
end

function NPC:GetBillboardComponent()
    return self.BillboardComponent
end

-- suppport for VisibilityManagementComponent
function NPC:IsGameplayVisible()
    return self.VisibilityManagementComponent.bVisibilityInGameplay
end
function NPC:SetCollisionEnabled(NewType)
    utils.SetActorCollisionEnabled(self, NewType)
end
function NPC:OnClientUpdateGameplayVisibility()
end



 function NPC:ReceiveEndPlay()
     if self.AudioTickHandle ~= nil then
         UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.AudioTickHandle)
         self.AudioTickHandle = nil
     end
     Super(NPC).ReceiveEndPlay(self)
 end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return NPC

