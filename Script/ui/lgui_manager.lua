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
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')

local LGUIManager = UnLua.Class()

function LGUIManager:Init()
    self.tbCreatedLGUI = {}
    self.world = G.GameInstance:GetWorld()
    self:CreateEventSystem()
end

function LGUIManager:EnableDefaultIMC()
    -- todo
end

---释放鼠标则显示鼠标，同时响应鼠标输入，屏蔽imc_default
function LGUIManager:ReleaseMouse(releaseMouse)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    if releaseMouse then
        UIManager:SetOverridenInputMode(UIManager.OverridenInputMode.GameOnly, true)
        self:RemoveLGUIIMC(PlayerController)
    else
        self:CreateLGUIIMC(PlayerController)
        UIManager:SetOverridenInputMode('')
    end
end

local function GetRenderingSpace(LGUIInfo, lguiManagerInst)
    local renderingSpace
    if LGUIInfo.LguiRenderingType == Enum.Enum_LguiRenderingType.RenderingWithPlayerTrans then
        if not lguiManagerInst.WorldSpace then
            lguiManagerInst:LoadWorldSpace()
        end
        renderingSpace = lguiManagerInst.WorldSpace:K2_GetRootComponent()
    elseif LGUIInfo.LguiRenderingType == Enum.Enum_LguiRenderingType.RenderingWithWorldTrans then
        if not lguiManagerInst.WorldSpace then
            lguiManagerInst:LoadWorldSpace()
        end
        renderingSpace = lguiManagerInst.WorldSpace:K2_GetRootComponent()
    elseif LGUIInfo.LguiRenderingType == Enum.Enum_LguiRenderingType.RenderingWithScreenSpace then
        if not lguiManagerInst.ScreenSpace then
            lguiManagerInst:LoadScreenSpace()
        end
        renderingSpace = lguiManagerInst.ScreenSpace:K2_GetRootComponent()
    end

    return renderingSpace
end

local function CreateLGUIPrefab(lguiManagerInst, LGUIInfo)
    local LGUIInstance = lguiManagerInst:GetLGUIInstance(LGUIInfo.UIName) ---@type UWidget
    if not LGUIInstance then
        local classPath = LGUIInfo.LguiClassPath
        local prefab = UE.UObject.Load(classPath)
        local renderingSpace = GetRenderingSpace(LGUIInfo, lguiManagerInst)
        if not renderingSpace then
            G.log:error('shiniingliu:', 'LGUIManager:CreateLGUIPrefab no renderingSpace')
            return
        end
        ---加载prefab到从场景中
        local prefabActor = UE.ULGUIBPLibrary.LoadPrefab(lguiManagerInst.world, prefab, renderingSpace)
        lguiManagerInst:SetTransfrom(LGUIInfo, prefabActor)
        if LGUIInfo.ReleaseMouse then
            lguiManagerInst:ReleaseMouse(LGUIInfo.ReleaseMouse)
        end
        LGUIInstance = prefabActor:GetComponentByClass(LGUIInfo.RootActorComponent)

        if LGUIInstance then
            lguiManagerInst.tbCreatedLGUI[LGUIInfo.LGUIName] = LGUIInstance

            LGUIInstance:SetLGUIInfo(LGUIInfo, prefabActor)
            LGUIInstance:CallOnCreate()
        end
    end
    return LGUIInstance
end

function LGUIManager:GetLGUIInstance(LGUIName)
    local FoundedUI = self.tbCreatedLGUI[LGUIName]
    return FoundedUI
end

function LGUIManager:OpenLGUI(LGUIInfo, ...)
    local actorComponent = CreateLGUIPrefab(self, LGUIInfo)
    if actorComponent then
        actorComponent:CallUpdateParams(...)
        actorComponent:BeginShow()
        return actorComponent
    end
    return nil
end

