require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_FindRandomCaptureble = Class(BTTask_Base)


function BTTask_FindRandomCaptureble:Execute(Controller, Pawn)

    local TargetActors = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(Pawn:GetWorld(), UE.AActor, TargetActors)

    -- G.log:debug("yj", "BTTask_FindRandomCaptureble:Execute %s", TargetActors:Length())
    for i = 1, TargetActors:Length() do
        local Target = TargetActors[i]
        if Target and Target ~= Pawn and (Target.CharIdentity == Enum.Enum_CharIdentity.Monster or Target.CharIdentity == Enum.Enum_CharIdentity.NPC) and Target.InteractionComponent.CaptureBy == nil then
            ai_utils.MakeBattleTargetPair(Pawn, Target)
            return ai_utils.BTTask_Succeeded
        end
    end

    return ai_utils.BTTask_Failed
end


return BTTask_FindRandomCaptureble
