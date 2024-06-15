--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_LampGroupLogic_C
local math = require("math")
local G = require("G")
local ActorBase = require("actors.common.interactable.base.base_item")
local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:CanActive(OtherActor)
    if not self:IsServer() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return false
    end
    local Owner = OtherActor:GetOwner()
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    --G.log:debug("zsf", "CanActive %s %s %s %s %s", self:IsClient(), self:IsServer(), Owner, PlayerControl, Owner==PlayerControl)
    return Owner == PlayerControl
end

function M:AllChildReadyClient()
    self:LogInfo("zsf", "[bp_lamp_group_logic] AllChildReadyClient")
    Super(M).AllChildReadyClient(self)
end

function M:AllChildReadyServer()
    self:LogInfo("zsf", "[bp_lamp_group_logic] AllChildReadyServer")
    self:TryMakeGamePlay()
    Super(M).AllChildReadyServer(self)
end

function M:MakeLampPlayLogic()
    --取配置数据(具体配置的优先级可以根据实际使用决策)
    local GroupMin = 3;
    local GroupMax = 6;
    local HpMin = 10
    local HpMax = 20
    if self.UniformConfig then
        GroupMin = self.UniformConfig.LampCountMin;
        GroupMax = self.UniformConfig.LampCountMax;
        HpMin = self.UniformConfig.LampHpMin;
        HpMax = self.UniformConfig.LampHpMax;
    end
    if self.OverridenConfig then
        GroupMin = self.LampCountRange.X;
        GroupMax = self.LampCountRange.Y;
    end
    local IDs = self:GetActorIds("LinkActors")
    self:LogInfo("zsf", "[bp_lamp_group_logic] HiGame###  total:LAMP IS NOT IN %s %s %s", IDs, GroupMin, GroupMax)
    local count = #IDs
    if count < 1 then
        self:LogInfo("zsf", "[bp_lamp_group_logic] CANT FIND ANY LAMP %s", UE.UKismetSystemLibrary.GetPathName(self))
        return;
    end

    self.tbLampActors = {}
    for i = 1, count do
        local EditorID = IDs[i]
        local lamp_obj = self:GetEditorActor(EditorID)
        if lamp_obj and lamp_obj.IsUnderGameLogic then
            self:LogInfo("zsf", "[bp_lamp_group_logic] HiGame###  inst: %s %s %s", G.GetDisplayName(lamp_obj), lamp_obj:IsUnderGameLogic(), self:IsServer())
            if not lamp_obj:IsUnderGameLogic() then
                table.insert(self.tbLampActors, lamp_obj);
                local hp = 0
                if HpMin and HpMax then
                    hp = math.random(HpMin, HpMax);
                end
                lamp_obj:InitPlayLogic(self, #self.tbLampActors, hp);
            end
        end
    end

    if #self.tbLampActors < GroupMin then
        self:LogInfo("zsf", "[bp_lamp_group_logic] LAMP TOO LESS TO MAKE GAMEPLAY %s %s", #self.tbLampActors, GroupMin)
        return;
    end

    self.cur_index = -1
end

function M:GetLampIndex(lamp_obj)
    for i, v in ipairs(self.tbLampActors) do
        if v == lamp_obj then
            return i;
        end
    end
end

function M:GetNextLamp(curLampObj)
    local lamp_index = self:GetLampIndex(curLampObj)
    local nextIdentify = (lamp_index) % (#self.tbLampActors) + 1
    self:LogInfo("zsf", "[bp_lamp_group_logic] GetNextLamp %s", nextIdentify)
    if nextIdentify <= #self.tbLampActors then
        return self.tbLampActors[nextIdentify]
    end
end

function M:ApplyLightingLamp(lampObj)
    local nextObj = self:GetNextLamp(lampObj);
    local lamp_index = self:GetLampIndex(lampObj)
    local len = lamp_index - self.cur_index
    local result = (len == 1) or (len == (1-#self.tbLampActors)) or (self.cur_index < 0)
    self:LogInfo("zsf", "[bp_lamp_group_logic] APPLY LIGHTING LAMP %s %s %s %s", G.GetDisplayName(lampObj), result, self.cur_index, lamp_index)
    if result then
        self.cur_index = self:GetLampIndex(lampObj)
        self:LightingSucceed(lampObj);
        return true;
    else
        self.cur_index = -1
        self:LightingFailed(lampObj);
        return false;
    end
end

function M:LightingSucceed(lampObj)
    for i, v in ipairs(self.tbLampActors) do
        if not v:IsInLighting() then
            return;
        end
    end
    for i, v in ipairs(self.tbLampActors) do
        self:LogInfo('zsf', '[bp_lamp_group_logic] %s SetInteractable %s', G.GetDisplayName(self), v.SetInteractable)
        if v.SetInteractable then
            v:SetInteractable(Enum.E_InteractedItemStatus.UnInteractable)
        end
    end
    self:GameLogicComplete();
end

function M:LightingFailed(lampObj)
    self:GameLogicReset();
end

function M:GameLogicReset()
    for i, v in ipairs(self.tbLampActors) do
        v:Reset();
    end
end

function M:GameLogicComplete()
    for i, v in ipairs(self.tbLampActors) do
        v:Complete();
    end
    self:LogicComplete()
end

function M:MissionComplete(sData)
   self:CallEvent_MissionComplete(sData)
end

function M:DropAwardBox()
    if self.UniformConfig and self.UniformConfig.DropBox then
        self:GetWorld():SpawnActor(self.UniformConfig.DropBox, self:GetTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn);
    end
end

return M
