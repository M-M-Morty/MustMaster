local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local  ButtonTable =require('CP0032305_GH.Script.ui.view.ingame.OfficeDecorate.ButtonTable')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local OfficeMainUI = Class(UIWindowBase)


local QuitText = "ITEM_MINIGAME_SCQUIT_TEXT"
local TitleText = "ITEM_USE_TITILE"

function OfficeMainUI:OnConstruct()
    self.DecorationMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DecorationMainVM.UniqueName)
    if not self.DecorationMainVM:GetInitialState() then
        self.DecorationMainVM:EnterDecoration(self)
        self.DecorationMainVM:SetCameraMode('Immersion')
    end
    self.CallbackTable = { self.LoadSetUPUI, nil, nil, self.ResetAll, self.LoadShoppingCartUI }
    self.WBP_Btn_Put.Button.OnClicked:Add(self,self.OnPutClicked)
    self.WBP_Btn_Adjust.Button.OnClicked:Add(self,self.OnAdjustClicked)
    self.WBP_Btn_Withdraw.Button.OnClicked:Add(self,self.OnUndoClicked)
    self.WBP_Btn_Forward.Button.OnClicked:Add(self,self.OnRedoClicked)
    self.WBP_Common_TopContent.CommonButton_Close.Button.OnClicked:Add(self,self.CloseOffice)
    self.VMNotifyField = self:CreateUserWidgetField(self.VMNotifies)
    ViewModelBinder:BindViewModel(self.VMNotifyField, self.DecorationMainVM.DecorationNotifyField, ViewModelBinder.BindWayToWidget)
    local UEPlayerController = UE.UGameplayStatics.GetPlayerController(UIManager.GameWorld, 0)
    local EnhancedInputLocalPlayerSubsystem = UE.USubsystemBlueprintLibrary.GetLocalPlayerSubsystem(UEPlayerController, UE.UEnhancedInputLocalPlayerSubsystem)
    EnhancedInputLocalPlayerSubsystem:RemoveMappingContext(self.IMCDefault, UE.FModifyContextOptions())
  

end

function OfficeMainUI:OnDestruct()
    self.WBP_Btn_Put.Button.OnClicked:Remove(self,self.OnPutClicked)
    self.WBP_Btn_Adjust.Button.OnClicked:Remove(self,self.OnAdjustClicked)
    self.WBP_Btn_Withdraw.Button.OnClicked:Remove(self,self.OnUndoClicked)
    self.WBP_Btn_Forward.Button.OnClicked:Remove(self,self.OnRedoClicked)
    self.WBP_Common_TopContent.CommonButton_Close.Button.OnClicked:Remove(self,self.CloseOffice)
    self.DecorationMainVM: SetInitialState(false)
    local UEPlayerController = UE.UGameplayStatics.GetPlayerController(UIManager.GameWorld, 0)
    local EnhancedInputLocalPlayerSubsystem = UE.USubsystemBlueprintLibrary.GetLocalPlayerSubsystem(UEPlayerController, UE.UEnhancedInputLocalPlayerSubsystem)
    EnhancedInputLocalPlayerSubsystem:AddMappingContext(self.IMCDefault, 100, UE.FModifyContextOptions())
    self.DecorationMainVM:LeaveDecoration()
end

function OfficeMainUI:Init()
    self:CreateFunctionIconButton()
    local ShopCarCount =self.DecorationMainVM:GetShopCarNum()
    if not self.DecorationMainVM:GetInitialState()  and ShopCarCount > 0 then
        self:LoadShoppingCartUI({ Initiator = 'ShopItem' })
    end
    self.DecorationMainVM: SetInitialState(true)
end

function OfficeMainUI:OnCreate()
    ---@type CurrencyData[]
    local CurrencyDatas = {
        {ExcelID = 990010, bShowAddButton = false},
    }
    self.WBP_Common_Currency:SetCurrencyDatas(CurrencyDatas)
end

function OfficeMainUI:OnShow()
    self.DecorationMainVM:SetCameraFocusTo()
    self:UpdateInteractBtns()
    self:UpdateUnRedos()
end

function OfficeMainUI:OnHide()
end

function OfficeMainUI:UpdateImmersionAim()
    local AbsolutePos = UE.USlateBlueprintLibrary.LocalToAbsolute(self.WBP_Common_CrossHair:GetCachedGeometry(), UE.FVector2D(0, 0))
    if self.DecorationMainVM:UpdateImmersionAimObj(AbsolutePos) then
        self:UpdateInteractBtns()
    end
end

function OfficeMainUI:VMNotifies(Message, ...)
    if Message == 'UnRedo' then
        self:UpdateUnRedos()
    end
end

function OfficeMainUI:UpdateInteractBtns()
    self.WBP_Btn_Put:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Btn_Recovery:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.DecorationMainVM:GetImmersionAimActorID() then
        self.WBP_Btn_Adjust:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.WBP_Btn_Adjust:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function OfficeMainUI:UpdateUnRedos()
    if #self.DecorationMainVM.tbUndoCommands > 0 then
        self.WBP_Btn_Withdraw:SetIsEnabled(true)
    else
        self.WBP_Btn_Withdraw:SetIsEnabled(false)
    end
    if #self.DecorationMainVM.tbRedoCommands > 0 then
        self.WBP_Btn_Forward:SetIsEnabled(true)
    else
        self.WBP_Btn_Forward:SetIsEnabled(false)
    end
end

