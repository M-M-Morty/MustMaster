--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")

local BPConst = require("common.const.blueprint_const")
local BaseNPC = require("actors.common.BaseNPC")

---@type BP_TestMissionNPC_C
local TestMissionNPC = Class(BaseNPC)

function TestMissionNPC:GetSaveDataClass()
    return BPConst.GetTestMissionNPCSaveDataClass()
end

function TestMissionNPC:LoadFromSaveData(SaveData)
    Super(TestMissionNPC).LoadFromSaveData(self, SaveData)
    G.log:debug("xaelpeng", "TestMissionNPC:LoadFromSaveData NPCName:%s ToplogoImgPath:%s", SaveData.NPCName, SaveData.ToplogoImgPath)
    self.NPCName = SaveData.NPCName
    if SaveData.ToplogoImgPath == "" then
        self.ToplogoImage = UE.UObject.Load(SaveData.ToplogoImgPath)
    else
        self.ToplogoImage = nil
    end
end

function TestMissionNPC:SaveToSaveData(SaveData)
    Super(TestMissionNPC).SaveToSaveData(self, SaveData)
    SaveData.NPCName = self.NPCName
    if self.ToplogoImage == nil then
        SaveData.ToplogoImgPath = ""
    else
        SaveData.ToplogoImgPath = UE.UKismetSystemLibrary.GetPathName(self.ToplogoImage)
    end
end

function TestMissionNPC:SetNPCName(NPCName)
    self.NPCName = NPCName
end

function TestMissionNPC:SetToplogoImgPath(ToplogoImgPath)
    if ToplogoImgPath ~= "" then
        self.ToplogoImage = UE.UObject.Load(ToplogoImgPath)
    else
        self.ToplogoImage = nil
    end
end

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function TestMissionNPC:ReceiveBeginPlay()
    Super(TestMissionNPC).ReceiveBeginPlay(self)
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return TestMissionNPC
