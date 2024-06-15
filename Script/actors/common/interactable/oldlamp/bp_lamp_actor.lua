--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_LampActor_C

require "UnLua"
local G = require("G")
local ActorBase = require("actors.common.interactable.base.interacted_item")
local M = Class(ActorBase)

-- function BP_LampActor_C:Initialize(Initializer)
-- end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
    --self.TextRender:K2_SetText(string.format('%d, %d / %d', self.Identify, self.TotalDamage, self.HP));

    local current = UE.UGameplayStatics.GetTimeSeconds(self);
    if self.swingExpire > current then
        --self.Handle:K2_AddLocalRotation(UE.FRotator(0, 0, -8), false, nil, true);
    end

    --if self.delayLightOn > 0 then
    --    self.delayLightOn = self.delayLightOn - DeltaSeconds;
    --    if self.delayLightOn <= 0 then
    --        self.NSLightState = true;
    --        self:UpdateLightState();
    --    end
    --end
    --
    --self.Widget:SetVisibility(self.damageExpire > current, false);
end


function M:UpdateLightState()
    --self.NS_LightOn:SetActive(self.NSLightState, false);
    --self.NS_Next:SetActive(self.NSLightState, false);
end

function M:OnRep_NSLightingActive()
end

function M:Client_AddInitationScreenUI_RPC()
    G.log:info("zsf", "[lamp actor] add_ui %s %s %s %s %s", self:IsInLighting(), self:IsServer(), self.HP, self.TotalDamage, G.GetDisplayName(self))
    if not self:IsInLighting() then
        Super(M).Client_AddInitationScreenUI_RPC(self)
    end
end

function M:ReceiveDamageOnMulticast(PlayerActor, InteractLocation, bAttack)
    G.log:info("zsf", "[lamp actor] remove_ui %s %s %s %s %s", self:IsInLighting(), self:IsServer(), self.HP, self.TotalDamage, G.GetDisplayName(self))
    if self:IsInLighting() then
        Super(M).ReceiveDamageOnMulticast(self, PlayerActor, InteractLocation, bAttack)
    end
end

function M:OnRep_NextLamp()
    self:SetNextEffect(self.NextLamp)
    self:LogInfo("zsf", "[lamp_actor_lua] vEndPos %s", self.NextLamp)
    self.NS_Next:SetVariablePosition('vEndPos', self.NextLamp);
end

function M:OnRep_NSLightState()
    self:Event_PlayEffect(self.NSLightState)
end

function M:OnRep_barPercent()
    self.Widget:GetWidget().lifebar:SetPercent(self.barPercent);
end

function M:PlayLinkNextEffect()
    G.log:info("zsf", "[lamp actor] PlayLinkNextEffect %s", self.NextLamp)
end

function M:Event_Lighting(nextLampActor)
    self.NextLamp = nextLampActor.NS_Lighting:K2_GetComponentLocation();
    self.NSLightState = true;
    self.NSLightingActive = true;
    self.delayLightOn = 0.68;
    self.swingExpire = 99999;
    self:SetInteractable(Enum.E_InteractedItemStatus.UnInteractable)
end

function M:Event_LightingWrong()
end

function M:Event_Swing()
    local current = UE.UGameplayStatics.GetTimeSeconds(self);
    self.swingExpire = current + 2;
    self.damageExpire = current + 2;
end

function M:Event_Reset()
    self.NSLightState = false;
    self.swingExpire = 0;
end

function M:InitPlayLogic(masterObj, identify, hp)
    self.Identify = identify;
    if hp and hp > 0 and self.HP <= 0 then
        self.HP = hp;
    end
    self.HP = math.max(self.HP, 1);  -- 确保数据正确
    self.GamePlayMaster = masterObj;
end

function M:GetIdentify()
    return self.Identify;
end

function M:IsUnderGameLogic()
    return self.Identify >= 0;
end

function M:IsInLighting()
    return self.HP <= (self.TotalDamage or 0);
end

function M:Server_ReceiveDamage(PlayerActor, damage, InteractLocation, bAttack)
    if not self:IsUnderGameLogic() then
        G.log:info("zsf", "LAMP IS NOT IN GAME LOGIC")
        return;
    end
    if self:IsInLighting() then
        G.log:info("zsf", "LAMP IS ALREADY IN LIGHTINGL")
        return;
    end

    G.log:info("zsf", "HiGame### receive damge %s", damage)
    self.Overridden.Server_ReceiveDamage(self, PlayerActor, damage, InteractLocation, bAttack)
    if self.HP <= self.TotalDamage then
        if self.GamePlayMaster:ApplyLightingLamp(self) then
            local nextLamp = self.GamePlayMaster:GetNextLamp(self);
            self:Event_Lighting(nextLamp); -- 点亮一个灯，并显示它的指向带
        else
            self:Event_LightingWrong(); -- 点亮了一个错误的灯
        end
    else
        self:Event_Swing();  -- 摇柄转动一段时间
    end
    self:UpdateBarPercent();
end

function M:UpdateBarPercent()
    self.barPercent = (self.HP - self.TotalDamage) / self.HP;
end

function M:Reset()
    self.TotalDamage = 0.0
    G.log:info("zsf", "Reset %s %s %s", G.GetDisplayName(self), self.TotalDamage, self:IsServer())
    self:Event_Reset();    -- 灯熄，摇柄停，指向带消失
    self:SetInteractable(Enum.E_InteractedItemStatus.Interactable)
    self:UpdateBarPercent();
end

function M:Complete()
end

return M
