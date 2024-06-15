--
-- DESCRIPTION
-- 多角色共享怪谈技能的释放顺序，所以怪谈技能配置信息和技能释放
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")
local utils = require("common.utils")
local SkillData = require("common.data.skill_list_data").data
local ItemEffectUtils = require("common.utils.item_effect_utils")
local ItemData = require("common.data.item_base_data")
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local mutable_actor_operations = require("actor_management.mutable_actor_operations")
---@type BP_AssistTeamComponent_C
local AssistTeamComponent = Component(ComponentBase)
local decorator = AssistTeamComponent.decorator

local ItemUseAssistSkillEffectType = ItemData.Assist

ItemEffectUtils:RegisterItemEffect(ItemUseAssistSkillEffectType, function(Owner, Target, UseParams) 
    if Owner and Owner.BP_AssistTeamComponent then
        Owner.BP_AssistTeamComponent:OnAssistMonsterItemUseCallBack(Target, UseParams)
    end
end)

function AssistTeamComponent:ReceiveBeginPlay()
    Super(AssistTeamComponent).ReceiveBeginPlay(self)
    self.__TAG__ = string.format("AssistTeamComponent(%s, server: %s)", G.GetObjectName(self), self.actor:IsServer())

end

function AssistTeamComponent:OnAssistMonsterItemUseCallBack(Target, UseParams)
    G.log:info(self.__TAG__, "AssistTeamComponent::OnAssistMonsterItemUseCallBack %s", G.GetObjectName(self.actor:GetPawn()))
    self:Client_UseAssistSkill()
    -- local Actor = self.actor:GetPawn()
    -- if Actor then
    --     Actor:SendMessage("AssistSkill")
    -- end
    --
end

function AssistTeamComponent:Server_ChangeSkillIndex(NewIndex)
    G.log:info("yb", "AssistTeamComponent Server_ChangeSkillIndex")
    self.CurSkillIndex = NewIndex
end

function AssistTeamComponent:Server_SetAssistSkills(NewSkills)
    self.AssistSkills = NewSkills
end

decorator.message_receiver()
function AssistTeamComponent:PostBeginPlay()
    local Actor = self.actor:GetPawn()
    if Actor then
        Actor:SendServerMessage("LearnAssistSkill")
    end
end

-- decorator.message_receiver()
-- function AssistTeamComponent:PostBeginPlay()
--     self:ReqLearnAssistSkill()
-- end

--run on client--
decorator.message_receiver()
function AssistTeamComponent:UseAssistItem()
    local Actor = self.actor:GetPawn()
    --状态机和技能管理组件只有客户端有，所以只能客户端先检查下技能是否能释放
    if  not Actor.SkillComponent:CheckAssistSkill() then
        return
    end
    local ActorID = mutable_actor_operations.GetMutableActorID(Actor)
    self.actor.ItemManager:Server_UseItemByExcelID(self.AssistItemID, 1, ActorID)
end


function AssistTeamComponent:Client_UseAssistSkill_RPC()
    --角色释放技能，只能从owner客户端发起
    local Actor = self.actor:GetPawn()
    if Actor then
        Actor:SendMessage("AssistSkill")
    end
end 

--run on server--
function AssistTeamComponent:Server_EquipAssistItem_RPC(NewAssistItemID)
    G.log:info(self.__TAG__, "AssistTeamComponent:Server_EquipAssistItem_RPC %s", NewAssistItemID)
    local PreAssistItemID = self.AssistItemID
    if PreAssistItemID ~= 0 then
        self:DoUnEquipAssistItem(PreAssistItemID)
    end
    self:DoEquipAssistItem(NewAssistItemID)
    G.log:info(self.__TAG__, "AssistTeamComponent:DoEquipAssistItem %s %s", self.AssistItemID, self.AssistSkillID)
end

function AssistTeamComponent:DoEquipAssistItem(NewAssistItemID)
    local ItemData = ItemUtil.GetItemConfigByExcelID(NewAssistItemID)
    if not ItemData then
        return
    end
    local UseParams = ItemData["item_use_details"]
    local SkillID = tonumber(UseParams[1])
    self.AssistItemID = NewAssistItemID
    self.AssistSkillID = SkillID
    G.log:info(self.__TAG__, "AssistTeamComponent:DoEquipAssistItem %s %s", self.AssistItemID, self.AssistSkillID)
    self:ReqLearnAssistSkill()
end

function AssistTeamComponent:OnRep_AssistSkillID()
    -- local Actor = self.actor:GetPawn()
    -- if Actor then
    --     Actor:SendServerMessage("InitAssistSkill")
    -- end
end

function AssistTeamComponent:Server_UnEquipAssistItem_RPC(PreAssistItemID)
    self:DoUnEquipAssistItem(PreAssistItemID)
    if self.AssistItemID == PreAssistItemID then
        self.AssistItemID = 0
        self.AssistSkillID = 0
    end
end

function AssistTeamComponent:DoUnEquipAssistItem(PreAssistItemID)
    local ItemData = ItemUtil.GetItemConfigByExcelID(PreAssistItemID)
    if not ItemData then
        return
    end
    local UseParams = ItemData["item_use_details"]
    local SkillID = tonumber(UseParams[1])
    self:ReqForgetAssistSkill(SkillID)
end

function AssistTeamComponent:ReqLearnAssistSkill()
    local Actor = self.actor:GetPawn()
    if Actor then
        Actor:SendServerMessage("LearnAssistSkill")
    end
end

--升级怪谈道具/装卸怪谈道具都应该先遗忘原本的怪谈技能
function AssistTeamComponent:ReqForgetAssistSkill(PreAssistSkillID)
    local Actor = self.actor:GetPawn()
    if Actor then
        Actor:SendServerMessage("ForgetSkill", PreAssistSkillID)
    end
end



-- function AssistTeamComponent:LearnSkill(SkillID)
--     G.log:info(self.__TAG__, "AssistTeamComponent:LearnSkill %s", SkillID)
--     local GAClassPath = SkillData[SkillID]["skill_path"]
--     local GAClass = UE.UClass.Load(GAClassPath)
--     local UserData = utils.MakeUserData()
--     UserData.SkillID = SkillID
--     G.log:debug(self.__TAG__, "Give ability GA: %s, SkillID: %d", GAClassPath, SkillID)
--     UE.UHiGASLibrary.GiveAbility(self.actor, GAClass, -1, UserData)
-- end

-- function AssistTeamComponent:GetAssistSkillState()
--     local ASC = self.actor:GetAbilitySystemComponent()
--     local AbilitySpec = SkillUtils.FindAbilitySpecFromSkillID(ASC, self.AssistSkillID)
--     local Abilities = ASC.ActivatableAbilities.Items
--     if AbilitySpec then
--         local Handle = GASpec.Handle
--         local Ability = GASpec.Ability
--         local ActorInfo = ASC:GetAbilityActorInfo()
--         local TimeRemaining, CooldownDuration = Ability:GetCooldownRemainingAndDuration(Handle, ActorInfo)
--         G.log:debug(self.__TAG__, "AssistTeamComponent:GetAssistSkillState TimeRemaining(%s) CooldownDuration(%s)", TimeRemaining, CooldownDuration)
--         return TimeRemaining, CooldownDuration
--     end
--     return 0, 0
-- end

return AssistTeamComponent
