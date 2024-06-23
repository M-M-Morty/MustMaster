--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local GA_GH_CommonBase = require('CP0032305_GH.Script.skill.ability.GA_GH_CommonBase')

---@type GA_Mecha_Skill_04_C
local GA_Mecha_Skill_04_C = Class(GA_GH_CommonBase)


function GA_Mecha_Skill_04_C:K2_ActivateAbility()
    self:K2_CommitAbility()

    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, nil, self.MontageToPlay, 1.0, nil, true, 1.0, 0)
    self:RefTask(PlayTask)
    PlayTask.OnCompleted:Add(self, self.OnCompleted_Default)
    --PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
    PlayTask.OnInterrupted:Add(self, self.OnInterrupted_Default)
    PlayTask.OnCancelled:Add(self, self.OnCancelled_Default)
    PlayTask:ReadyForActivation()

    self:WaitHandleDamage()
    self:WaitHandleTurn()

    local graspTag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.Common.a')
    local waitTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, graspTag, nil, false, true)
    self:RefTask(waitTask)
    waitTask.EventReceived:Add(self, self.OnEventReceived_Grasp)
    waitTask:ReadyForActivation()
end

function GA_Mecha_Skill_04_C:OnCompleted_Default()
    self:K2_EndAbility(false)
end
function GA_Mecha_Skill_04_C:OnInterrupted_Default()
    self:K2_EndAbility(false)
end
function GA_Mecha_Skill_04_C:OnCancelled_Default()
    self:K2_EndAbility(false)
end

function GA_Mecha_Skill_04_C:OnEventReceived_Grasp()
    self:getTinObject()
end

--技能抓取的脚本处理
function GA_Mecha_Skill_04_C:getTinObject()
    local selfActor = self:GetAvatarActorFromActorInfo()

    local tinComp = selfActor.TinObj
    self.tinActor = selfActor:GetWorld():SpawnActor(self.Grasp_Tin_C, tinComp:K2_GetComponentToWorld(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, selfActor)
    self.tinActor:K2_AttachToComponent(selfActor.Mesh, 'lf_hand_slot', UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepWorld)
    
    self.tinActor:K2_SetActorRelativeLocation(UE.FVector(-25, 30, 10), false, nil, true) --x:上下,y:左右,z:前后
    self.tinActor:K2_SetActorRelativeRotation(UE.FRotator(90, 0, 0), false, nil, true)
    
    --selfActor.TinObj:SetVisibility(false, false)
    selfActor:TryRemoveTinObj()
end

function GA_Mecha_Skill_04_C:dropTinObject(projectileObj)
    projectileObj.tinActor = self.tinActor --权责传递出去
    self.tinActor = nil
end

function GA_Mecha_Skill_04_C:restoreTinObject()
    local selfActor = self:GetAvatarActorFromActorInfo()
    --selfActor.TinObj:SetVisibility(true, false)]]
    selfActor:TryRestoreTinObj()

    if self.tinActor and self.tinActor:IsValid() then
        self.tinActor:K2_DestroyActor()
    end
end

function GA_Mecha_Skill_04_C:K2_OnEndAbility(bWasCancelled)
    Super(GA_Mecha_Skill_04_C).K2_OnEndAbility(self, bWasCancelled)

    self:restoreTinObject()
end


return GA_Mecha_Skill_04_C

