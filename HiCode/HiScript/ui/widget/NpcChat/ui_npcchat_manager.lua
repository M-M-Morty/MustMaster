--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local Actor = require("common.actor")
local PlayerChatManager = require('CP0102309_MG.Script.ui.ingame.dialog.PlayerChatManager')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local G = require("G")

local M = UnLua.Class()

function M:OpenMessagePanel()
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end

    if self.messagesPanelActor then
        return
    end

    if self.UIHideLayerNode == nil then
        self.UIHideLayerNode = utils.HideUI()
    end

    UIManager:SetOverridenInputMode(UIManager.OverridenInputMode.GameOnly, true)

    local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    self:RemoveLGUIIMC(PlayerController)
    self.messagesPanelActor = self:LoadMessagesPanel()
    self.messagesPanel = self:GetMessagePanelComponent(self.messagesPanelActor)
    self.messagesPanel:InitPanel(self)

    self:MoveCamera()
end

function M:MoveCamera()
    local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
        local Manager = UE.UGameplayStatics.GetPlayerCameraManager(self, 0)
        Manager:ApplyCustomViewUpdater(self.LGUIUpdaterClass, self.BlendArgs)
        Manager.CustomViewUpdater.Rotation = self.LGUICamera:K2_GetComponentRotation()
        Manager.CustomViewUpdater.Location = self.LGUICamera:K2_GetComponentLocation()
        Manager.CustomViewUpdater:ProcessCameraView(0)
    
    Controller:EnableInput(Controller)
end
function M:ReMoveCamera()
    local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
    local Manager = UE.UGameplayStatics.GetPlayerCameraManager(self, 0)
        if Manager ~= nil then
            Manager:ApplyCustomViewUpdater(nil, self.BlendArgs)
        end
    
    Controller:EnableInput(Controller)
end
--打开聊天界面
function M:OpenChatingPanel(npcId)
    --utils:HideUI()
    if self.messagesPanelActor then
        self:ClosePanelWithActor(self.messagesPanelActor)
        self.messagesPanelActor = nil
    end
    self.chatingPanelActor = self:LoadChatingPanel()
    self.chatingPanel = self:GetChatingPanelComponent(self.chatingPanelActor)
    self.chatingPanel:InitPanel(npcId, self)
end

--打开视频聊天界面
function M:OpenVideoChatPanel()
    if UE.UKismetSystemLibrary.IsServer(self) then
        return
    end

    if self.videochatingPanelActor then
        return
    end
    self.UIHideLayerNode = utils.HideUI()
    UIManager:SetOverridenInputMode(UIManager.OverridenInputMode.GameOnly, true)

    local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    self:RemoveLGUIIMC(PlayerController)
    self.videochatingPanelActor =self:LoadVideoChatPanel()
    self.videochatingPanel = self:GetVideoChatingPanelComponent(self.videochatingPanelActor)
    self.videochatingPanel:InitPanel(self)
end

function M:CloseMessagePanel()

    if self.UIHideLayerNode then
        utils.ShowUI(self.UIHideLayerNode)
        self.UIHideLayerNode = nil
    end
    local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    self:CreateLGUIIMC(PlayerController)
    UIManager:SetOverridenInputMode('')

    self:ClosePanelWithActor(self.messagesPanelActor)
    self.messagesPanelActor = nil
    self:ReMoveCamera()

end

function M:CloseChatingPanel()
    self:ClosePanelWithActor(self.chatingPanelActor)
    self:OpenMessagePanel()
end

function M:CloseVideoChatingPanel()
    if self.UIHideLayerNode then
        utils.ShowUI(self.UIHideLayerNode)
        self.UIHideLayerNode = nil
    end
    local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    self:CreateLGUIIMC(PlayerController)
    UIManager:SetOverridenInputMode('')
    self:ClosePanelWithActor(self.videochatingPanelActor)
    self:ReMoveCamera()

end

return M
