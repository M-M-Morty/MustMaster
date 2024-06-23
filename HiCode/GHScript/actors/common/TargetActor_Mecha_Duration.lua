

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')


---@type TargetActor_Mecha_Duration_C
local TargetActor_Mecha_Duration_C = Class()


function TargetActor_Mecha_Duration_C:OnStartTargeting(Ability)
    local avatar = self.OwningAbility:GetAvatarActorFromActorInfo()
    self:K2_AttachToActor(avatar, '', UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepRelative)
    self.bDestroyOnConfirmation = false
    self.damaged = {}
end

function TargetActor_Mecha_Duration_C:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)
end
function TargetActor_Mecha_Duration_C:ReceiveEndPlay(EndPlayReason)
    self.Overridden.ReceiveEndPlay(self, EndPlayReason)
end
function TargetActor_Mecha_Duration_C:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)

    if self.OwningAbility and self.vCollideActors:Length() > 0 then -- already after OnStartTargeting and need confirm
        local pickObjs = {}
        local Crash = false
        for i, obj in pairs(self.vCollideActors) do
            if FunctionUtil:IsPlayer(obj) then
                if not self:IsDamageExist(obj) then
                    table.insert(pickObjs, obj)
                end
            end
        end

        if Crash and self.OwningAbility.ApplyCrash then
            self.OwningAbility:ApplyCrash()
        end
        if #pickObjs > 0 then
            self.vCollideActors:Clear()
            for i , v in ipairs(pickObjs) do
                self.vCollideActors:Add(v)
                table.insert(self.damaged, v)
            end
            self:ConfirmTargeting();
        end

        self.vCollideActors:Clear()
    end
end

function TargetActor_Mecha_Duration_C:OnCollideActor(tarActor)
    --UnLua.LogWarn('TargetActor_Mecha_Duration_C:OnCollideActor', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(tarActor))

    if FunctionUtil:IsPlayer(tarActor) then
        self.vCollideActors:AddUnique(tarActor)
    end
end

function TargetActor_Mecha_Duration_C:IsDamageExist(obj)
    for i, v in ipairs(self.damaged) do
        if v == obj then
            return true
        end
    end
    return false
end



return TargetActor_Mecha_Duration_C

