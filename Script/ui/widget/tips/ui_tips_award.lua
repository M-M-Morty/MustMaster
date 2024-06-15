--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local utils = require("common.utils")

---@type WBP_Tips_Award_C
local WBP_Tips_Award = Class(UIWindowBase)

--function WBP_Tips_Award:Initialize(Initializer)
--end

--function WBP_Tips_Award:PreConstruct(IsDesignTime)
--end

function WBP_Tips_Award:OnConstruct()
    ---@type UTileViewProxy
    self.TileViewProxy = WidgetProxys:CreateWidgetProxy(self.TileView_Item)

    self.ItemQueue = {}
    self.CurrentSpecItem = nil
end

-- function WBP_Tips_Award:Tick(MyGeometry, InDeltaTime)
-- end

---`public`推一个新条目到此界面的显示队列
function WBP_Tips_Award:PushSpecItem(Items)
    local MessageItem = {}
    MessageItem.Items = Items
    MessageItem.Duration = 2
    MessageItem.PassedTime = 0
    table.insert(self.ItemQueue, MessageItem)

    self:DisplayNextMessage()
end

function WBP_Tips_Award:DisplayNextMessage()
    if not self.CurrentSpecItem then
        if #self.ItemQueue > 0 then
            self.CurrentSpecItem = self.ItemQueue[1]
            table.remove(self.ItemQueue, 1)
            self.TileViewProxy:SetListItems(self.CurrentSpecItem.Items)
            -- self.Text_Content:SetRenderOpacity(0)
            self:PlayAnimation(self.FadeOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
            utils.DoDelay(UIManager.GameWorld, self.CurrentSpecItem.Duration, function()
                self:PlayAnimation(self.FadeOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
                self.CurrentSpecItem = nil
            end)
        end
    end
end

---`brief`淡出动画的回调
function WBP_Tips_Award:FadeOutEnd()
    self:DisplayNextMessage()
    if not self.CurrentSpecItem then
        self:CloseMyself()
    end
end

return WBP_Tips_Award
