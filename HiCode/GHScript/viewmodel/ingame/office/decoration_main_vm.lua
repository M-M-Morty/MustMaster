--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local SubsystemUtils = require("common.utils.subsystem_utils")
local GlobalActorConst = require("common.const.global_actor_const")
local OfficeEnums = require("office.OfficeEnums")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local StringUtil = require('CP0032305_GH.Script.common.utils.string_utl')
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local OfficeModelTable = require("common.data.office_model")
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')

--[[
local Op = {
    Skin = 
    Colors = {} k=PartIdx, v=TableColor
    }

local CommandData = {
    Function = ,
    Parameters = ,
    Update = ,
    BackUp = ,
    }
]]

---@class DecorationMainVM : ViewModelBase
local DecorationMainVM = Class(ViewModelBaseClass)


function DecorationMainVM:ctor()
    Super(DecorationMainVM).ctor(self)

    self.DecorationNotifyField = self:CreateVMField('') --用于BroadcastNotification
end


function DecorationMainVM:EnterDecoration()

    self.SelectedActorID = nil
    self.tbUndoCommands = {}
    self.tbRedoCommands = {}
    self.tbOriginDecorations = {}

    self:GetDecorationHandler():Server_EnterDecorationMode()
end

function DecorationMainVM:LeaveDecoration(bBuyAll)
    self:GetDecorationHandler():ClientRequestLevelDecorationMode(bBuyAll)
end

function DecorationMainVM:GetCurrentDecoration(ActorID)
    local DecorationInfo = self:GetDecorationHandler():GetActorDecorationInfo(ActorID, true)
    if not DecorationInfo then
        DecorationInfo = self:GetDecorationHandler():GetActorDefaultDecorationInfo(ActorID)
    end
    return DecorationInfo
end

function DecorationMainVM:GetColorIndexTab(aryComps)
    local length = aryComps:Length()
    local t = {}
    if length > 0 then
        for i = 1, length do
            local color = aryComps:Get(i)
            t[color.Index] = { R = color.Color.R, G = color.Color.G, B = color.Color.B, A = color.Color.A }
        end
    end
    return t
end

function DecorationMainVM:DecorationToString(info)
    local a = string.format('ActorID:%s, BasicKey:%s, Skin:%s', info.ActorID, info.BasicModelKey, info.SkinKey)
    local b = 'Colors:'
    local length = info.Component:Length()
    if length > 0 then
        for i = 1, length do
            local v = info.Component:Get(i)
            b = b .. string.format('[%d]=%s', v.Index, tostring(v.Color))
        end
    end
    return a .. b
end

function DecorationMainVM:UpdateActorDecoration(info)
    local current = self:GetCurrentDecoration(info.ActorID)
    if info.SkinKey ~= current.SkinKey then
        local available = true
        if not StringUtil:IsEmpty(info.SkinKey) then
            available = self:GetDecorationHandler():IsSkinAvailable(info.SkinKey)
        end
        if available then
            self:GetDecorationHandler():ClientChangeSkinForActor(info.ActorID, info.SkinKey)
        else
            self:GetDecorationHandler():ClientTrialSkinForActor(info.ActorID, info.SkinKey)
        end
    end
    current = self:GetCurrentDecoration(info.ActorID)
    local length = info.Component:Length()
    if length > 0 then
        local tbExistColor = self:GetColorIndexTab(current.Component)
        local skin_key = current.SkinKey
        if StringUtil:IsEmpty(current.SkinKey) then
            skin_key = self:GetDefaultSkin(current.BasicModelKey)
        end
        for i = 1, length do
            local color = info.Component:Get(i)
            if not FunctionUtil:EqualColor(color.Color, tbExistColor[color.Index]) then
                local available = self:GetDecorationHandler():IsColorAvailable(skin_key, color.Index, color.Color)
                if available then
                    self:GetDecorationHandler():ClientChangeColorForActor(info.ActorID, color.Index, color.Color)
                else
                    self:GetDecorationHandler():ClientTrialColorForActor(info.ActorID, color.Index, color.Color)
                end
            end
        end
    end
end

function DecorationMainVM:CreateDecorationData(origin, op)
    local s
    if origin then
        s = origin:Copy()
    else
        s = Struct.BPS_OfficeDecorationInfo()
    end
    op = op or {}
    if op.Skin then
        s.SkinKey = op.Skin
    end
    if op.Colors then
        for k, v in pairs(op.Colors) do
            local bFind = false
            local length = s.Component:Length()
            if length > 0 then
                for i = 1, length do
                    local comp = s.Component:GetRef(i)
                    if comp.Index == k then
                        comp.Color = UE.FColor(v.R, v.G, v.B, v.A)
                        bFind = true
                        break
                    end
                end
            end
            if not bFind then
                local comp = Struct.BPS_OfficeModelPartInfo()
                comp.Index = k
                comp.Color = UE.FColor(v.R, v.G, v.B, v.A)
                s.Component:Add(comp)
            end
        end
    end
    return s
