--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_MiniGames_AudioGames_NoteLine : WBP_MiniGames_AudioGames_NoteLine_C
---@field bRedLine boolean

---@type WBP_MiniGames_AudioGames_NoteLine
local WBP_MiniGames_AudioGames_NoteLine = UnLua.Class()

function WBP_MiniGames_AudioGames_NoteLine:Construct()
    self.bRedLine = true
end

---@param Angle float
---@param Length float
function WBP_MiniGames_AudioGames_NoteLine:SetParam(Angle, Length)
    ---@type UCanvasPanelSlot
    local Slot = self.CanvasRedLine.Slot

    local Pos = UE.FVector2D(Length / 2, 0)
    Slot:SetPosition(Pos)
    self.CanvasRedLine:SetRenderTransformAngle(math.deg(Angle))

    local rotationY = Length * 0.5 * math.sin(Angle)
    local rotationX = Length * 0.5 - Length * 0.5 * math.cos(Angle)

    Pos.X = Pos.X - rotationX
    Pos.Y = Pos.Y + rotationY
    Slot:SetPosition(Pos)

    ---@type UCanvasPanelSlot
    local RedLineSlot = self.ImgRedLine.Slot
    local RedLineSize = RedLineSlot:GetSize()
    RedLineSize.X = Length
    RedLineSlot:SetSize(RedLineSize)

    ---@type UCanvasPanelSlot
    local RedLineShadowSlot = self.ImgRedLineShadow.Slot
    local RedLineShadowSize = RedLineShadowSlot:GetSize()
    RedLineShadowSize.X = Length
    RedLineShadowSlot:SetSize(RedLineShadowSize)
end

return WBP_MiniGames_AudioGames_NoteLine
