require "UnLua"

local G = require("G")

local ComboNode = Class()

function ComboNode:ctor(Mgr, InSkillID)
    self.Mgr = Mgr
    self.StoryBoard = Mgr.StoryBoard
    self.Transitions = {}    
    self.SkillID = InSkillID
end

function ComboNode:SortPriority()
    table.sort(self.Transitions, function(a, b)
        return a.Priority < b.Priority
    end)
end

function ComboNode:AddTransition(InTransition)
    table.insert(self.Transitions, InTransition)
    self:SortPriority()
end

function ComboNode:RemoveTransition(InTransition)
    for i = #self.Transitions, 1, -1 do
        if self.Transitions[i] == InTransition then
            table.remove(self.Transitions, i)
        end
    end
    self:SortPriority()
end

function ComboNode:Start()    
    local Skill = self.StoryBoard.Skills[self.SkillID]
    if Skill then
        Skill:Start()
    end
end

function ComboNode:GetSkill()
    local Skill = self.StoryBoard.Skills[self.SkillID]
    assert(Skill ~= nil)
    return Skill
end

function ComboNode:Cancel()
    local Skill = self.StoryBoard.Skills[self.SkillID]
    if Skill then
        Skill:Cancel()
    end
end

function ComboNode:TryGoNext()
    for _, Transition in pairs(self.Transitions) do
        local Suc = Transition:Jump(self.StoryBoard)
        if Suc then
            G.log:debug("ComboNode", "Cur skill: %d, go next: %d", self.SkillID, Transition.To.SkillID)
            self.Mgr:EndComboTailState()

            -- Reset storyboard when transition success.
            self.Mgr:ResetStoryBoard()

            Transition.From:Cancel()
            Transition.To:Start()

            -- Check whether combo node same combo manager, otherwise switch manager.
            self.Mgr.Owner.SkillDriver:TrySwitchManager(Transition.To:GetSkill(), true)

            --end
            return Transition.To
        end
    end

    return nil
end

function ComboNode:Clear()
    self.Transitions = {}
end

return ComboNode