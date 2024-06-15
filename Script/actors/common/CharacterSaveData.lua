local Util = require('common.utils')
local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local CharacterSaveData = Component(ComponentBase)

function CharacterSaveData:ReadCharacersData(SaveData)
    --TODO 假数据
    SaveData = 
    {

        [9999] =
        {
            LearnedSkills =
            {
                [9999] = 1,
            },
            PendingUnlockSkills =
            {
                9999,
            }
        }
        
    }
end

function CharacterSaveData:SaveCharactersData()
    --TODO 存数据库
end

--记录新学习技能
function CharacterSaveData:AddLearnedSkill(SaveData, CharacterType, SkillID)
    if SaveData == nil then
        G.log:error("PlayerSaveData", "AddLearnedSkill SaveData is nil")
        return        
    end

    if SaveData[CharacterType] == nil then
        SaveData[CharacterType] = 
        {
            LearnedSkills = {},
            PendingUnlockSkills = {}
        }
    end
    
    if(SaveData[CharacterType].LearnedSkills[SkillID] == nil) then
        table.insert(SaveData[CharacterType].LearnedSkills, SkillID)
    end
    
    table.remove(SaveData[CharacterType].PendingUnlockSkills, SkillID)            
end

--标记待解锁技能
function CharacterSaveData:AddPendingUnlockSkill(SaveData, CharacterType, SkillID)
    if(SaveData[CharacterType] ~= nil) then
        if(Util:find(SaveData[CharacterType].PendingUnlockSkills, SkillID) == 0) then
            table.insert(SaveData[CharacterType].PendingUnlockSkills, SkillID)
        end
    end    
end

--角色升级
function CharacterSaveData:ChangeCharacterLevel(SaveData, CharacterType, NewLevel )
    if SaveData[CharacterType] ~= nil then
        SaveData[CharacterType].CharacterLevel = NewLevel

        self:SaveCharactersData()
    else
        G.log:error("PlayerSaveData", "CharacterLevelUP CharacterType:%s not exist", CharacterType)
    end
end

--技能升级
function CharacterSaveData:CharacterSkillLevelUp(SaveData, CharacterType , SkillID, NewLevel)
    if SaveData[CharacterType] ~= nil then
        SaveData[CharacterType].LearnedSkills[SkillID] = NewLevel
        
        self:SaveCharactersData()
    else
        G.log:error("PlayerSaveData", "CharacterSkillUP CharacterType:%s not exist", CharacterType)
    end
end

return CharacterSaveData