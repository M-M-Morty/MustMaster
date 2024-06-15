--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

local Default_Dialogue_Icon = '/Game/CP0032305_GH/UI/Texture/Communication/Atlas/Frames/T_Icon_Interact_A_02_png.T_Icon_Interact_A_02_png'

---@type WBP_CommunicationMainUI_ChatSelection_Item_C
local UICommunicationChatItem = Class(UIWidgetListItemBase)

--function UICommunicationChatItem:Initialize(Initializer)
--end

--function UICommunicationChatItem:PreConstruct(IsDesignTime)
--end

function UICommunicationChatItem:OnConstruct()
end

function UICommunicationChatItem:BuildWidgetProxy()
end

function UICommunicationChatItem:OnListItemObjectSet(ListItemObject)
end

function UICommunicationChatItem:OnItemIn()
    if self.ItemData and self.ItemData.MainUI then
        self.ItemData.MainUI:OnItemIn(self.ItemData.ItemIndex)
    end
end

function UICommunicationChatItem:OnItemOut()
end

function UICommunicationChatItem:SetSelectionState(NewSelectIndex)
end
    
-- function UICommunicationChatItem:Tick(MyGeometry, InDeltaTime)
-- end

return UICommunicationChatItem