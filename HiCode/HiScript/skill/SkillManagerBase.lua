
require "UnLua"

-- Unify ComboManager and single skill.
local G = require("G")
local SkillObj = require ("skill.SkillObj")
local SkillClimb = require ("skill.SkillClimb")
local SkillUtils = require("common.skill_utils")
local check_table = require("common.data.state_conflict_data")

local SkillManagerBase = Class()


function SkillManagerBase:ctor(InOwner, SkillID, SkillType)
    self.__TAG__ = "SkillManagerBase"
    self.Owner = InOwner
    self.actor = self.Owner.actor
    self.SkillDriver = self.Owner.SkillDriver
    self.SkillID = SkillID
    self.SkillType = SkillType
    self.StoryBoard = {}

    self:_init()
end

function SkillManagerBase:_init()
    if not self.SkillID then
        return
    end

    self.AbilityCDO = self.Owner:FindAbilityFromSkillID(self.SkillID)
    if not self.AbilityCDO then
        G.log:warn("SkillManagerBase", "SkillID %s not found CDO, perhaps not give?", tostring(self.SkillID))
        return
    end

    if self.AbilityCDO.bClimbAttack then
        self.Skill = SkillClimb.new(self.Owner, self.SkillID)
    else
        self.Skill = self.SkillDriver:InitSkillObj(self.SkillID)
    end
end

function SkillManagerBase:Start(SkillActivateCallbackOwner, SkillActivateCallback)
    if self.Skill then
        self.Skill:Start(SkillActivateCallbackOwner, SkillActivateCallback)
    end
end

function SkillManagerBase:KeyDown()
    G.log:warn("santi", "SkillManagerBase not implemented KeyDown invoked.")
    self:Start()
end

function SkillManagerBase:KeyUp()
    if self.Skill then
        local GA, _ = self.Skill:GetAbility()
        if GA.KeyUp then
            GA:KeyUp()
        end
    end
end

function SkillManagerBase:MarkSwitchOut()
    self.bSwitchOut = true
--    G.log:debug(self.__TAG__, "MarkSwitchOut: In MarkSwitchOut, Player : %s", GetObjectName(self.actor))
end
    
function SkillManagerBase:OnComboTail()
    G.log:info("SkillManagerBase", "OnComboTail")
    self.StoryBoard.InComboTail = true
end

function SkillManagerBase:IsInSkillTail()
    return self.StoryBoard.InComboTail
end

function SkillManagerBase:GetSkillType()
    return self.SkillType
end

function SkillManagerBase:EndComboTailState()
    self.Owner:SendMessage("EndState", check_table.State_SkillTail, false)
    self.Owner:SendMessage("EndState", check_table.State_SkillTail_NotMovable, false)
end

function SkillManagerBase:OnEndCurrentSkill()
    self:EndComboTailState()
    local CurSkill = self:GetCurrentSkill()
    if CurSkill then
        CurSkill:OnEndAbility()
    end
--    G.log:debug(self.__TAG__, "MarkSwitchOut: AbilityEnd, Player : %s", GetObjectName(self.actor))
end

function SkillManagerBase:GetCurrentSkillID()
    return self.SkillID
end

function SkillManagerBase:GetCurrentSkill()
    return self.Skill
end

function SkillManagerBase:GetCurrentSkillType()
    return self.SkillType
end

function SkillManagerBase:GetCurrentAbilityCDO()
    return self.AbilityCDO
end

function SkillManagerBase:IsCurrentSkillActivating()
    local CurSkill = self:GetCurrentSkill()
    return CurSkill:IsRunning()
end

function SkillManagerBase:GetActivateLongPressTime()
    return self.AbilityCDO.ActivateLongPressTime
end

function SkillManagerBase:CanSwitch()
    return true
end

function SkillManagerBase:StopAndReset()
    local Skill = self:GetCurrentSkill()
    if Skill then
        Skill:Cancel()
    end
    self:Reset()
end

function SkillManagerBase:Stop()
    local Skill = self:GetCurrentSkill()
    if Skill then
        Skill:Cancel()
    end
end

function SkillManagerBase:Reset()
    self:ResetStoryBoard()
end

function SkillManagerBase:ResetStoryBoard()
    -- 后摇开始帧
    self.StoryBoard.InComboTail = false
end

return SkillManagerBase
