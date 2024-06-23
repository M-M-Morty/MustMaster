--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

--[[ Usage:
	
	local LinkListUtil = require('linklist_utl')

	local LinkList = LinkListUtil:CreateList()

	local LinkNode1 = LinkListUtil.NodeClass.new()
	local LinkNode2 = NodeSubClass1.new()	-- NodeSubClass1 inherit from NodeClass
	local LinkNode3 = NodeSubClass2.new()
	local LinkNode4 = NodeSubClass3.new()

	LinkList:AddHead(LinkNode1)
	LinkList:AddTail(LinkNode2)
	LinkList:InsertAfter(LinkNode1, LinkNode3)
	LinkList:InsertBefore(LinkNode3, LinkNode4)

	for Node in LinkList:Nodes_Iterator() do
		LinkList:RemoveNode(Node)	-- or Node:RemoveFromContainer()
	end

]]

local G = require('G')

local LinkListUtil = {}

---@class LuaLinkListNode
local NodeClass = Class()
LinkListUtil.NodeClass = NodeClass

function NodeClass:ctor()
	self.Container = nil
	self.NextNode = nil
	self.PrevNode = nil
end

---@return LuaLinkList
function NodeClass:GetContainer()
	return self.Container
end

function NodeClass:RemoveFromContainer()
	if self.Container then
		self.Container:RemoveNode(self)
	end
end

---@class LuaLinkList
local ListClass = {}

function ListClass:Constructor()
	self.AloneNode = NodeClass.new()
	self.AloneNode.Container = self
	self.AloneNode.NextNode = self.AloneNode
	self.AloneNode.PrevNode = self.AloneNode

	self.SizeNum = 0
end

function ListClass:GetSize()
	return self.SizeNum
end

---@param NewNode LuaLinkListNode
function ListClass:AddHead(NewNode)
	self:InsertAfter(self.AloneNode, NewNode)
end

---@param NewNode LuaLinkListNode
function ListClass:AddTail(NewNode)
	self:InsertBefore(self.AloneNode, NewNode)
end

---@param NodeWhere LuaLinkListNode
---@param NewNode LuaLinkListNode
function ListClass:InsertAfter(NodeWhere, NewNode)
	if NodeWhere.Container == self and NewNode.Container == nil then
		NewNode.Container = self

		NewNode.PrevNode = NodeWhere
		NodeWhere.NextNode.PrevNode = NewNode
		NewNode.NextNode = NodeWhere.NextNode
		NodeWhere.NextNode = NewNode

		self.SizeNum = self.SizeNum + 1
	end
end

---@param NodeWhere LuaLinkListNode
---@param NewNode LuaLinkListNode
function ListClass:InsertBefore(NodeWhere, NewNode)
	if NodeWhere.Container == self and NewNode.Container == nil then
		NewNode.Container = self

		NewNode.NextNode = NodeWhere
		NodeWhere.PrevNode.NextNode = NewNode
		NewNode.PrevNode = NodeWhere.PrevNode
		NodeWhere.PrevNode = NewNode

		self.SizeNum = self.SizeNum + 1
	end
end

---@param Node LuaLinkListNode
function ListClass:RemoveNode(Node)
	if self == Node.Container and Node ~= self.AloneNode then
		local NextNode = Node.NextNode
		local PrevNode = Node.PrevNode

		if NextNode.PrevNode ~= Node or PrevNode.NextNode ~= Node or self.SizeNum <= 0 then
			G.log:warn('gh_utils', 'LinkList structure is broken')
			return
		end

		-- cut linked node
		PrevNode.NextNode = NextNode
		NextNode.PrevNode = PrevNode
		
		Node.Container = nil
		Node.NextNode = nil
		Node.PrevNode = nil

		self.SizeNum = self.SizeNum - 1
		
		return NextNode
	end
end


function ListClass:Clear()
	while self.SizeNum > 0 do
		self:RemoveNode(self.AloneNode.NextNode)
	end
end

local function ListNode_Iterator(state)
	local ListObj = state.ListObj
	local NodeObj = state.NodeObj
	if NodeObj ~= ListObj.AloneNode then
		state.NodeObj = NodeObj.NextNode
		return NodeObj
	end
end

function ListClass:Nodes_Iterator()
	local state = { ListObj = self, NodeObj = self.AloneNode.NextNode }
	return ListNode_Iterator, state
end


---@return LuaLinkList
function LinkListUtil:CreateList()
	local obj = setmetatable({}, {
		__index = ListClass
	})
	obj:Constructor()
	return obj
end

return LinkListUtil