end

function DecorationMainVM:ChangeSkin(ActorID, NewSkin)
    local current = self:GetCurrentDecoration(ActorID)
    self:BackupOrigin(current)
    local info = self:CreateDecorationData(current, { Skin = NewSkin })
    self:UpdateActorDecoration(info)
    self:CreateUndo({ Function = 'ChangeSkin', Parameters = {ActorID, NewSkin}, Update = { info }, BackUp = { current} })
end

function DecorationMainVM:ChangeColor(ActorID, Index, NewColor)
    local current = self:GetCurrentDecoration(ActorID)
    self:BackupOrigin(current)
    local info = self:CreateDecorationData(current, { Colors = { [Index] = NewColor } })
    self:UpdateActorDecoration(info)
    self:CreateUndo({ Function = 'ChangeColor', Parameters = {ActorID, Index, NewColor}, Update = { info }, BackUp = { current} } )
end

function DecorationMainVM:ResetAll()
    local tbActorID = TableUtil:GetKeyList(self.tbOriginDecorations)
    local tbCurrent = {}
    local tbUpdate = {}
    for _, ActorID in pairs(tbActorID) do
        local current = self:GetCurrentDecoration(ActorID)
        table.insert(tbCurrent, current)
        local info = self:CreateDecorationData(self.tbOriginDecorations[ActorID])
        table.insert(tbUpdate, info)
        self:UpdateActorDecoration(info)
    end
    self:CreateUndo({ Function = 'ResetAll', Parameters = {}, Update = tbUpdate, BackUp = tbCurrent })
end

function DecorationMainVM:Undo()
    if #self.tbUndoCommands < 1 then
        return
    end
    local command = table.remove(self.tbUndoCommands)
    local bak = command.BackUp
    for i, v in pairs(bak) do
        self:UpdateActorDecoration(v)
    end
    table.insert(self.tbRedoCommands, command)
end

function DecorationMainVM:Redo()
    if #self.tbRedoCommands < 1 then
        return
    end
    local command = table.remove(self.tbRedoCommands)
    local up = command.Update
    for i, v in pairs(up) do
        self:UpdateActorDecoration(v)
    end
    table.insert(self.tbUndoCommands, command)
end

function DecorationMainVM:CreateUndo(command)
    table.insert(self.tbUndoCommands, command)
    if #self.tbRedoCommands > 0 then
        self.tbRedoCommands = {}
    end
end

function DecorationMainVM:BackupOrigin(info)
    if self.tbOriginDecorations[info.ActorID] then
        return
    end
    self.tbOriginDecorations[info.ActorID] = info:Copy()
end

function DecorationMainVM:GetOfficeSubsystem()
    local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(UIManager.GameWorld)
    return OfficeSubsystem
end

function DecorationMainVM:GetOfficeManager()
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
    if not OfficeManager then
        G.log:warn('gh', 'DecorationMainVM:GetOfficeManager OfficeManager Is nil')
        local Actors = UE.TArray(UE.AActor)
        local Cls = UE.UClass.Load('/Game/Blueprints/Office/BPA_OfficeManager.BPA_OfficeManager_C')
        UE.UGameplayStatics.GetAllActorsOfClass(UIManager.GameWorld, Cls, Actors)
        OfficeManager = Actors:Get(1)
    end
    return OfficeManager
end

function DecorationMainVM:GetDecorationHandler()
    local OfficeManager = self:GetOfficeManager()
    if OfficeManager then
        return OfficeManager:GetDecorationHandlerComp()
    end
end

function DecorationMainVM:SetSelectedActor(ActorID)
    self.SelectedActorID = ActorID
end

function DecorationMainVM:GetSelectedActor()
    return self.SelectedActorID
end

function DecorationMainVM:GetDefaultSkin(BasicModel)
    if StringUtil:IsEmpty(BasicModel) then
        return nil
    end
    local tbData = OfficeModelTable.data
    local t = tbData[BasicModel]
    for k, v in pairs(t) do
        if v.IsBasicMesh then
            return k
        end
    end
end

