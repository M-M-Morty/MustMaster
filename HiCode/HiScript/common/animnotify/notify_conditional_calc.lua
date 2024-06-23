
local G = require("G")
check_table = require("common.data.state_conflict_data")


local NotifyConditionalCalc = Class()

function NotifyConditionalCalc:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if Owner and UE.UKismetSystemLibrary.IsValid(Owner) then
        local CI = self.NegativeCalc
        if Owner.BuffComponent and Owner.BuffComponent:HasBuff(self.Buff) then
            CI = self.PositiveCalc
        end

        -- 发送结算事件
        local KnockInfoObj = SkillUtils.KnockInfoStructToObject(CI.KnockInfo)
        local EventTag = CI.EventTag

        local Data = UE.FGameplayEventData()
        Data.EventTag = EventTag
        Data.OptionalObject = KnockInfoObj
        UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(Owner, EventTag, Data)
    end
end

return NotifyConditionalCalc
