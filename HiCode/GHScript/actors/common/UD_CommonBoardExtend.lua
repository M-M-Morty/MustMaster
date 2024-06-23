

---@type UD_CommonBoardExtend_C
local UD_CommonBoardExtend_C = Class()

function UD_CommonBoardExtend_C:GetSkillCastTime(skillKey)
    local time = self.SkillCastTime:Find(skillKey)
    return time
end
function UD_CommonBoardExtend_C:SetSkillCastTime(skillKey, time)
    time = time or UE.UGameplayStatics.GetTimeSeconds(self)
    self.SkillCastTime:Add(skillKey, time)
end


function UD_CommonBoardExtend_C:SetActions(actions)
    self.actions:Clear()
    local length = actions:Length()
    if length > 0 then
        for i = 1, length do
            self.actions:Add(actions:Get(i))
        end
    end
end
function UD_CommonBoardExtend_C:TryInitActions(actions)
    if self.actions:Length() < 1 then
        self:SetActions(actions)
    end
end


return UD_CommonBoardExtend_C
