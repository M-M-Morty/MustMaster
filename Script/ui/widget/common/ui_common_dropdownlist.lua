
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local G = require('G')


local ui_common_dropdownlist = Class(UIWindowBase)

function ui_common_dropdownlist:OnConstruct()
    self.bShowList = false

    if self.bDropDown then
        self.Switcher_List:SetActiveWidgetIndex(1)
        self.Switcher_Arrow:SetActiveWidgetIndex(1)
        self.List_PropProxy = WidgetProxys:CreateWidgetProxy(self.ListDown)
        self.List_Prop = self.ListDown
    else
        self.Switcher_List:SetActiveWidgetIndex(0)
        self.Switcher_Arrow:SetActiveWidgetIndex(0)
        self.List_PropProxy = WidgetProxys:CreateWidgetProxy(self.ListUp)
        self.List_Prop = self.ListUp
    end
    self.Switcher_List:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WBP_CommonButton.OnClicked:Add(self, self.OnClickedDropDownBtn)
end

function ui_common_dropdownlist:OnShow()
    ---默认不打开
    self.Switcher_List:SetVisibility(UE.ESlateVisibility.Hidden)
end

function ui_common_dropdownlist:OnDestruct()
    self.WBP_CommonButton.OnClicked:Remove(self, self.OnClickedDropDownBtn)
end

---列表item参数，必须含有itemText参数, selectedCallBack为选中某个item后的回调
---若不执行回调，可以通过curItem来取数据
function ui_common_dropdownlist:InitDropDownList(listItemsData, dropDownTitle, selectedCallBack, defaultSelected)
    self.listItemsData = listItemsData
    self.curSelectedIndex = 0
    if dropDownTitle and not defaultSelected then
        self.Tex_Title:SetText(dropDownTitle)
    end
    if selectedCallBack then
        self.SelectedCallBack = selectedCallBack
    end
    self.defaultSelected = defaultSelected
    self:LoadListItems()
end

function ui_common_dropdownlist:LoadListItems()
    self.List_Prop:ClearListItems()
    local items = self.listItemsData
    for idx, itemData in pairs(items) do
        if self.defaultSelected and self.defaultSelected == idx then
            ---默认选中,先赋值，设置显示状态，并执行回调
            ---curSelectedItem会在打开items时重新赋值
            itemData.bSelected = true
            self:DoSelectedCallback(itemData)
            self.curSelectedIndex = idx
            self.Tex_Title:SetText(itemData.itemText)
        end
        itemData.itemIndex = idx
        itemData.ownerWidget = self
        self.List_PropProxy:AddItem(itemData)
    end
end

function ui_common_dropdownlist:OnClickedDropDownBtn()
    self:ShowDropList(not self.bShowList)
    if self.bShowList then
        --todo 全局输入屏蔽
    else

    end
end

---在子item中执行点击select
function ui_common_dropdownlist:OnClickedSelectItem(selectItem)
    self:SelectedItem(selectItem)
    self:DoSelectedCallback(selectItem.itemData)
    self:ShowDropList(false)
end

function ui_common_dropdownlist:SelectedItem(selectItem)
    if self.curSelectedItem then
        self.curSelectedItem:SetSelectedState(false)
    end
    self.curSelectedIndex = selectItem.itemData.itemIndex
    self.curSelectedItem = selectItem
    self.Tex_Title:SetText(selectItem.itemData.itemText)
end

function ui_common_dropdownlist:DoSelectedCallback(itemData)
    ---执行回调
    if self.SelectedCallBack then
        self:SelectedCallBack(itemData)
    end
end

function ui_common_dropdownlist:ShowDropList(bShow)
    self.bShowList = bShow
    if bShow then
        self.Switcher_List:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if self.bDropDown then
            self.Switcher_Arrow:SetActiveWidgetIndex(0)
        else
            self.Switcher_Arrow:SetActiveWidgetIndex(1)
        end
        --todo 下拉上拉动画
    else
        self.Switcher_List:SetVisibility(UE.ESlateVisibility.Hidden)
        if self.bDropDown then
            self.Switcher_Arrow:SetActiveWidgetIndex(1)
        else
            self.Switcher_Arrow:SetActiveWidgetIndex(0)
        end
    end
end

return ui_common_dropdownlist
