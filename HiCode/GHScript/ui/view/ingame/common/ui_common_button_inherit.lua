--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ComBtn = require('CP0032305_GH.Script.ui.view.ingame.common.ui_common_button')

---@type WBP_ComBtn_Firset_Emphasize_C
local M = Class(ComBtn)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:Construct()
    -- self.Overridden.Construct(self)
    Super(M).Construct(self)
    -- Img_Hover
    self.OnHovered:Add(self, self.Inherit_OnHovered)
    self.OnUnhovered:Add(self, self.Inherit_OnUnhovered)
    self.Img_Hover:SetVisibility(UE.ESlateVisibility.Hidden)
end

--function M:Tick(MyGeometry, InDeltaTime)

--end

function M:Inherit_OnHovered()
    self.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function M:Inherit_OnUnhovered()
    self.Img_Hover:SetVisibility(UE.ESlateVisibility.Hidden)
end

return M
