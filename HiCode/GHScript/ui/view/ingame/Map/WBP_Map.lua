--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

local SlotSave = require("CP0032305_GH.Script.ui.view.ingame.map.SlotSave")

local json = require("thirdparty.json")

---@class WBP_Map : WBP_Map_C
---@field ChildImages UUserWidget[][] @切图信息
---@field ViewBegin FVector2D @当前地图视距左上角
---@field ViewEnd FVector2D @当前地图视距右下角
---@field InitViewCentrePosition FVector2D @初始化时当前视距中心点坐标
---@field ViewCentrePosition FVector2D @当前视距中心点坐标，以CurrentScale==1为基准
---@field BaseScale float @基础缩放
---@field CurrentScale float @当前缩放率
---@field bMouseDown boolean @鼠标是否下按
---@field MoveRate float @移动速率
---@field ImageSize FVector2D @获取地图区域大小
---@field Labels WBP_MapLabel[] @图标
---@field PlayerLabel WBP_MapLabel @主角图标
---@type WBP_Map
local WBP_Map = Class(UIWindowBase)

--function WBP_Map:Initialize(Initializer)
--end

--function WBP_Map:PreConstruct(IsDesignTime)
--end
local Row = 10
local Column = 10

local MaxScale = 4

---场景中坐标范围
local LocationBegin = UE.FVector(-2000.0, -1000.0, 0)
local LocationEnd = UE.FVector(4000.0, 4000.0, 0)

---地图中显示的3D场景中的视距范围，(LocationEnd.X-LocationBegin.X)/(LocationEnd.Y-LocationBegin.Y) == ViewRange.X/ViewRange.Y 必须相等
local ViewRange = UE.FVector2D(1500, 1500)

function WBP_Map:OnConstruct()
    self.ChildImages = {}
    self.MoveRate = 1
    for i = 1, Row do
        table.insert(self.ChildImages, {})
        for j = 1, Column do
            table.insert(self.ChildImages[i], nil)
        end
    end
    print("WBP_Map:OnConstruct")
    for r = 1, Row do
        self.GridPanel_Image:SetRowFill(r - 1, 1)
    end
    for c = 1, Column do
        self.GridPanel_Image:SetColumnFill(c - 1, 1)
    end
    for r = 1, Row do
        for c = 1, Column do
            self:LoadChildImage(r, c)
        end
    end
    self.Button_Test.OnClicked:Add(self, self.OnButtonTest)

    local ViewScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
    local ViewSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
    local ScreenSize = ViewSize / ViewScale
    ---默认用屏幕大小
    self.ImageSize = ScreenSize

    ---初始视距范围是全地图
    self.ViewBegin = UE.FVector2D(0, 0)
    self.ViewEnd = UE.FVector2D(self.ImageSize.X, self.ImageSize.Y)
    self.InitViewCentrePosition = UE.FVector2D(self.ImageSize.X / 2, self.ImageSize.Y / 2)
    self.ViewCentrePosition = UE.FVector2D(self.ImageSize.X / 2, self.ImageSize.Y / 2)

    print("WBP_Map:OnConstruct", tostring(self.ViewCentrePosition))

    ---计算基础缩放率
    self.BaseScale = (LocationEnd.X - LocationBegin.X) / ViewRange.X
    self.CurrentScale = self.BaseScale
    local Scale = UE.FVector2D(1, 1) * self.CurrentScale
    self.ScaleBox_Content:SetRenderScale(Scale)

    self.Labels = {}

    local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
    local PlayerLocation = Controller:K2_GetPawn():K2_GetActorLocation()
    self:AddLabel(PlayerLocation, true)

    self:AddLabel(UE.FVector(0, 0, 0))

    self:MoveToLocation2D(self:Location2Map2D(PlayerLocation))
end

function WBP_Map:OnHide()

end
function WBP_Map:OnShow()
    if self.PlayerLabel then
        local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
        self.PlayerLabel.Location2D = self:Location2Map2D(Controller:K2_GetPawn():K2_GetActorLocation())
    end
    self:TrimLabel()
end