function DecorationMainVM:GetBasicModel(Skin)
    if StringUtil:IsEmpty(Skin) then
        return nil
    end
    local tbData = OfficeModelTable.data
    for BasicModel, skins in pairs(tbData) do
        for skin, v in pairs(skins) do
            if v.Index == Skin then
                return BasicModel
            end
        end
    end
end

function DecorationMainVM:GetSkinList(BasicModel)
    if StringUtil:IsEmpty(BasicModel) then
        return nil
    end
    local tbData = OfficeModelTable.data
    local tbList = tbData[BasicModel]
    local t = {}
    for k, v in pairs(tbList) do
        local skin_state = self:GetDecorationHandler():GetSkinAssetState(k)
        if skin_state <= OfficeEnums.OfficeModelSkinState.LockedByPrecondition then
            table.insert(t, k)
        end
    end
    return t
end

function DecorationMainVM:GetSkinConfig(Skin, BasicModel)
    if StringUtil:IsEmpty(BasicModel) and StringUtil:IsEmpty(Skin) then
        return nil
    end
    if StringUtil:IsEmpty(BasicModel) then
        BasicModel = self:GetBasicModel(Skin)
    end
    if StringUtil:IsEmpty(Skin) then
        Skin = self:GetDefaultSkin(BasicModel)
    end

    local tbData = OfficeModelTable.data
    return tbData[BasicModel][Skin]
end

function DecorationMainVM:GetSkinData(Skin, BasicModel)
    if StringUtil:IsEmpty(BasicModel) and StringUtil:IsEmpty(Skin) then
        return nil
    end
    local tbConfig = self:GetSkinConfig(Skin, BasicModel)
    
    local skin_state = self:GetDecorationHandler():GetSkinAssetState(Skin)
    local skin_available = self:GetDecorationHandler():IsSkinAvailable(Skin)
    local unlocked = (skin_state ~= OfficeEnums.OfficeModelSkinState.LockedByPrecondition)
    local tbGameData = { Unlocked = unlocked, Owned = skin_available, ExistColors = {}}
    for partIdx = 1, #tbConfig.CompName do
        local colors = self:GetDecorationHandler():GetModelUnlockedColors(Skin, partIdx)
        local t = {}
        for _, v in pairs(colors) do
            table.insert(t, { R=v.R, G=v.G, B=v.B, A=v.A })
        end
        tbGameData.ExistColors[partIdx] = t
    end
    return tbConfig, tbGameData
end


--[[
    Ret = { Element ... }
    Element = { Skin = ? | Colors = ?, Count =, Cost = ? }
]]
function DecorationMainVM:GetShopCarList()
    local tRet = {}
    local lst = self:GetDecorationHandler():GetShopCarItemsView()
    for k, v in pairs(lst.SkinItems) do
        local skinConfig = self:GetSkinConfig(k)
        local cost = { ID = skinConfig.UnlockItemID, Count = tonumber(skinConfig.UnlockItemNum) * v.Num }
        local t = { Skin = k, Count = v.Num, Cost = cost }
        table.insert(tRet, t)
    end

    local tbSorted = {}
    for i, v in pairs(lst.ColorItems) do
        local t = tbSorted[v.ModelKey]
        if not t then
            t = { Skin = v.ModelKey, Colors = {[v.Index] = {v.Color.R, v.Color.G, v.Color.B, v.Color.A}}, Count = 1}
            tbSorted[v.ModelKey] = t
        else
            t.Count = t.Count + 1
            t.Colors[v.Index] = {v.Color.R, v.Color.G, v.Color.B, v.Color.A}
        end
    end
    for k, v in pairs(tbSorted) do
        local skinConfig = self:GetSkinConfig(v.Skin)
        v.Cost = { ID = skinConfig.ColorUnlockItemID, Count = tonumber(skinConfig.ColorUnlockItemNum) * v.Count }
        table.insert(tRet, v)
    end
    return tRet
end

function DecorationMainVM:GetFloorList()
    -- body
end

function DecorationMainVM:GetRoomList()
    -- body
end

function DecorationMainVM:TeleportToRoom(Room)
    -- body
end

function DecorationMainVM:SwitchFloor(Floor)
    -- body
end




function DecorationMainVM:SetSelectedSkin(SkinID)
    self.SelectedSkinID = SkinID
end

function DecorationMainVM:SetSelectedComponent(CompName)
    self.SelectedComponent = CompName
end


function DecorationMainVM:GetSelectedSkin()
    return self.SelectedSkinID
end

function DecorationMainVM:GetSelectedComponent()
    return self.SelectedComponent
end

