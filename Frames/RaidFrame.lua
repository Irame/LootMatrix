---@class LM_Private
local private = select(2, ...)

---@class BossInfo : RowInfo
---@field id number
---@field index number
---@field name string
---@field imageId number

---@class LM_RaidHeader : LM_RowHeader
---@field Image Texture
---@field Label FontString
---@field RaidHighlight Texture
LM_RaidHeaderMixin = {}

---@param bossInfo BossInfo
function LM_RaidHeaderMixin:Init(bossInfo)
    self.bossInfo = bossInfo
    self.Image:SetTexture(bossInfo.imageId)

    local raidName = bossInfo.name
    self.Label:SetText(raidName)
end

function LM_RaidHeaderMixin:OnSizeChanged(width, height)
    self.Image:SetSize(height-5, (height-5)/2);
end

function LM_RaidHeaderMixin:SetRaidHighlight(value)
    self.RaidHighlight:SetShown(value)
end

function LM_RaidHeaderMixin:Reset()
    self.bossInfo = nil
    self.RaidHighlight:Hide()
end

---@class LM_RaidFrame : LM_MatrixFrame
LM_RaidFrameMixin = {}

function LM_RaidFrameMixin:GatherRowInfo()
    -- populates EncounterJournal global
    EncounterJournal_LoadUI()

    --Select Raids Tab
    EncounterJournal.instanceID = nil
    EncounterJournal.encounterID = nil
    EJ_ContentTab_Select(EncounterJournal.raidsTab:GetID())

    --Select Current Season
    local currentSeaonTier = EJ_GetNumTiers()
    EJ_SelectTier(currentSeaonTier)

    C_EncounterJournal.ResetSlotFilter()

    local firstInstanceId = nil

    ---@type BossInfo[]
    local bossInfos = {}

    local instanceIdx = 0
    local instanceId
    while true do
        instanceIdx = instanceIdx + 1
        local nextInstanceId  = EJ_GetInstanceByIndex(instanceIdx, true)

        if not nextInstanceId then
            break
        end

        instanceId = nextInstanceId

        if not firstInstanceId then
            firstInstanceId = instanceId
        end
    end

    if not instanceId then
        return bossInfos
    end

    EJ_SelectInstance(instanceId)

    EJ_SetDifficulty(DifficultyUtil.ID.PrimaryRaidHeroic)

    --private.addon:Print("Scanning instance: " .. instanceId)

    local bossIdx = 0
    while true do
        bossIdx = bossIdx + 1

        local name, description, journalEncounterID, rootSectionID, link, journalInstanceID, dungeonEncounterID, instanceID = EJ_GetEncounterInfoByIndex(bossIdx, instanceId)

        if not journalEncounterID then
            break
        end

        local bossImage = select(5, EJ_GetCreatureInfo(1, journalEncounterID)) or "Interface\\EncounterJournal\\UI-EJ-BOSS-Default";

        EJ_SelectEncounter(journalEncounterID)

        local itemIds = {}
        self:GatherItemsFromJournal(itemIds)

        tinsert(bossInfos, {
            id = instanceId,
            index = instanceIdx,
            tier = EJ_GetCurrentTier(),
            name = name,
            imageId = bossImage,
            loot = itemIds,
        })
    end

    -- woraround to keep the raid journal working
    EncounterJournal_DisplayInstance(firstInstanceId)
    EJ_ContentTab_Select(EncounterJournal.selectedTab)

    return bossInfos
end

