
local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

local MusicKeyItem = Class(UIWidgetBase)

function MusicKeyItem:OnConstruct()
    self.Switch_TrackNote:SetActiveWidgetIndex(1)
end

function MusicKeyItem:UpdatePosition()
    
end

function MusicKeyItem:Init(item,index)
    self.perfectTime = item.perfectTime
    self.keyPosition = item.keyPosition
    self.index = index
    self.judgeType = nil
    self.keyType = item.keyType
    self.bDown = false
    self.bcomplete = false
    self.endTime = self.perfectTime
    print("xmjInit",self.bcomplete)
end

function MusicKeyItem:IsIdle()
    return self.bcomplete
end

function MusicKeyItem:EndAction()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end


function MusicKeyItem:MissAction()
    self.Switch_TrackNote:SetActiveWidgetIndex(2)
end
return MusicKeyItem
