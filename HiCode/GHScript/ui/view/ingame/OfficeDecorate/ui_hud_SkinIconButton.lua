local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

local SkinIconButton = Class(UIWindowBase)

function SkinIconButton:OnListItemObjectSet(ItemObject)
   local ItemValue= ItemObject.ItemValue
    self.SkinName = ItemValue.SkinName
    self.UnlockItemNum = ItemValue.UnlockItemNum
    self.SkinMessages = ItemValue.SkinMessages
    self.WBP_Btn_RoleState.Button.OnClicked:Add(self,self.OnSelectedClicked)
    self.Target = ItemValue.Target
    self.Parent = ItemValue.Parent
    self.ActorID = ItemValue.ActorID
    self.DecorationVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DecorationMainVM.UniqueName)
end

function SkinIconButton:OnSelectedClicked()
    self.DecorationVM:SetSelectedSkin(self.SkinName)
    for i, Message in ipairs(self.SkinMessages) do
        self.DecorationVM:SetSkinMessage(self.ActorID,self.SkinName,Message.ComponentName,Message.Color,Message.AlterState)
    end
    self.DecorationVM.NotifyMessageChanged(self.Parent,self.Target,self.SkinMessages)
    self.DecorationVM:SetSelectedComponent(self.SkinMessages[1].ComponentName)
    self.DecorationVM:SetChangeColor()
end


return SkinIconButton
