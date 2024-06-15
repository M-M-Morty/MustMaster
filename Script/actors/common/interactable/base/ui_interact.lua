require "UnLua"
local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local utils = require("common.utils")
local decorator = require("common.decorator").new()

local M = Class()

function M:Construct()
	self.Overridden.Construct(self)
	self:BindDelegate()
end


function M:BindDelegate()
	self.btn_interact.OnPressed:Add(self, M.OnPressed_ButtonInteract)
	self.btn_interact.OnReleased:Add(self, M.OnReleased_ButtonInteract)
end

function M:OnPressed_ButtonInteract()
end

function M:OnReleased_ButtonInteract()
end

return M