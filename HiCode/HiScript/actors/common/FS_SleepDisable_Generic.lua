require "UnLua"
---Destructible base actor and implement BPI_Destructible interface.
---Child class can overwrite this to show different break behavior.

local table = require("table")
local G = require("G")
local BPConst = require ("common.const.blueprint_const")
local utils = require("common.utils")
local MutableActorOperations = require("actor_management.mutable_actor_operations")

local ActorBase = require("actors.common.interactable.base.base_item")
--local Actor = require("common.actor")

local M = Class(ActorBase)

function M:LogInfo(...)
    G.log:info_obj(self, ...)
end

function M:LogDebug(...)
    G.log:debug_obj(self, ...)
end

function M:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function M:LogError(...)
    G.log:error_obj(self, ...)
end

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:GetAbilitySystemComponent()
    return self.HiAbilitySystemComponent
end

return RegisterActor(M)