---@param R integer
---@param C integer
function WBP_Map:LoadChildImage(R, C)
    local Child = self.ChildImages[R][C]
    if Child then
        return
    end
    print("WBP_Map:LoadChildImage", R, C)
    local UIClass = LoadClass('/Game/CP0032305_GH/UI/UMG/Ingame/Map/WBP_MapChildImage.WBP_MapChildImage_C')
    ---@type WBP_MapChildImage_C
    local ChildImage = UE.UWidgetBlueprintLibrary.Create(self, UIClass)
    ChildImage.TextBlock_Grid:SetText(string.format("%d , %d", R, C))
    self.GridPanel_Image:AddChildToGrid(ChildImage, R - 1, C - 1)
    self.ChildImages[R][C] = ChildImage
end

---@param Location FVector
---@param IsPlayer boolean @optional
function WBP_Map:AddLabel(Location, IsPlayer)
    local UIClass = LoadClass('/Game/CP0032305_GH/UI/UMG/Ingame/Map/WBP_MapLabel.WBP_MapLabel_C')
    ---@type WBP_MapLabel
    local LabelUI = UE.UWidgetBlueprintLibrary.Create(self, UIClass)
    local Location2D = self:Location2Map2D(Location)
    print("WBP_Map:AddLabel", Location, Location2D)
    LabelUI:SetRenderTranslation(Location2D)
    LabelUI:SetRenderOpacity(10)
    LabelUI.Location2D = Location2D
    table.insert(self.Labels, LabelUI)
    self.CanvasPanel_Content:AddChildToCanvas(LabelUI)
    if IsPlayer then
        self.PlayerLabel = LabelUI
    end
    LabelUI.Button.OnClicked:Add(self, function()
        self:MoveToLocation2D(LabelUI.Location2D)
    end)
end

---@param R integer
---@param C integer
function WBP_Map:UnLoadChildImage(R, C)
    local Child = self.ChildImages[R][C]
    if not Child then
        return
    end
    print("WBP_Map:UnLoadChildImage", R, C)
    self.GridPanel_Image:RemoveChild(Child)
    self.ChildImages[R][C] = nil
end

local Random = 1
function WBP_Map:OnButtonTest()
    print("WBP_Map:OnButtonTest")
    Random = Random + 1
    if Random % 2 == 0 then
        self:UnLoadChildImage(3, 4)
        self:UnLoadChildImage(5, 1)
        self:UnLoadChildImage(1, 5)
        self:UnLoadChildImage(1, 8)
        self:UnLoadChildImage(7, 5)
    else
        self:LoadChildImage(3, 4)
        self:LoadChildImage(5, 1)
        self:LoadChildImage(1, 5)
        self:LoadChildImage(1, 8)
        self:LoadChildImage(7, 5)
    end

    --local SaveGame = SlotSave.GetSlot("Map")
    --print("WBP_Map:OnButtonTest", SaveGame:Get("test1"), SaveGame:Get("test2"), SaveGame:Get("test3"))
    --SaveGame:Put("test1", "1")
    --SaveGame:Put("test2", "a")
    --SaveGame:Put("test3", "c")
    --SaveGame:Save()
    --
    --local Test = {}
    --Test.A = "daf"
    --Test.B = 123
    --Test.C = { 33, 4 }
    --local Content = json.encode(Test)
    --
    --print("ReadFile" .. SlotSave.ReadFile("D:/test.txt"))
    --SlotSave.WriteFile("D:/test.txt", Content)
end

function WBP_Map:OnMouseWheel(MyGeometry, MouseEvent)
    local Delta = UE.UKismetInputLibrary.PointerEvent_GetWheelDelta(MouseEvent)
    self:BeginScale(Delta, 0.1)
    return UE.UWidgetBlueprintLibrary.Handled()
end

---The system calls this method to notify the widget that a mouse button was release within it. This event is bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Map:OnMouseButtonUp(MyGeometry, MouseEvent)
    print("WBP_Map:OnMouseButtonUp")
    self.bMouseDown = false
    return UE.UWidgetBlueprintLibrary.Handled()
end

