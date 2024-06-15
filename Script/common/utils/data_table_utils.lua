local G = require("G")

local M = {}

M.AKAudioResourceTable = "/Game/Data/Datatable/AKAudio/DT_AKAudioResource_Composite.DT_AKAudioResource_Composite"
M.MovieResourceTable = "/Game/Data/Datatable/DT_Media.DT_Media"
M.ResourceIndexMainTable = "/Game/Data/Datatable/DT_ResourceIndex_Main.DT_ResourceIndex_Main"
M.AreaAbilityTable = "/Game/Data/Datatable/DT_AreaAbility.DT_AreaAbility"
M.InputConfigTable = "/Game/Data/Datatable/DT_InputConfig.DT_InputConfig"
M.AreaAbilityMap = {bInit=false}


function M.LoadDataTable(DataTablePath)
    -- todo Add Cache for DataTable
    return UE.UObject.Load(DataTablePath)
end

function M.GetAreaAbilityRow(SMActor)
    local RowMap = M.GetAreaAbilityRowMap()
    local Cls = UE.UGameplayStatics.GetClass(SMActor)
    local PathName = tostring(UE.UKismetSystemLibrary.GetPathName(Cls))
    local SubPathName = PathName:sub(1, -3)
    if RowMap[SubPathName] then -- Blurprint
        return RowMap[SubPathName]
    end
    if SMActor and SMActor.StaticMeshComponent and SMActor.StaticMeshComponent.StaticMesh then -- StatiMesh
        local PathName = UE.UKismetSystemLibrary.GetPathName(SMActor.StaticMeshComponent.StaticMesh)
        return RowMap[PathName]
    end
end

function M.GetAreaAbilityRowMap()
    if not M.AreaAbilityMap.bInit then
        local OutRowNames = M.GetDataTableRowNames(M.AreaAbilityTable)
        for Ind=1,OutRowNames:Length() do
            local RowName = OutRowNames[Ind]
            local Data = M.GetDataTableRow(M.AreaAbilityTable, RowName)
            if Data.Mesh then
                --local PathName = UE.UKismetSystemLibrary.GetPathName(Data.Mesh)
                M.AreaAbilityMap[tostring(Data.Mesh)] = Data
            end
        end
        M.AreaAbilityMap.bInit = true
    end
    return M.AreaAbilityMap
end

function M.GetDataTableRowNames(TableName)
    local DataTable = M.LoadDataTable(TableName)
    local OutRowNames = UE.UDataTableFunctionLibrary.GetDataTableRowNames(DataTable)
    return OutRowNames
end

function M.GetDataTableRow(TableName, RowName)
    local DataTable = M.LoadDataTable(TableName)
    local RowData = UE.UDataTableFunctionLibrary.GetRowDataStructure(DataTable, RowName)
    return RowData
end

function M.GetAudioPathByDataTableID(AudioID)
    if AudioID then
        local AudioData = M.GetDataTableRow(M.AKAudioResourceTable, AudioID)
        if AudioData ~= nil then
            if not AudioData.AKEvent:IsNull() then
                return tostring(AudioData.AKEvent)
            end
        end
    end
end

function M.GetMediaDataByDataTableID(MediaID)
    if MediaID then
        return M.GetDataTableRow(M.MovieResourceTable, MediaID)
    else
        return nil 
    end
end


function M.GetInputConfigDataByDataTableID(InputKey)
    if InputKey then
        return M.GetDataTableRow(M.InputConfigTable, InputKey)
    else
        return nil 
    end
end

return M
