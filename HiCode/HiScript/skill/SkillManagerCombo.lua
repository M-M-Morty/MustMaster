
require "UnLua"

--[[
    Normal combo skill manager.
]]
local G = require("G")
local ComboNode = require("skill.ComboNode")
local ComboTransition = require("skill.ComboTransition").Transition
local SkillObj = require ("skill.SkillObj")

local NormalCondition = require("skill.ComboTransition").ExportFunc.NormalComboCondition

local MinComboSkillCount = require("common.event_const").MinComboSkillCount

local SkillManagerBase = require("skill.SkillManagerBase")
local SkillManagerCombo = Class(SkillManagerBase)

function SkillManagerCombo:ctor(InOwner, SkillID, SkillType)
    Super(SkillManagerCombo).ctor(self, InOwner, SkillID, SkillType)

    self.__TAG__ = "SkillManagerCombo"
    G.log:debug(self.__TAG__, "Init SkillManagerCombo type: %d", self.SkillType)
end

function SkillManagerCombo:_init()
    self.RootComboNode = nil
    self.CurNode = nil
    self.ComboSkillContainer = {}
    self.StoryBoard = {}
    self:ResetStoryBoard()
    self.StoryBoard.Skills = self.ComboSkillContainer
end

function SkillManagerCombo:InitFromData(ComboSkillIDs)
    if ComboSkillIDs and #ComboSkillIDs >= MinComboSkillCount then
        local ComboNodeMap = {}
        for ind, SkillID in ipairs(ComboSkillIDs) do
            if not self.ComboSkillContainer[SkillID] then
                -- Init SkillObj
                local Skill = self.Owner.SkillDriver:InitSkillObj(SkillID)
                self.ComboSkillContainer[SkillID] = Skill

                -- Init ComboNode
                local Node = ComboNode.new(self, SkillID)
                ComboNodeMap[SkillID] = Node
                if ind == 1 then
                    self.RootComboNode = Node
                    self.CurNode = self.RootComboNode
                end
            end
        end

        -- Init ComboTransition
        local ComboLen = #ComboSkillIDs
        for Ind = 1, ComboLen do
            local NextInd = Ind + 1
            if NextInd > ComboLen then
                NextInd = 1
            end
            local Transition = ComboTransition.new(ComboNodeMap[ComboSkillIDs[Ind]], ComboNodeMap[ComboSkillIDs[NextInd]], 1)
            Transition:AddCondition(NormalCondition)
        end
        return
    end
end

function SkillManagerCombo:KeyDown()
    if self.CurNode then
        G.log:info(self.__TAG__, "EventID.KEY_DOWN")
        if self.StoryBoard.InComboPeriod then
            self.StoryBoard.ComboDownInPeriod = true
        end

        self:Start()
    end
end

function SkillManagerCombo:Start()
    if self.bSwitchOut then
        self.StoryBoard.InComboCheck = false
        if  self.CurNode and self.StoryBoard.InComboTail and self.StoryBoard.ComboCheckEnd then
            self.CurNode:Cancel()
        end
        self.CurNode = self.RootComboNode
        self.bSwitchOut = false
    end
    
    if self.CurNode then
        G.log:info(self.__TAG__, "EventID.KEY_UP")
        
        if self.StoryBoard.InComboCheck then
            -- 如果当前在跳转窗口，直接跳转到下一个技能.
            G.log:debug(self.__TAG__, "In ComboCheck, check KeyDown in ComboPeriod and try go next")
            if self:TryGoNext() then
                return
            end
        end

        -- TODO Prevent same skill repeat trigger use block tag in GA right now.
        if self.StoryBoard.InComboTail and self.StoryBoard.ComboCheckEnd then
            self.CurNode:Cancel()
        end
        self.CurNode:Start()
    end
end

function SkillManagerCombo:KeyUp()
end

function SkillManagerCombo:ComboPeriodStart_Notify()
    G.log:info(self.__TAG__, "EventID.PERIOD_START")
    self.StoryBoard.InComboPeriod = true

    -- To ensure
    self.StoryBoard.ComboDownInPeriod = false
end

function SkillManagerCombo:ComboPeriodEnd_Notify()
    G.log:info(self.__TAG__, "EventID.PERIOD_END")
    self.StoryBoard.InComboPeriod = false
end

function SkillManagerCombo:ComboCheckStart_Notify()
    G.log:info(self.__TAG__, "EventID.CHECK_START")
    self.StoryBoard.InComboCheck = true

    -- TODO ComboPeriodStart notify probability not trigger.
    self.StoryBoard.InComboPeriod = true

    -- First in ComboCheck window, try go next if have.
    G.log:debug(self.__TAG__, "ComboCheckStart, try go next if ComboPeriod down")
    self:TryGoNext()
end

function SkillManagerCombo:ComboCheckEnd_Notify()
    G.log:info(self.__TAG__, "EventID.CHECK_END")
    self.StoryBoard.InComboCheck = false
    self.StoryBoard.ComboCheckEnd = true
    self.bSwitchOut = false
end

function SkillManagerCombo:InCombo()
    return self.StoryBoard.InComboCheck
end

function SkillManagerCombo:TryGoNext()
    if self.CurNode then
        local Next = self.CurNode:TryGoNext()
        if Next then
            self.CurNode = Next
            return true
        end
    end

    return false
end

function SkillManagerCombo:OnEndCurrentSkill()
    Super(SkillManagerCombo).OnEndCurrentSkill(self)

    -- Reset combo after combo check end
    if self.StoryBoard.ComboCheckEnd then
        self:Reset()
        self.actor:ResetPose(true)
    end
end

function SkillManagerCombo:GetCurrentSkillID()
    if self.CurNode then
        return self.CurNode.SkillID
    end

    return nil
end

function SkillManagerCombo:GetCurrentSkill()
    if self.CurNode then
        return self.CurNode:GetSkill()
    end

    return nil
end

-- Stop current skill and reset combo.
function SkillManagerCombo:StopAndReset()
    if self.CurNode then
        self.CurNode:Cancel()
    end
    self:Reset()
end

function SkillManagerCombo:Reset()
    G.log:debug(self.__TAG__, "SkillManagerCombo reset.")
    self.CurNode = self.RootComboNode
    self:ResetStoryBoard()
    self.StoryBoard.Skills = self.ComboSkillContainer
end

-- Reset all the flag in StoryBoard.
function SkillManagerCombo:ResetStoryBoard()
    Super(SkillManagerCombo).ResetStoryBoard(self)

    -- Whether in ComboPeriod window.
    self.StoryBoard.InComboPeriod = false
    self.StoryBoard.ComboDownInPeriod = false
    self.StoryBoard.ComboCheckEnd = false

    -- Whether in ComboCheck window.
    self.StoryBoard.InComboCheck = false
end

function SkillManagerCombo:CanSwitch()
    -- Only switch combo manager(land -> air) when not activate, or in combo check.
    return not self:IsCurrentSkillActivating() or self.StoryBoard.InComboCheck
end

function SkillManagerCombo:Clear()
    if self.CurNode then
        self.CurNode:Clear()
    end

    self:_init()
end

return SkillManagerCombo