---The system calls this method to notify the widget that a mouse button was pressed within it. This event is bubbled.
---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Map:OnMouseButtonDown(MyGeometry, MouseEvent)
    --local MousePosition = UE.UWidgetLayoutLibrary.GetMousePositionOnViewport(self)
    local Location2D = self:GetMap2DByMouse()
    local Location = self:Map2D2Location(Location2D)
    local Location2D_New = self:Location2Map2D(Location)
    print("WBP_Map:OnMouseButtonDown", Location2D, Location, Location2D_New)
    self.bMouseDown = true
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param MyGeometry FGeometry
---@param MouseEvent FPointerEvent
---@return FEventReply
function WBP_Map:OnMouseMove(MyGeometry, MouseEvent)
    if not self.bMouseDown then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    local Delta = UE.UKismetInputLibrary.PointerEvent_GetCursorDelta(MouseEvent)
    --print("WBP_Map:OnMouseMove", tostring(Delta))
    self:BeginMove(Delta, 0.8)
    return UE.UWidgetBlueprintLibrary.Handled()
end

---@param AxisValue float
---@param ScaleRate float @optional
function WBP_Map:BeginScale(AxisValue, ScaleRate)
    print("WBP_Map:BeginScale", AxisValue, ScaleRate)
    ScaleRate = ScaleRate or 0.1
    local OldScale = self.CurrentScale
    self.CurrentScale = self.CurrentScale + self.BaseScale * AxisValue * ScaleRate
    self.CurrentScale = UE.UKismetMathLibrary.FClamp(self.CurrentScale, 1, MaxScale * self.BaseScale)

    local Scale = UE.FVector2D(1, 1) * self.CurrentScale
    self.ScaleBox_Content:SetRenderScale(Scale)
    self:CheckTranslate()
    local OldViewCentrePosition = UE.FVector2D(self.ViewCentrePosition.X, self.ViewCentrePosition.Y)
    self:CalcViewRange()

    ---围绕ViewCentrePosition来缩放，所以需要计算偏移量
    local Delta = self.ViewCentrePosition - OldViewCentrePosition
    Delta = Delta * self.CurrentScale
    local Translation = self.ScaleBox_Content.RenderTransform.Translation
    Translation = Translation + Delta
    local Min, Max = self:GetTranslationRange()

    Translation.X = UE.UKismetMathLibrary.FClamp(Translation.X, Min.X, Max.X)
    Translation.Y = UE.UKismetMathLibrary.FClamp(Translation.Y, Min.Y, Max.Y)

    self.ScaleBox_Content:SetRenderTranslation(Translation)

    self:CalcViewRange()
    self:CalcGridLoad()
end

---计算视觉范围
---@private
function WBP_Map:CalcViewRange()
    ---计算中心点
    local Translation = self.ScaleBox_Content.RenderTransform.Translation
    --local X = self.InitViewCentrePosition.X
    --local Y = self.InitViewCentrePosition.Y
    --X = X - Translation.X / self.CurrentScale
    --Y = Y - Translation.Y / self.CurrentScale
    --
    --self.ViewCentrePosition = UE.FVector2D(X, Y)

    self.ViewCentrePosition = self.InitViewCentrePosition - Translation / self.CurrentScale

    self.ViewBegin = UE.FVector2D(math.abs(self.ViewCentrePosition.X - self.ImageSize.X / (2 * self.CurrentScale)), math.abs(self.ViewCentrePosition.Y - self.ImageSize.Y / (2 * self.CurrentScale)))
    self.ViewEnd = UE.FVector2D(math.abs(self.ViewCentrePosition.X + self.ImageSize.X / (2 * self.CurrentScale)), math.abs(self.ViewCentrePosition.Y + self.ImageSize.Y / (2 * self.CurrentScale)))

    print("WBP_Map:CalcViewRange", tostring(self.ViewCentrePosition), tostring(self.ViewBegin), tostring(self.ViewEnd), self.CurrentScale)
end

