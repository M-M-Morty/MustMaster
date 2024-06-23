---@type BP_SSDialogueSelectionWidget_C
local M = UnLua.Class()

function M:ConstructItem()
    self.ComBtn_Dialogue.OnClicked:Add(self, function()
        self:Click()
    end)
end

return M