local ActorSkinCoponentMesssage = {}
ActorSkinCoponentMesssage[1] = {}--修改前的数据
ActorSkinCoponentMesssage[2] = {}--修改后的数据
function DecorationMainVM:SetSkinMessage(ActorID,SkinID,ComponentName,Color,bAlterState,bIsDefault)
    self:RecordMessage(ActorSkinCoponentMesssage[2],ActorID,SkinID,ComponentName,Color,bAlterState)
    if bIsDefault == 'Default' then
        self:RecordMessage(ActorSkinCoponentMesssage[1],ActorID,SkinID,ComponentName,Color,bAlterState)
    end
end

function DecorationMainVM:RecordMessage(MesssageData,ActorID,SkinID,ComponentName,Color,bAlterState)
    local CompMessage = {}
    CompMessage[ComponentName] = {Color = Color ,AlterState = bAlterState or false}
    local SelectedSkin = {}
    SelectedSkin[SkinID] = CompMessage
    if MesssageData[ActorID] == nil  then
        MesssageData[ActorID] = SelectedSkin
    else
        local SelectedActorTar = MesssageData[ActorID]
        if SelectedActorTar[SkinID] == nil then
            SelectedActorTar[SkinID] = CompMessage
        else
            local selectCompTar = SelectedActorTar[SkinID]
            selectCompTar[ComponentName] = {Color = Color ,AlterState = bAlterState or false}
        end
    end
end

function DecorationMainVM:GetSkinMessage(ActorID,SkinID,bIsDefault)
    local Messsage = nil
    if bIsDefault == 'Default' then
        Messsage = ActorSkinCoponentMesssage[1]
    else
        Messsage = ActorSkinCoponentMesssage[2]
    end
    local SelectedActor = Messsage[ActorID]
    if SelectedActor == nil then
        return nil
    end
    local SelecteSkinMessage = SelectedActor[SkinID]
    if SelecteSkinMessage == nil then
        return nil
    end
    local ColorItemTable = {}
    for ComponentName, ColorMesssage in pairs(SelecteSkinMessage) do
        table.insert(ColorItemTable,{ComponentName = ComponentName,Color = ColorMesssage.Color,AlterState = ColorMesssage.AlterState,Target = nil,Parent = nil })
    end
    return ColorItemTable
end

function DecorationMainVM:AffirmAlterStae()
    
    local ActorMessage = ActorSkinCoponentMesssage[2][self:GetSelectedActor()]
    local DefaultActorMessage = ActorSkinCoponentMesssage[1][self:GetSelectedActor()]
    local SkinMessage = ActorMessage[self:GetSelectedSkin()]
    local DefaultSkinMessage  = DefaultActorMessage[self:GetSelectedSkin()]
    for CompName, Message in pairs(SkinMessage) do
        Message.AlterState=true
        DefaultSkinMessage[CompName].Color = Message.Color
    end
end

function DecorationMainVM:GetIsSkinAlterStae()
     local SkinMessage = self:GetSkinMessage(self:GetSelectedActor(),self:GetSelectedSkin())
     for i, Message in ipairs(SkinMessage) do
        if not Message.AlterState then
            return false
        end
     end
     return true
end

local MessageChanged = {}
function DecorationMainVM.RegMessageChanged(UWidgert,Callback,InTarget)
    MessageChanged[InTarget]={
        Self = UWidgert,
        Callback = Callback,
        Targer = InTarget
    }
end

---卸载
---@param UWidgert any
---@param Callback function
function DecorationMainVM.UnRegMessageChanged(InTarget)
    MessageChanged[InTarget] = nil
end


---@param Mission MissionObject
function DecorationMainVM.NotifyMessageChanged(UWidgert,InTarget, ...)
    for Target, Changed in pairs(MessageChanged) do
        if Target == InTarget then
            Changed.Callback(UWidgert, ...)
        end
    end
end

function DecorationMainVM:SetChangeColor(InbIsDefault)
    local bIsDefault = nil
    if InbIsDefault then
        bIsDefault = 'Default'
    end
    local SelecteSkinMessage = self:GetSkinMessage(self:GetSelectedActor(),self:GetSelectedSkin(),bIsDefault)
    for i = 1, #SelecteSkinMessage, 1 do
        local Color= {}
        Color[1] = SelecteSkinMessage[i].Color.R * 255
        Color[2] = SelecteSkinMessage[i].Color.G * 255
        Color[3] = SelecteSkinMessage[i].Color.B * 255
        Color[4] = SelecteSkinMessage[i].Color.A * 255
        self:ChangeColor(self:GetSelectedActor(),i,Color)
    end
end

return DecorationMainVM