---@param AxisValue FVector2D
---@param MoveRate float @optional
---@return void
function WBP_Map:BeginMove(AxisValue, MoveRate)
    if math.abs(AxisValue.X) < 0.1 and math.abs(AxisValue.Y) < 0.1 then
        return
    end
    MoveRate = MoveRate or 1
    MoveRate = self.MoveRate * MoveRate
    local Translation = self.ScaleBox_Content.RenderTransform.Translation
    --print("WBP_Map:BeginMove", tostring(Translation))
    local OldTranslation = UE.FVector2D(Translation.X, Translation.Y)
    Translation.X = Translation.X + AxisValue.X * MoveRate
    Translation.Y = Translation.Y + AxisValue.Y * MoveRate

    --local ViewScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
    --local ViewSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
    --local ScreenSize = ViewSize / ViewScale
    ----print("----------", tostring(ViewSize), tostring(ScreenSize))
    --if not self.ImageSize then
    --    ---默认用屏幕大小
    --    self.ImageSize = ScreenSize
    --end
    --local ImageSize = self.ImageSize
    ----local ImageSize = self:GetDesiredSize()
    --local MaxX = (ImageSize.X * self.CurrentScale - ImageSize.X) / 2
    --local MaxY = (ImageSize.Y * self.CurrentScale - ImageSize.Y) / 2
    --local MinX = ImageSize.X - ScreenSize.X + MaxX
    --local MinY = ImageSize.Y - ScreenSize.Y + MaxY

    local Min, Max = self:GetTranslationRange()

    Translation.X = UE.UKismetMathLibrary.FClamp(Translation.X, Min.X, Max.X)
    Translation.Y = UE.UKismetMathLibrary.FClamp(Translation.Y, Min.Y, Max.Y)

    if Translation.X == OldTranslation.X and Translation.Y == OldTranslation.Y then
        return
    end

    self.ScaleBox_Content:SetRenderTranslation(Translation)

    print("WBP_Map:BeginMove2", tostring(self.ViewCentrePosition), "  ----  ", tostring(Translation), tostring(OldTranslation), (OldTranslation - Translation) / self.CurrentScale, self.CurrentScale)
    self:CalcViewRange()

    self:CalcGridLoad()
end

---@return FVector2D,FVector2D @Min,Max
function WBP_Map:GetTranslationRange()
    local ViewScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
    local ViewSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
    local ScreenSize = ViewSize / ViewScale
    local ImageSize = self.ImageSize
    local MaxX = (ImageSize.X * self.CurrentScale - ImageSize.X) / 2
    local MaxY = (ImageSize.Y * self.CurrentScale - ImageSize.Y) / 2
    local MinX = ImageSize.X - ScreenSize.X + MaxX
    local MinY = ImageSize.Y - ScreenSize.Y + MaxY

    return UE.FVector2D(-MinX, -MinY), UE.FVector2D(MaxX, MaxY)
end

---检测移动时是否超框了
---@private
---@return boolean
function WBP_Map:CheckTranslate()
    local Translation = self.ScaleBox_Content.RenderTransform.Translation
    local OldTranslation = UE.FVector2D(Translation.X, Translation.Y)
    --print("WBP_Map:CheckTranslate", tostring(OldTranslation), self.CurrentScale)

    --local ViewScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
    --local ViewSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
    --local ScreenSize = ViewSize / ViewScale
    --local ImageSize = self.ImageSize
    --local MaxX = (ImageSize.X * self.CurrentScale - ImageSize.X) / 2
    --local MaxY = (ImageSize.Y * self.CurrentScale - ImageSize.Y) / 2
    --local MinX = ImageSize.X - ScreenSize.X + MaxX
    --local MinY = ImageSize.Y - ScreenSize.Y + MaxY
    local Min, Max = self:GetTranslationRange()

    local NewTranslation = UE.FVector2D(0, 0)
    NewTranslation.X = UE.UKismetMathLibrary.FClamp(OldTranslation.X, Min.X, Max.X)
    NewTranslation.Y = UE.UKismetMathLibrary.FClamp(OldTranslation.Y, Min.Y, Max.Y)
    if NewTranslation.X ~= OldTranslation.X or NewTranslation.Y ~= OldTranslation.Y then
        self.ScaleBox_Content:SetRenderTranslation(NewTranslation)
        self:CalcViewRange()
        return true
    end
    return false
end

---3D坐标转2D坐标，基于CurrentScale为1时的转换
---@param Location FVector
---@return FVector2D
function WBP_Map:Location2Map2D(Location)
    if Location.X < LocationBegin.X or Location.X > LocationEnd.X or Location.Y < LocationBegin.Y or Location.Y > LocationEnd.Y then
        print("WBP_Map:Location2Map2D out", tostring(Location))
        return nil
    end
    return UE.FVector2D((Location.X - LocationBegin.X) / (LocationEnd.X - LocationBegin.X) * self.ImageSize.X, (Location.Y - LocationBegin.Y) / (LocationEnd.Y - LocationBegin.Y) * self.ImageSize.Y)
