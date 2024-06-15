require "UnLua"
-- 废弃
-- Unify ComboManager and single skill.
local G = require("G")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')
local SkillManagerBase = require("skill.SkillManagerBase")

local SkillManagerAssist = Class(SkillManagerBase)



function SkillManagerAssist:ctor(InOwner, SkillIDs, SkillType, CurrentIndex)
    self.SkillIDQueue = SkillIDs
    self.Skills = {}
    self.AbilityCDOs = {}
    self.CurSkillIndex = CurrentIndex
    Super(SkillManagerAssist).ctor(self, InOwner, nil, SkillType)
    self.__TAG__ = "SkillManagerAssist"
end


function SkillManagerAssist:_init()
    self.Skills = {}
    self.AbilityCDOs = {}
    --self.CurSkillIndex = 1
    for _, SkillID in pairs(self.SkillIDQueue) do
        if SkillID then 
            local SkillInst = self.SkillDriver:InitSkillObj(SkillID)
            if not SkillID then
                G.log:error("AssistSkill", "skill id (%s) not config", SkillID)
            else
                table.insert(self.Skills, SkillInst)
                table.insert(self.AbilityCDOs, SkillInst:GetAbilityCDO())
            end
        end
    end
    
    --- 通知UI刷新怪谈技能UI
    UIManager.UINotifier:UINotify(UIEventDef.RefreshWitchSkillUI, self:GetCurrentSkillID(), self:GetNextSkillID())
end

function SkillManagerAssist:ReplaceSkills(SkillIDs, CurrentIndex)
    self.SkillIDQueue = SkillIDs
    self.CurSkillIndex = CurrentIndex
    self:_init()
end


function SkillManagerAssist:Start(SkillActivateCallbackOwner, SkillActivateCallback)
    local CurSkill = self:GetCurrentSkill()
    G.log:info(self.__TAG__, "Start Cast Assist Skill %s", CurSkill == nil)
    if not CurSkill or not CurSkill:CanActivate() then return end
    if CurSkill then
        CurSkill:Start(SkillActivateCallbackOwner, SkillActivateCallback)
    end
    --- 通知UI怪谈技能释放
    UIManager.UINotifier:UINotify(UIEventDef.WitchSkillTrigger)
end


function SkillManagerAssist:GetCurrentSkillID()
    -- G.log:error(self.__TAG__ , "get skillID (%s) %s", self.CurSkillIndex, self.SkillIDQueue[self.CurSkillIndex])
    if #self.SkillIDQueue == 0 then
        return nil
    end
    return self.SkillIDQueue[self.CurSkillIndex]
end

function SkillManagerAssist:GetNextSkillID()
    if #self.SkillIDQueue == 0 then
        return nil
    end
    return self.SkillIDQueue[(self.CurSkillIndex % (#self.SkillIDQueue)) + 1]
end

function SkillManagerAssist:GetCurrentSkill()
    -- G.log:error(self.__TAG__ , "get skill (%s) %s", self.CurSkillIndex, self.SkillIDQueue[self.CurSkillIndex] == nil)
    return self.Skills[self.CurSkillIndex]
end

function SkillManagerAssist:GetNextSkill()
    return self.Skills[(self.CurSkillIndex % (#self.SkillIDQueue)) + 1]
end

function SkillManagerAssist:GetCurrentSkillType()
    return self.SkillType
end

function SkillManagerAssist:GetCurrentAbilityCDO()
    return self.AbilityCDOs[self.CurSkillIndex]
end

function SkillManagerAssist:OnEndCurrentSkill()
    Super(SkillManagerAssist).OnEndCurrentSkill(self)
    -- G.log:warn(self.__TAG__ , "current skill index: %s cast finish", self.CurSkillIndex)
    self.CurSkillIndex = (self.CurSkillIndex % (#self.SkillIDQueue)) + 1
    if self.actor then
        local PlayerController = self.actor.PlayerState:GetPlayerController()
        if not PlayerController then
            G.log:error(self.__TAG__ , "update Assist SkillIndex failed, reason: get Controller failed")
            return
        end
        PlayerController.BP_AssistTeamComponent:Server_ChangeSkillIndex(self.CurSkillIndex)
    else
        G.log:error(self.__TAG__ , "update Assist SkillIndex failed, reason: Actor is null")
        return
    end
end

return SkillManagerAssist
