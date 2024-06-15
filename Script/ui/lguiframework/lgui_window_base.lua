local G = require("G")

local LGUIWindowBase = {}

function LGUIWindowBase:SetLGUIInfo(LGUIInfo, prefabActor)
    self.LGUIInfo = LGUIInfo
    self.PrefabActor = prefabActor
end

function LGUIWindowBase:CallOnCreate()
    G.log:debug('shiniingliu:', 'LGUIWindowBase:CallOnCreate %s', self.LGUIInfo.UIName)
    if self.OnCreate then
        self:OnCreate()
    end
end

function LGUIWindowBase:CallUpdateParams(...)
    if self.UpdateParams then
        self:UpdateParams(...)
    end
end

function LGUIWindowBase:BeginShow()
    self:CallOnShow()
end

function LGUIWindowBase:CallOnShow()
    if self.OnShow then
        self:OnShow()
    end
end

function LGUIWindowBase:BeginHide(bDestroy)
    if bDestroy then
        self:CallOnDestroy()
    else
        self:CallOnHide()
    end
end

function LGUIWindowBase:HideImmediately()
    self:CallOnHide()
end

function LGUIWindowBase:CallOnHide()
    if self.OnHide then
        self:OnHide()
    end
end

function LGUIWindowBase:CallOnDestroy()
    if self.OnDestroy then
        self:OnDestroy()
    end
end

return LGUIWindowBase