end
---2D坐标转3D坐标，基于CurrentScale为1时的转换
---@param Location2D FVector2D
---@return FVector
function WBP_Map:Map2D2Location(Location2D)
    if Location2D.X < 0 or Location2D.X > self.ImageSize.X or Location2D.Y < 0 or Location2D.Y > self.ImageSize.Y then
        print("WBP_Map:Map2D2Location out", tostring(Location2D))
        return nil
    end
    return UE.FVector((Location2D.X / self.ImageSize.X) * (LocationEnd.X - LocationBegin.X) + LocationBegin.X, (Location2D.Y / self.ImageSize.Y) * (LocationEnd.Y - LocationBegin.Y) + LocationBegin.Y, 0)
end

---移动到制定2D坐标
---@param Location2D FVector2D
function WBP_Map:MoveToLocation2D(Location2D)
    print("WBP_Map:MoveToLocation2D", Location2D)
    local Translation = (self.InitViewCentrePosition - Location2D) * self.CurrentScale
    local Min, Max = self:GetTranslationRange()
    Translation.X = UE.UKismetMathLibrary.FClamp(Translation.X, Min.X, Max.X)
    Translation.Y = UE.UKismetMathLibrary.FClamp(Translation.Y, Min.Y, Max.Y)
    self.ScaleBox_Content:SetRenderTranslation(Translation)
    self:CalcViewRange()
    self:CalcGridLoad()
end

---获取当前鼠标的Map2D坐标
---@return FVector2D
function WBP_Map:GetMap2DByMouse()
    local MousePosition = UE.UWidgetLayoutLibrary.GetMousePositionOnViewport(self)

    local X = (MousePosition.X / self.ImageSize.X) * (self.ViewEnd.X - self.ViewBegin.X) + self.ViewBegin.X
    local Y = (MousePosition.Y / self.ImageSize.Y) * (self.ViewEnd.Y - self.ViewBegin.Y) + self.ViewBegin.Y
    return UE.FVector2D(X, Y)
end

---计算需要Load的格子范围
function WBP_Map:CalcGridLoad()
    local High = self.ImageSize.Y / Row
    local Width = self.ImageSize.X / Column

    local BeginX = math.floor(self.ViewBegin.X / Width)
    local BeginY = math.floor(self.ViewBegin.Y / High)
    local EndX = math.floor(self.ViewEnd.X / Width) + 2
    local EndY = math.floor(self.ViewEnd.Y / High) + 2

    BeginX = UE.UKismetMathLibrary.Clamp(BeginX, 1, Column)
    BeginY = UE.UKismetMathLibrary.Clamp(BeginY, 1, Row)
    EndX = UE.UKismetMathLibrary.Clamp(EndX, 1, Column)
    EndY = UE.UKismetMathLibrary.Clamp(EndY, 1, Row)

    print("WBP_Map:CalcGridLoad", tostring(self.ViewBegin), tostring(self.ViewEnd), BeginX, BeginY, EndX, EndY)
    --for C = BeginX, EndX do
    --    for R = BeginY, EndY do
    --        self:LoadChildImage(R, C)
    --    end
    --end

    for r = 1, Row do
        for c = 1, Column do
            if (r >= BeginY and r <= EndY) and (c >= BeginX and c <= EndX) then
                self:LoadChildImage(r, c)
            else
                self:UnLoadChildImage(r, c)
            end
        end
    end
    self:TrimLabel()
end

---整理图标
function WBP_Map:TrimLabel()
    local BeginTranslation = self.ScaleBox_Content.RenderTransform.Translation
    local BeginLocationX = BeginTranslation.X - (self.CurrentScale - 1) * self.ImageSize.X / 2
    local BeginLocationY = BeginTranslation.Y - (self.CurrentScale - 1) * self.ImageSize.Y / 2

    local EndLocationX = self.ImageSize.X + BeginTranslation.X + (self.CurrentScale - 1) * self.ImageSize.X / 2
    local EndLocationY = self.ImageSize.Y + BeginTranslation.Y + (self.CurrentScale - 1) * self.ImageSize.Y / 2

    for _, Label in ipairs(self.Labels) do
        local X = self.CurrentScale * Label.Location2D.X + BeginLocationX
        local Y = self.CurrentScale * Label.Location2D.Y + BeginLocationY
        Label:SetRenderTranslation(UE.FVector2D(X, Y))
    end
end

--function WBP_Map:Tick(MyGeometry, InDeltaTime)
--end

return WBP_Map