---设置lguiPrefab的偏移量和相机偏移量
function LGUIManager:SetTransfrom(LGUIInfo, prefabActor)
    local Player = G.GetPlayerCharacter(self.world, 0)
    if LGUIInfo.LguiRenderingType == Enum.Enum_LguiRenderingType.RenderingWithPlayerTrans then   ---在当前player旁渲染
        local playerTrans = Player:GetTransform()
        local Location1, Rotation1, Scale1 = UE.UKismetMathLibrary.BreakTransform(playerTrans)
        local lguiTrans = UE.UKismetMathLibrary.MakeTransform(Location1, Rotation1, LGUIInfo.OffsetScale)

        ---LguiTransformOffset 为lgui和player的相对位置
        prefabActor:K2_SetActorTransform(lguiTrans, false, nil, true)

        --不使用AddActorWorldTransform，会将scale重置为1
        prefabActor:K2_AddActorLocalRotation(LGUIInfo.OffsetRotation, false, nil, true)
        prefabActor:K2_AddActorLocalOffset(LGUIInfo.OffsetLocation, false, nil, true)

        if LGUIInfo.UseLguiCamera then
            local cameraTrans = UE.UKismetMathLibrary.MakeTransform(Location1, Rotation1, LGUIInfo.CameraScale)

            self.LGUICamera:K2_SetWorldTransform(cameraTrans, false, nil, false)
            self.LGUICamera:K2_AddLocalRotation(LGUIInfo.CameraRotation, false, nil, true)
            self.LGUICamera:K2_AddLocalOffset(LGUIInfo.CameraLocation, false, nil, true)
            self:MoveCamera()
        end
    elseif LGUIInfo.LguiRenderingType == Enum.Enum_LguiRenderingType.RenderingWithWorldTrans then   ---世界坐标渲染
        local actorTrans = UE.UKismetMathLibrary.MakeTransform(LGUIInfo.OffsetLocation
            , LGUIInfo.OffsetRotation, LGUIInfo.OffsetScale)
        prefabActor:K2_SetActorTransform(actorTrans, false, nil, true)
    end
    ---屏幕空间渲染不进行单独prefab偏移设置，使用RootActor默认偏移来适配屏幕
end

function LGUIManager:LoadWorldSpace()
    self.WorldSpace = UE.ULGUIBPLibrary.LoadPrefab(self.world, self.WorldSpaceUIRoot, self.DefaultSceneRoot)
end

function LGUIManager:LoadScreenSpace()
    self.ScreenSpace = UE.ULGUIBPLibrary.LoadPrefab(self.world, self.ScreenSpaceUIRoot, self.DefaultSceneRoot)
end

function LGUIManager:CreateEventSystem()
    self.EventSystem = self.world:SpawnActor(self.EventSystem, self.DefaultSceneRoot:K2_GetComponentToWorld(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil)
end

function LGUIManager:CloseLGUI(LGUIInstance, bDestroy)
    if not LGUIInstance then
        return
    end

    local CreatedLGUIInstance = self.tbCreatedLGUI[LGUIInstance.LGUIInfo.LGUIName]
    if CreatedLGUIInstance then
        --self:ClosePanelWithActor(prefabactor)
        CreatedLGUIInstance:BeginHide(true)
        UE.ULGUIBPLibrary.DestroyActorWithHierarchy(CreatedLGUIInstance.PrefabActor, true)
        self.tbCreatedLGUI[CreatedLGUIInstance.LGUIInfo.LGUIName] = nil
        if CreatedLGUIInstance.UseLguiCamera then
            self:MoveCamera()
        end
        if CreatedLGUIInstance.LGUIInfo then
            if CreatedLGUIInstance.LGUIInfo.UseLguiCamera then
                self:RemoveCamera()
            end
            if CreatedLGUIInstance.LGUIInfo.ReleaseMouse then
                self:ReleaseMouse(false)
            end
        end
    end
end

---进行相机和主相机之间的切换
function LGUIManager:MoveCamera()
    local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
    local Manager = UE.UGameplayStatics.GetPlayerCameraManager(self, 0)
    Manager:ApplyCustomViewUpdater(self.LGUIUpdaterClass, self.BlendArgs)
    Manager.CustomViewUpdater.Rotation = self.LGUICamera:K2_GetComponentRotation()
    Manager.CustomViewUpdater.Location = self.LGUICamera:K2_GetComponentLocation()
    Manager.CustomViewUpdater:ProcessCameraView(0)
    
    Controller:EnableInput(Controller)
end

function LGUIManager:RemoveCamera()
    local Controller = UE.UGameplayStatics.GetPlayerController(self, 0)
    local Manager = UE.UGameplayStatics.GetPlayerCameraManager(self, 0)
        if Manager ~= nil then
            Manager:ApplyCustomViewUpdater(nil, self.BlendArgs)
        end
    Controller:EnableInput(Controller)
end

return LGUIManager
