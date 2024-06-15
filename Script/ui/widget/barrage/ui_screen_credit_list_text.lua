--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')

local TIMER_INTERVAL = 0.2

---@type WBP_ScreenCreditList_Text_C
local M = Class(UIWidgetListItemBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:OnConstruct()
end

function M:OnDestroy()
    -- UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
end

function M:Tick(MyGeometry, InDeltaTime)
    if self.isEnd then
        local UI = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_ScreenCreditList.UIName)
        if UI then
            UI:FeedDog()
        end
    end
end

---@param ListItemObject UICommonItemObj_C
function M:OnListItemObjectSet(ListItemObject)
    if ListItemObject.ItemValue.isEnd then
        self.isEnd = ListItemObject.ItemValue.isEnd
    end
    -- 此处为解决UE的未在视窗中则不刷新从而导致闪烁的bug, 故添加换行符
    self.Txt_CastList01:SetText('\n' .. ListItemObject.ItemValue.Entry)
    self.Txt_CastList02:SetText('\n' .. ListItemObject.ItemValue.Name)

    ---@type FTimerHandle
    -- self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)
end

-- function M:TimerLoop()
--     if self.isEnd then
--         local PixelLocation = UE.FVector2D()
--         local ViewPortLocationTopLeft = UE.FVector2D()
--         local CheckAreaTopLeft = UE.USlateBlueprintLibrary.GetLocalTopLeft(self:GetCachedGeometry())
--         UE.USlateBlueprintLibrary.LocalToViewport(self, self:GetCachedGeometry(), CheckAreaTopLeft, PixelLocation, ViewPortLocationTopLeft)
--         UnLua.LogWarn("zys pos", PixelLocation.Y)
--         if PixelLocation.Y < 20 then
--             UnLua.LogWarn("call")
--             local UI = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_ScreenCreditList.UIName)
--             if UI then
--                 UnLua.LogWarn("call call")
--                 UI:FeedDog()
--             end
--         end
--     end
-- end

return M
