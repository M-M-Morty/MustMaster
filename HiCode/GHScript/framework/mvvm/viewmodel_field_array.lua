--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')

local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local ViewmodelField = require('CP0032305_GH.Script.framework.mvvm.viewmodel_field')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')

---@class ViewmodelFieldArray : ViewmodelField
local ViewmodelFieldArray = Class(ViewmodelField)

function ViewmodelFieldArray:ctor(InViewModel, InFieldValue)
    Super(ViewmodelFieldArray).ctor(self, InViewModel)
    self:SetItems(InFieldValue)
end

function ViewmodelFieldArray:IsViewModelFieldArray()
    return true
end

---@return ViewModelInterface
function ViewmodelFieldArray:GetItem(InIndex)
    return self.FieldValue[InIndex]
end

---@return ViewModelInterface
function ViewmodelFieldArray:FindItemIf(fnCall)
    if not fnCall then
        return
    end
    for Index, Item in ipairs(self.FieldValue) do
        if fnCall(Item:GetFieldValue(), Item) then
            return Item, Index
        end
    end
end

function ViewmodelFieldArray:FindItemValueIf(fnCall)
    local ItemField, ItemIndex = self:FindItemIf(fnCall)
    if ItemField then
        return ItemField:GetFieldValue(), ItemField, ItemIndex
    end
end

function ViewmodelFieldArray:GetItemNum()
    return #self.FieldValue
end

function ViewmodelFieldArray:SetItems(Items)
    self.FieldValue = {}
    if type(Items) == 'table' then
        for i = 1, #Items do
            self:AddItem(Items[i], true)
        end
        self:BroadcastValueChanged()
    end
end

---@return ViewmodelField
function ViewmodelFieldArray:AddItem(NewItem, NotBroadcast)
    if not NewItem then
        return
    end

    local WrappedItem = nil
    if NewItem.__IsViewModelInterface__ then
        WrappedItem = NewItem
    else
        WrappedItem = Super(ViewmodelFieldArray).new(self:GetViewModel(), NewItem)
    end
    table.insert(self.FieldValue, WrappedItem)

    if not NotBroadcast then
        self:BroadcastValueChanged('AddItem', WrappedItem)
    end
    return WrappedItem
end

function ViewmodelFieldArray:RemoveItemByIndex(InIndex, NotBroadcast)
    if InIndex > 0 and InIndex <= #self.FieldValue then
        local WrappedItem = self.FieldValue[InIndex]
        WrappedItem:ReleaseVMObj()
        table.remove(self.FieldValue, InIndex)
        
        if not NotBroadcast then
            self:BroadcastValueChanged('RemoveItem', {WrappedItem})
        end
    end
end

---@return Item ViewmodelField
function ViewmodelFieldArray:RemoveItem(Item, NotBroadcast)
    local tbRemovedField = {}
    TableUtil:ArrayRemoveIf(self.FieldValue, function(WrappedItem)
        if Item == WrappedItem then
            table.insert(tbRemovedField, WrappedItem)
            WrappedItem:ReleaseVMObj()
            return true
        end
    end)
    if #tbRemovedField > 0 then
        if not NotBroadcast then
            self:BroadcastValueChanged('RemoveItem', tbRemovedField)
        end
    end
    return tbRemovedField
end

function ViewmodelFieldArray:RemoveItemIf(fnCall, NotBroadcast)
    if not fnCall then
        return
    end

    local tbRemovedField = {}
    TableUtil:ArrayRemoveIf(self.FieldValue, function(WrappedItem)
        if fnCall(WrappedItem) then
            table.insert(tbRemovedField, WrappedItem)
            WrappedItem:ReleaseVMObj()
            return true
        end
    end)
    if #tbRemovedField > 0 then
        if not NotBroadcast then
            self:BroadcastValueChanged('RemoveItem', tbRemovedField)
        end
    end
    return tbRemovedField
end

function ViewmodelFieldArray:ClearItems(NotBroadcast)
    for i, WrappedItem in ipairs(self.FieldValue) do
        WrappedItem:ReleaseVMObj()
    end
    self.FieldValue = {}
    if not NotBroadcast then
        self:BroadcastValueChanged()
    end
end

local function fnIterator(state)
	local tb = state.tb
	local pos = state.pos
	if pos <= #tb then
		state.pos = pos + 1
		return tb[pos]
	end
end

function ViewmodelFieldArray:Items_Iterator()
	local state = { tb = self.FieldValue, pos = 1 }
	return fnIterator, state
end


return ViewmodelFieldArray