function OfficeMainUI:CreateFunctionIconButton()
    
    local ListItem = {}
    
    for Index = 1, self.ButtonIcon:Length(), 1 do
        if Index == 5 then
            table.insert(ListItem,{CallbackIndex = Index ,Icon =self.ButtonIcon:Get(Index),Parent =self,RedDot = 2,Bubble = 1 ,RedDotNumber = self.DecorationMainVM:GetShopCarNum(),Initiator = 'ShopItem'})
        else
            table.insert(ListItem,{CallbackIndex = Index ,Icon =self.ButtonIcon:Get(Index),Parent =self})
        end
    end
    local ColorSquarePorxys =  WidgetProxys:CreateWidgetProxy(self.WBP_FirmRenovation_FunctionOptions.List_FunctionOptions)
    ColorSquarePorxys:SetListItems(ListItem)
end


function OfficeMainUI:OnPutClicked()

end

function OfficeMainUI:OnAdjustClicked()
    local selected = self.DecorationMainVM:GetImmersionAimActorID()
    if selected then
        self.DecorationMainVM:SetSelectedActor(selected)
        local UIInfo = UIDef.UIInfo.UI_AdjustingTheInterface
        ButtonTable:ShowUI(UIInfo,self,false)
        return true
    end
end

function OfficeMainUI:ResetAll()
    self.DecorationMainVM:ResetAll()
end

function OfficeMainUI:OnUndoClicked()
    self.DecorationMainVM:Undo()
end

function OfficeMainUI:OnRedoClicked()
    self.DecorationMainVM:Redo()
end

function OfficeMainUI:OnMouseMoveCustom(mouseDelta)
    local camera_state = self.DecorationMainVM:GetCameraState()
    if camera_state == 'Immersion' then
        self.DecorationMainVM:UpdateImmersionRotation(mouseDelta)
        self:UpdateImmersionAim()
    elseif camera_state == 'Focus' then
        self.DecorationMainVM:UpdateFocusRotation(mouseDelta)
    end
end

function OfficeMainUI:OnMouseWheelCustom(wheelDelta)
end

function OfficeMainUI:OnMouseLeftButton()
    if self.DecorationMainVM:GetCameraState() == 'Immersion' then
        if self:OnAdjustClicked() then
            return UE.UWidgetBlueprintLibrary.Handled()
        end
    end
end

function OfficeMainUI:OnMouseMiddleButton()
end

function OfficeMainUI:OnMouseRightButton()
end

-- 处理ESC
function OfficeMainUI:OnReturn()

end

function OfficeMainUI:OnKeyTrigger(key)
    local camera_state = self.DecorationMainVM:GetCameraState()
    if camera_state == 'Immersion' then
        if key == 'w' then
            self.DecorationMainVM:UpdateImmersionMovement(UE.FVector2D(1, 0))
        elseif key == 's' then
            self.DecorationMainVM:UpdateImmersionMovement(UE.FVector2D(-1, 0))
        elseif key == 'a' then
            self.DecorationMainVM:UpdateImmersionMovement(UE.FVector2D(0, -1))
        elseif key == 'd' then
            self.DecorationMainVM:UpdateImmersionMovement(UE.FVector2D(0, 1))
        end
        self:UpdateImmersionAim()
    elseif camera_state == 'Focus' then
        if key == 'w' then
            self.DecorationMainVM:UpdateFocusDistance(-1)
        elseif key == 's' then
            self.DecorationMainVM:UpdateFocusDistance(1)
        end
    end
end

function OfficeMainUI:OnShortKeyPress(action)
    if action == '1' then
    elseif action == '2' then
    elseif action == '3' then
    elseif action == '4' then
        self:ResetAll()
    elseif action == '5' then
        self:LoadShoppingCartUI()
    elseif action == 'tab' then
    end
end

function OfficeMainUI:LoadShoppingCartUI(Data)
    if Data == nil then
        Data = {Initiator = 'OfficeMainUI', Owner = self}
    end
    local UIInfo = UIDef.UIInfo.UI_ShoppingCart
    ButtonTable:ShowUI(UIInfo,self,false,Data)
end

function OfficeMainUI:LoadSetUPUI()
    local UIInfo = UIDef.UIInfo.UI_SetUP
    ButtonTable:ShowUI(UIInfo,self,false)
end



function OfficeMainUI:IconButtonOnClicked(Item)
    if Item.CallbackIndex == nil then
        return
    end
    local Callback = self.CallbackTable[Item.CallbackIndex]
    Callback(self,Item)
end




function OfficeMainUI:CloseOffice()
    if self.DecorationMainVM:GetShopCarNum() > 0 then
        self.PopUpInstance = UIManager:OpenUI(UIDef.UIInfo.UI_Common_SecondTextConfirm)
        self.PopUpInstance.WBP_Common_Popup_Small:BindCommitCallBack(self, self.LoadShoppingCartUI)
        self.PopUpInstance.WBP_Common_Popup_Small:BindCancelCallBack(self,self.OpenMainInterfaceHUD)
        self.PopUpInstance:SetTitleAndContent(TitleText,QuitText)
        return
    end
    self:OpenMainInterfaceHUD()
end

function OfficeMainUI:OpenMainInterfaceHUD()
    self.DecorationMainVM:SetInitialState(false)
    local UIInfo = UIDef.UIInfo.UI_MainInterfaceHUD
    ButtonTable:ShowUI(UIInfo,self)
end

return OfficeMainUI