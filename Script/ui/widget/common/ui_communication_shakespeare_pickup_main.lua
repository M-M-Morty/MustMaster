--
-- 叙事编辑器对话分支使用
--
-- @COMPANY GHGame
-- @AUTHOR zhengyanshuai
-- @DATE ${date} ${time}
-- @Notice 
--

local G = require('G')

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')

---@class WBP_Interact_Pickup: WBP_Interact_Pickup_C
local M = Class(UIWindowBase)



--显示对话分支时隐藏所有hud
function M:StartShowSelectionMainWidget()
    G.log:error("StartShowSelectionMainWidget", "MainWidget:StartShowSelectionMainWidget")

    UIManager:HideAllHUD()
end

--恢复所有hud显示
function M:StopShowSelectionMainWidget()
    G.log:error("StartShowSelectionMainWidget", "MainWidget:StopShowSelectionMainWidget")

    UIManager:RecoverShowAllHUD()
end
return M
