--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@type BP_UIManagerLauncher_C
local UIManagerLauncher = Class()
UIManagerLauncher.bInitUIDone = false
local G = require("G")

-- function UIManagerLauncher:Initialize(Initializer)
-- end

function UIManagerLauncher:ReceiveBeginPlay()
    G.log:debug("xaelpeng", "UIManagerLauncher:ReceiveBeginPlay")
    self.Overridden.ReceiveBeginPlay(self)
    if not UE.UKismetSystemLibrary.IsDedicatedServer(self) then
        self.DoInitUI(self)
    end
end

-- function UIManagerLauncher:ReceiveEndPlay()
-- end

-- function UIManagerLauncher:ReceiveTick(DeltaSeconds)
-- end

function UIManagerLauncher.DoInitUI(WorldContextObj)
    if UIManagerLauncher.bInitUIDone then
        return
    end
    UIDef:InitUIDef()
    UIDef:InitLGUIDef()
    UIManagerLauncher.InitGlobal()  -- global的数据初始化暂时放在这里
    UIManagerLauncher.InitUIManager(WorldContextObj)
    UIManagerLauncher.bInitUIDone = true
end

function UIManagerLauncher.InitGlobal()
    ViewModelCollection:InitGlobalVM()
end

function UIManagerLauncher.InitUIManager(WorldContextObj)
    UIManager:InitManager(WorldContextObj)
    UIManager:OpenIngameLayerManager()
end

function UIManagerLauncher.IsInitialized()
    return UIManagerLauncher.bInitUIDone
end

function UIManagerLauncher.ResetUIManager(WorldContextObj)
    UIManager:UninitManager()
    UIManager:InitManager(WorldContextObj)
    UIManager:OpenIngameLayerManager()
end



return UIManagerLauncher
