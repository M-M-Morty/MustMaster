
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')

local IconButton = UnLua.Class()
---@param UIInfo UIInfoClass
---@param CloseUI UIWindowBase
function IconButton:ShowUI(UIInfo,CloseUI,IsRemove,...)

   if UIInfo ~= nil then
      local OfficeUI=UIManager:OpenUI(UIInfo)
      if OfficeUI.Init ~= nil then
         OfficeUI:Init(...)
      end
   end
   if CloseUI ~= nil then
      UIManager:CloseUIImmediately(CloseUI,IsRemove or true)
   end
end

return IconButton