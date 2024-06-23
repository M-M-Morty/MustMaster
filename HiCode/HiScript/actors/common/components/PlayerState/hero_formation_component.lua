local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

-- BP_HeroFormationComponent
local HeroFormationComponent = Component(ComponentBase)
local decorator = HeroFormationComponent.decorator

local MAX_FORMATION_INDEX = 6

function HeroFormationComponent:ReceiveBeginPlay()
    Super(HeroFormationComponent).ReceiveBeginPlay(self)
    local bIsServer = self.actor:IsServerAuthority()
    if bIsServer then
        -- FIXME(hangyuewang): 目前没有账号创建选角逻辑，先硬编码一个初始队伍
        self.BattleFormationIndex = 1
        for i = 1, 4 do
            local HeroFormation = Struct.BPS_HeroFormationInfo()
            self.HeroFormationList:Add(HeroFormation)
        end
        local HeroFormation = self.HeroFormationList:GetRef(1)
        HeroFormation.FormationName = "测试队伍"
        HeroFormation.HeroList:Add(4)
        HeroFormation.HeroList:Add(5)
        HeroFormation.HeroList:Add(6)
        HeroFormation.HeroList:Add(8)
        HeroFormation.AssistSlot.SlotType = Enum.BPE_FormationAssistSlotType.Assist
        HeroFormation.AssistSlot.AssistID = 309999
    end
end

-- 是否能修改编队数据
function HeroFormationComponent:CanChangeFormation()
    -- 玩家在战斗状态无法修改编队数据
    -- TODO(hangyuewang): 战斗状态无法切换
    return true
end

function HeroFormationComponent:IsFormationEmpty(FormationInfo)
    for i = 1, FormationInfo.HeroList:Length() do
        local HeroID = FormationInfo.HeroList:GetRef(i)
        if HeroID ~= 0 then
            return true
        end
    end
    return false
end

function HeroFormationComponent:Server_ChangeBattleFormation_RPC(FormationIndex)
    if not self:CanChangeFormation() then
        return
    end

    if FormationIndex < 1 or FormationIndex > self.HeroFormationList:Length() then
        G.log:warn("HeroFormationComponent", "Server_ChangeBattleFormation FormationIndex(%s) wrong, max=%s", 
            FormationIndex, self.HeroFormationList:Length())
        return
    end

    if FormationIndex == self.BattleFormationIndex then
        G.log:warn("HeroFormationComponent", "Server_ChangeBattleFormation FormationIndex(%s) is current battle index", FormationIndex)
        return
    end

    local FormationInfo = self.HeroFormationList:GetRef(FormationIndex)
    if self:IsFormationEmpty(FormationInfo) then
        G.log:warn("HeroFormationComponent", "Server_ChangeBattleFormation FormationIndex(%s) FormationData empty", FormationIndex)
        return
    end

    self.BattleFormationIndex = FormationIndex
    -- TODO(hangyuewang): 使用FormationInfo修改大世界的队伍数据
end

function HeroFormationComponent:Server_ChangeFormationInfo_RPC(FormationIndex, FormationInfo)
    if not self:CanChangeFormation() then
        return
    end

    if FormationIndex < 1 or FormationIndex > self.HeroFormationList:Length() then
        G.log:warn("HeroFormationComponent", "Server_ChangeFormationInfo FormationIndex(%s) wrong, max=%s", 
            FormationIndex, self.HeroFormationList:Length())
        return
    end
    -- 检查FormationInfo的合法性
    -- TODO(hangyuewang): 检查英雄和怪谈是否都存在，怪谈是否被其他武器装备，当前出战的队伍英雄数不能少于1


    self.HeroFormationList:Set(FormationIndex, FormationInfo)
end

function HeroFormationComponent:Server_ChangeFormationName_RPC(FormationIndex, FormationName)
    if not self:CanChangeFormation() then
        return
    end

    -- TODO(hangyuewang): FormationName的长度和敏感词检测
    if FormationIndex < 1 or FormationIndex > self.HeroFormationList:Length() then
        G.log:warn("HeroFormationComponent", "Server_ChangeFormationName FormationIndex(%s) wrong, max=%s", 
            FormationIndex, self.HeroFormationList:Length())
        return
    end

    local HeroFormation = self.HeroFormationList:GetRef(FormationIndex)
    HeroFormation.FormationName = FormationName
end

function HeroFormationComponent:Server_AddHeroFormation_RPC()
    if not self:CanChangeFormation() then
        return
    end
    if self.HeroFormationList:Length() >= MAX_FORMATION_INDEX then
        G.log:warn("HeroFormationComponent", "Server_AddHeroFormation HeroFormationList full, Length=%s", self.HeroFormationList:Length())
        return
    end
    -- 添加个空队伍
    local HeroFormation = Struct.BPS_HeroFormationInfo()
    self.HeroFormationList:Add(HeroFormation)
end

function HeroFormationComponent:Server_RemoveHeroFormation_RPC(FormationIndex)
    if not self:CanChangeFormation() then
        return
    end
    if FormationIndex < 1 or FormationIndex > self.HeroFormationList:Length() then
        G.log:warn("HeroFormationComponent", "Server_RemoveHeroFormation FormationIndex(%s) wrong, max=%s", 
            FormationIndex, self.HeroFormationList:Length())
        return
    end
    if FormationIndex == self.BattleFormationIndex then
        G.log:warn("HeroFormationComponent", "Server_RemoveHeroFormation FormationIndex(%s) is BattleFormationIndex", FormationIndex)
        return
    end

    -- 修正出战队伍Index
    if FormationIndex < self.BattleFormationIndex then
        self.BattleFormationIndex = self.BattleFormationIndex - 1
    end

    self.HeroFormationList:Remove(FormationIndex)
end

return HeroFormationComponent