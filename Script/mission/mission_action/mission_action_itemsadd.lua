--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local json = require("thirdparty.json")
local MissionActionBase = require("mission.mission_action.mission_action_base")

---@type BP_MissionAction_ItemsAdd_C
local MissionActionItemsAdd = Class(MissionActionBase)

function MissionActionItemsAdd:OnActive()
    Super(MissionActionItemsAdd).OnActive(self)
    self:RunActionOnActorByTag("HiGamePlayer", self:GenerateActionParam())
end

function MissionActionItemsAdd:GenerateActionParam()
    local ItemsInfo = {}
    for Ind=1,self.ItemInfos:Length() do
        local ItemNode = self.ItemInfos:Get(Ind)
        table.insert(ItemsInfo, {ItemID=ItemNode.ItemID,ItemNum=ItemNode.ItemNum})
    end
    local Param = {
        ItemsInfo=ItemsInfo
    }
    return json.encode(Param)
end

function MissionActionItemsAdd:Run(PlayerState, ActionParamStr)
    Super(MissionActionItemsAdd).Run(self, PlayerState, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    local ItemManager = PlayerState:GetPlayerController().ItemManager
    if Param.ItemsInfo then
        for _,ItemNode in ipairs(Param.ItemsInfo) do
            ItemManager:AddItemByExcelID(ItemNode.ItemID,ItemNode.ItemNum)
        end
    end
end

function MissionActionItemsAdd:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return MissionActionItemsAdd
