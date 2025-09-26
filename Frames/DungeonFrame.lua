---@class MPLM_Private
local private = select(2, ...)

---@class DungeonInfo : RowInfo
---@field id number
---@field index number
---@field name string
---@field image string
---@field mapId integer

---@class MPLM_DungeonHeader : MPLM_RowHeader
---@field Image Texture
---@field Label FontString
---@field DungeonHighlight Texture
MPLM_DungeonHeaderMixin = {}

---@param dungeonInfo DungeonInfo
function MPLM_DungeonHeaderMixin:Init(dungeonInfo)
    self.dungeonInfo = dungeonInfo
    self.Image:SetTexture(dungeonInfo.image)

    local dungeonName = dungeonInfo.name
    if private.db.global.useShortDungeonNames and private.dungeonShorthands[dungeonInfo.id] then
        dungeonName = private.dungeonShorthands[dungeonInfo.id]
    end
    self.Label:SetText(dungeonName)
end

function MPLM_DungeonHeaderMixin:OnSizeChanged(width, height)
    self.Image:SetWidth(height-5);
end

function MPLM_DungeonHeaderMixin:SetDungeonHighlight(value)
    self.DungeonHighlight:SetShown(value)
end

function MPLM_DungeonHeaderMixin:Reset()
    self.dungeonInfo = nil
    self.DungeonHighlight:Hide()
end

---@class MPLM_DungeonFrame : MPLM_MatrixFrame
MPLM_DungeonFrameMixin = {}

function MPLM_DungeonFrameMixin:UpdateMatrix()
    MPLM_MatrixFrameMixin.UpdateMatrix(self)
    self:UpdateDungeonHighlight()
end

function MPLM_DungeonFrameMixin:UpdateDungeonHighlight()
    local _, _, _, _, _, _, _, instanceID, _, _ = GetInstanceInfo()
    local itemButtonsOfHighlightedDungeon = nil
    for rowHeader, itemButtonsPerDungeon in pairs(self.matrixFrames.itemButtons) do
        local dungeonHeader = rowHeader ---@type MPLM_DungeonHeader
        local dungeonHighlighted = instanceID == dungeonHeader.dungeonInfo.mapId
        dungeonHeader:SetDungeonHighlight(dungeonHighlighted)

        if dungeonHighlighted then
            itemButtonsOfHighlightedDungeon = itemButtonsPerDungeon
        end
    end

    for i, slotHeader in ipairs(self.matrixFrames.slotHeaders) do
        slotHeader:SetHighlight(itemButtonsOfHighlightedDungeon and itemButtonsOfHighlightedDungeon[slotHeader] ~= nil)
    end
end

local dungeonSplits = {
    [1194] = { -- Tazavesh, the Veiled Market
        [1] = { -- Tazavesh: Streets of Wonder
            lfgDungeonId = 2329,
            encounters = {
                2437,  -- Zo'phex the Sentinel
                2454,  -- The Grand Menagerie
                2436,  -- Mailroom Mayhem
                2452,  -- Myza's Oasis
                2451,  -- So'azmi
            }
        },
        [2] = { -- Tazavesh: So'leah's Gambit
            lfgDungeonId = 2330,
            encounters = {
                2448, -- Hylbrande
                2449, -- Timecap'n Hooktail
                2455, -- So'leah
            }
        }
    }
}

function MPLM_DungeonFrameMixin:GatherItems(itemIds)
    for i = 1, EJ_GetNumLoot() do
        local lootInfo = C_EncounterJournal.GetLootInfoByIndex(i)
        if lootInfo and lootInfo.itemID and lootInfo.filterType ~= Enum.ItemSlotFilterType.Other then
            tinsert(itemIds, lootInfo.itemID)

            if lootInfo.name then
                --private.addon:Print("Found loot: " .. lootInfo.name)
                self.itemCache[lootInfo.itemID] = lootInfo
            end
        end
    end
end;

function MPLM_DungeonFrameMixin:GatherRowInfo()
    -- populates EncounterJournal global
    EncounterJournal_LoadUI()

    --Select Dungeons Tab
    EncounterJournal.instanceID = nil
    EncounterJournal.encounterID = nil
    EJ_ContentTab_Select(EncounterJournal.dungeonsTab:GetID())

    --Select Current Season
    local currentSeaonTier = EJ_GetNumTiers()
    EJ_SelectTier(currentSeaonTier)

    C_EncounterJournal.ResetSlotFilter()

    local firstInstanceId = nil

    ---@type DungeonInfo[]
    local dungeonInfos = {}

    local instanceIdx = 0
    while true do
        instanceIdx = instanceIdx + 1
        local instanceId, instanceName, _, _, _, _, image2, _, _, _, mapId  = EJ_GetInstanceByIndex(instanceIdx, false)

        if not instanceId then
            break
        end

        if not firstInstanceId then
            firstInstanceId = instanceId
        end

        EJ_SelectInstance(instanceId)

        EJ_SetDifficulty(DifficultyUtil.ID.DungeonMythic)

        --private.addon:Print("Scanning instance: " .. instanceName)

        if dungeonSplits[instanceId] then
            --private.addon:Print("Scanning split instance: " .. instanceName)
            for i, split in ipairs(dungeonSplits[instanceId]) do
                local itemIds = {}
                for _, encounterId in pairs(split.encounters) do
                    --private.addon:Print("Scanning encounter: " .. EJ_GetEncounterInfo(encounterId))
                    EJ_SelectEncounter(encounterId)
                    self:GatherItems(itemIds)
                end

                local dungeonInfo = C_LFGInfo.GetDungeonInfo(split.lfgDungeonId)
                --private.addon:Print("Found " .. #itemIds .. " items for " .. i .. ". split: " .. dungeonInfo.name)

                tinsert(dungeonInfos, {
                    id = split.lfgDungeonId,
                    index = instanceIdx,
                    tier = EJ_GetCurrentTier(),
                    name = dungeonInfo.name,
                    image = image2,
                    loot = itemIds,
                    mapId = mapId,
                })
            end
        else
            local itemIds = {}
            self:GatherItems(itemIds)

            tinsert(dungeonInfos, {
                id = instanceId,
                index = instanceIdx,
                tier = EJ_GetCurrentTier(),
                name = instanceName,
                image = image2,
                loot = itemIds,
                mapId = mapId,
            })
        end
    end

    -- woraround to keep the dungeon journal working
    EncounterJournal_DisplayInstance(firstInstanceId)
    EJ_ContentTab_Select(EncounterJournal.selectedTab)

    return dungeonInfos
end

