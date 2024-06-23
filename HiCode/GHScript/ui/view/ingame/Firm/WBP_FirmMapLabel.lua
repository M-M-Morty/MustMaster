--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

---@class WBP_FirmMapLabel: WBP_FirmMapLabel_C
---@field Location2D FVector2D
---@field GridLocation FIntPoint
---@field AnchorName string
---@field PicKey string
---@field TempId integer
---@field bIsAdd boolean
---@field OldLocation FVector2D
---@field IsTrace boolean
---@field bIsVisible boolean
---@field ShowId integer
---@field IsGuide boolean
---@field FloatUI WBP_FirmMapLabel
---@field IsAnchor boolean
---@field Mission MissionObject
---@field OutScreen boolean
---@type WBP_FirmMapLabel
local WBP_FirmMapLabel = Class(UIWindowBase)

WBP_FirmMapLabel.IconDefaultSize={
    X=30,
    Y=30
}

function WBP_FirmMapLabel:InsidScope()
    
    if self.IconSlot == nil then
        self.IconSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.WBP_HUD_Task_Icon.TargetArea)
    end
    if self.IconDefaultScale == nil then
        self.IconDefaultScale=self.WBP_HUD_Task_Icon.RenderTransform.Scale
    end
    if self.IconScopeSize==nil and self.MapScale~=nil then
        self.IconScopeSize=self.TaskRadius * 2 * self.MapScale
    end
    local IconSize
    if self.IconScopeSize ~= nil then
        IconSize = self.IconScopeSize / self.IconDefaultScale.X
        else
        IconSize = self.IconDefaultSize.X
    end
    self.IconSlot:SetSize(UE.FVector2D( IconSize , IconSize ))
    self.WBP_HUD_Task_Icon.Task_Icon_Switcher:SetActiveWidgetIndex(5)
    self.ScopeState=true
    self.WBP_HUD_Task_Icon:StopAnimation(self.WBP_HUD_Task_Icon.DX_IconTrackMainLoop)
    self.WBP_HUD_Task_Icon.EFF:SetVisibility(UE.ESlateVisibility.Hidden)
    if not self.OriginScale then
        self.OriginScale = self.RenderTransform.Scale.X
    end
    self:SetRenderScale(UE.FVector2D( 1 , 1 ))
end
function WBP_FirmMapLabel:OutScope()
    if self.IconSlot == nil then
        self.IconSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.WBP_HUD_Task_Icon.TargetArea)
    end
    if self.IconSlot ~= nil then
        self.IconSlot:SetSize(UE.FVector2D( self.IconDefaultSize.X , self.IconDefaultSize.Y ))
        self.WBP_HUD_Task_Icon.Task_Icon_Switcher:SetActiveWidgetIndex(1)
        self.ScopeState=false
        self.WBP_HUD_Task_Icon.EFF:SetVisibility(UE.ESlateVisibility.Visible)
        self.WBP_HUD_Task_Icon:PlayAnimation(self.WBP_HUD_Task_Icon.DX_IconTrackMainLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
        if self.OriginScale ~= nil then
            self:SetRenderScale(UE.FVector2D( self.OriginScale , self.OriginScale ))
        end
    end
    
end
return WBP_FirmMapLabel