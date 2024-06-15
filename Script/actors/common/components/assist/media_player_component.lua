--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local DataTableUtils = require("common.utils.data_table_utils")
local G = require("G")

local MediaPlayComponent = Component(ComponentBase)

function MediaPlayComponent:ReceiveBeginPlay()
    Super(MediaPlayComponent).ReceiveBeginPlay(self)
    self.__TAG__ = string.format("MediaPlayComponent(%s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
    self.MaterialInstance = nil
end

function MediaPlayComponent:PlayMedia(MediaKey)
    local Movie = DataTableUtils.GetMediaDataByDataTableID(MediaKey)
    if Movie and self.actor:IsClient() then
        -- 修改贴图材质
        --local Materials = self.actor.Mesh:GetMaterials()
        -- G.log:info(self.__TAG__, "play media modify material %s", Materials:Length())
        -- if self.MaterialIndex <= 0 then return end
        -- local Material = Materials:Get(self.MaterialIndex)
        -- if not Material then return end
        -- self.MaterialInstance = UE.UKismetMaterialLibrary.CreateDynamicMaterialInstance(0, Material)
        -- G.log:info(self.__TAG__, "play media modify material %s", Material:GetName())
        -- local Texture = UE.UMediaTexture.Load(Movie.MediaTexture)
        -- self.actor.Mesh:SetMaterial(self.MaterialIndex - 1, self.MaterialInstance)
        -- -- 播放对应的media  
        -- self.MediaPlayer = UE.UMediaPlayer.Load(Movie.MediaPlayer)
        local Source = UE.UMediaSource.Load(Movie.MediaSource)
        self.MediaPlayer:OpenSource(Source)
    end 
end


function MediaPlayComponent:ReceiveEndPlay()
    Super(MediaPlayComponent).ReceiveEndPlay(self)
    if self.MediaPlayer then
        self.MediaPlayer:Close()
    end
    -- if self.MaterialInstance then
    --     self.MaterialInstance:SetScalarParameterValue("Image Brightness", 0)
    --     self.actor.Mesh:SetMaterial(self.MaterialIndex - 1, self.MaterialInstance)
    -- end 
end

return MediaPlayComponent
