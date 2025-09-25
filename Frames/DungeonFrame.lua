---@class MPLM_Private
local private = select(2, ...)

---@class DungeonInfo
---@field id number
---@field index number
---@field name string
---@field image string
---@field loot number[]
---@field mapId integer

---@class MPLM_DungeonHeader : Frame
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

---@class MPLM_SlotHeader : Frame
---@field Label FontString
---@field EquippedItem1Button MPLM_ItemButton
---@field EquippedItem2Button MPLM_ItemButton
---@field DungeonHighlight Texture
MPLM_SlotHeaderMixin = {}

function MPLM_SlotHeaderMixin:Init(slot)
    self.Label:SetText(private.slotFilterToSlotName[slot])
    local slotIDs = private.slotFilterToSlotIDs[slot]

    if slotIDs[1] then
        local itemLink = GetInventoryItemLink("player", slotIDs[1])
        self.EquippedItem1Button:Init(itemLink)
    else
        self.EquippedItem1Button:Hide()
    end

    self.EquippedItem1Button:ClearAllPoints()
    if slotIDs[2] then
        local itemLink = GetInventoryItemLink("player", slotIDs[2])
        self.EquippedItem2Button:Init(itemLink)
        self.EquippedItem1Button:SetPoint("TOPRIGHT", self, "TOP", 0, -7)
    else
        self.EquippedItem2Button:Hide()
        self.EquippedItem1Button:SetPoint("TOP", 0, -7)
    end
end

function MPLM_SlotHeaderMixin:SetDungeonHighlight(value)
    self.DungeonHighlight:SetShown(value)
end

function MPLM_SlotHeaderMixin:Reset()
    self.DungeonHighlight:Hide()
end

---@class MPLM_DungeonFrame : Frame
MPLM_DungeonFrameMixin = {}

local function FramePoolDefaultReset(pool, region)
    if region.Reset then
        region:Reset()
    end
    region:Hide()
    region:ClearAllPoints()
end

local function ObjectPoolDefaultReset(pool, object)
    if object.Reset then
        object:Reset()
    end
end

local function ItemButtonContainerPoolCreate(pool)
    return private.ctor.ItemButtonContainer()
end

function MPLM_DungeonFrameMixin:OnLoad()
    self.dungeonHeaderPool = CreateFramePool("Frame", self, "MPLM_DungeonHeaderTemplate", FramePoolDefaultReset)
    self.slotHeaderPool = CreateFramePool("Frame", self, "MPLM_SlotHeaderTemplate", FramePoolDefaultReset)
    self.itemButtonPool = CreateFramePool("Button", nil, "MPLM_ItemButtonTemplate", FramePoolDefaultReset)
    self.itemButtonContainerPool = CreateObjectPool(ItemButtonContainerPoolCreate, ObjectPoolDefaultReset)

    ---@type table<number, EncounterJournalItemInfo>
    self.itemCache = {}

    ---@type DungeonInfo[]
    self.dungeonInfos = {}

    self.parent = self:GetParent() --[[@as MPLM_MainFrame]]
end

function MPLM_DungeonFrameMixin:DoScan()
    self.dungeonInfos = self:ScanDungeons()
    self:UpdateMatrix()
end

function MPLM_DungeonFrameMixin:UpdateMatrix()
    self.matrixFrames = self:BuildMatrix()
    self:UpdatSizeConstraints(self.matrixFrames)
    self:LayoutMatrix(self.matrixFrames)
    self:UpdateSearchGlow()
    self:UpdateDungeonHighlight()
end

function MPLM_DungeonFrameMixin:OnSizeChanged()
    if self.matrixFrames then
        self:LayoutMatrix(self.matrixFrames)
    end
end

---@param itemLink string
---@return integer|true|false|nil matchResult 2 = strong match, 1 = weak match, true = all stats match, false = no match, nil = invalid item link
function MPLM_DungeonFrameMixin:MatchWithStatSearch(itemLink)
    if not itemLink then return nil end

    -- different behaviour if both stat search boxes are set to the same value
    -- then we have a strong match if the higher stat is the selected stat
    -- and a weak match if the lower stat is the selected stat
    if private.db.char.stat1SearchValue and private.db.char.stat1SearchValue == private.db.char.stat2SearchValue then
        local searchValue = private.db.char.stat1SearchValue
        local orderedStats = private:GetSortedStatsInfo(itemLink)
        if orderedStats[1] and orderedStats[1].statKey == searchValue then return 2 end
        if orderedStats[2] and orderedStats[2].statKey == searchValue then return 1 end
        return false
    else
        local stats = C_Item.GetItemStats(itemLink)
        if not stats then return nil end
        local result = (stats[private.db.char.stat1SearchValue] and 1 or 0) + (stats[private.db.char.stat2SearchValue] and 1 or 0)
        return result > 0 and result or (not private.db.char.stat1SearchValue or not private.db.char.stat2SearchValue)
    end
end

function MPLM_DungeonFrameMixin:UpdateSearchGlow()
    for button in self.itemButtonPool:EnumerateActive() --[[@as fun(): MPLM_ItemButton]] do
        if button.itemLink then
            local matchResult = self:MatchWithStatSearch(button.itemLink)
            if matchResult == 2 then
                button:ShowStrongHighlight()
            elseif matchResult == 1 then
                button:ShowWeakHighlight()
            else
                button:HideWeakHighlight()
                button:HideStrongHighlight()
            end
        else
            button:HideStrongHighlight()
            button:HideWeakHighlight()
        end
    end
end

function MPLM_DungeonFrameMixin:UpdateDungeonHighlight()
    local _, _, _, _, _, _, _, instanceID, _, _ = GetInstanceInfo()
    local itemButtonsOfHighlightedDungeon = nil
    for dungeonHeader, itemButtonsPerDungeon in pairs(self.matrixFrames.itemButtons) do
        local dungeonHighlighted = instanceID == dungeonHeader.dungeonInfo.mapId
        dungeonHeader:SetDungeonHighlight(dungeonHighlighted)

        if dungeonHighlighted then
            itemButtonsOfHighlightedDungeon = itemButtonsPerDungeon
        end
    end

    for i, slotHeader in ipairs(self.matrixFrames.slotHeaders) do
        slotHeader:SetDungeonHighlight(itemButtonsOfHighlightedDungeon and itemButtonsOfHighlightedDungeon[slotHeader] ~= nil)
    end
end

function MPLM_DungeonFrameMixin:UpdatSizeConstraints(matrixFrames)
    local minHeight = #matrixFrames.dungeonHeaders * 65
    local minWidth = #matrixFrames.slotHeaders * 65

    local maxHeight = minHeight * 1.5
    local maxWidth = #matrixFrames.slotHeaders * 110

    self.parent:UpdatSizeConstraints(minWidth, minHeight, maxWidth, maxHeight)
end

function MPLM_DungeonFrameMixin:GetLootSlotsPresent()
	local isLootSlotPresent = {};
	for i, dungeonInfo in ipairs(self.dungeonInfos) do
        for j, itemId in ipairs(dungeonInfo.loot) do
            local itemInfo = self.itemCache[itemId]
            if itemInfo then
                isLootSlotPresent[itemInfo.filterType] = true;
            end
        end
	end
	return isLootSlotPresent;
end

function MPLM_DungeonFrameMixin:IsItemVisible(itemInfo)
    return itemInfo
        and itemInfo.filterType
        and itemInfo.link
        and private:IsSlotActive(itemInfo.filterType)
        and (not self.parent.hideOtherItems or self:MatchWithStatSearch(itemInfo.link))
        and true or false
end

---@param dungeonInfo DungeonInfo
function MPLM_DungeonFrameMixin:HasDungeonVisibleItems(dungeonInfo)
    for i, itemId in ipairs(dungeonInfo.loot) do
        if self:IsItemVisible(self.itemCache[itemId]) then
            return true
        end
    end
end

---@class MatrixFrames
---@field dungeonHeaders MPLM_DungeonHeader[]
---@field slotHeaders MPLM_SlotHeader[]
---@field itemButtons table<MPLM_DungeonHeader, table<MPLM_SlotHeader, ItemButtonContainer>>

function MPLM_DungeonFrameMixin:BuildMatrix()
    self.dungeonHeaderPool:ReleaseAll()
    self.slotHeaderPool:ReleaseAll()
    self.itemButtonPool:ReleaseAll()
    self.itemButtonContainerPool:ReleaseAll()

    ---@type MatrixFrames
    local matrixFrames = {
        dungeonHeaders = {},
        slotHeaders = {},
        itemButtons = {},
    }

    local dungeonToHeader = {}
    for i, dungeonInfo in ipairs(self.dungeonInfos) do
        if self:HasDungeonVisibleItems(dungeonInfo) then
            local dungeonHeader = self.dungeonHeaderPool:Acquire() --[[@as MPLM_DungeonHeader]]
            dungeonHeader:Init(dungeonInfo)

            dungeonToHeader[i] = dungeonHeader
            tinsert(matrixFrames.dungeonHeaders, dungeonHeader)
        end
    end

	local isLootSlotPresent = self:GetLootSlotsPresent();
    local slotToHeader = {}
    for i, filter in pairs(private.slotFilterOrdered) do
        if isLootSlotPresent[filter] and private:IsSlotActive(filter) then
            local slotHeader = self.slotHeaderPool:Acquire() --[[@as MPLM_SlotHeader]]
            slotHeader:Init(filter)

            slotToHeader[filter] = slotHeader
            tinsert(matrixFrames.slotHeaders, slotHeader)
        end
    end

    for i, dungeonInfo in ipairs(self.dungeonInfos) do
        local dungeonHeader = dungeonToHeader[i]

        if dungeonHeader then
            local itemButtonsFrames = {}
            for j, itemId in ipairs(dungeonInfo.loot) do
                local itemInfo = self.itemCache[itemId]

                if self:IsItemVisible(itemInfo) then
                    local slotHeader = slotToHeader[itemInfo.filterType]
                    local currentButtonContainer = itemButtonsFrames[slotHeader]
                    if not currentButtonContainer then
                        currentButtonContainer = self.itemButtonContainerPool:Acquire() --[[@as ItemButtonContainer]]
                        currentButtonContainer:Init(2, 2, self, dungeonHeader, slotHeader)
                        itemButtonsFrames[slotHeader] = currentButtonContainer
                    end

                    local itemButton = self.itemButtonPool:Acquire() --[[@as MPLM_ItemButton]]
                    itemButton:Init(itemInfo)

                    currentButtonContainer:AddButton(itemButton)
                end
            end

            matrixFrames.itemButtons[dungeonHeader] = itemButtonsFrames
        end
    end

    return matrixFrames
end

---@param matrixData MatrixFrames
function MPLM_DungeonFrameMixin:LayoutMatrix(matrixData)
    local dividerSize = 5
    local dungeonStartY = 5 + 35
    local maxCellSize = 110

    local availableHeight = self:GetHeight() - dungeonStartY;
    local dungenHeight = math.min(maxCellSize, availableHeight / #matrixData.dungeonHeaders)

    local lastDungeonHeader = nil
    for i, dungeonHeader in ipairs(matrixData.dungeonHeaders) do
        dungeonHeader:SetHeight(dungenHeight)
        if lastDungeonHeader then
            dungeonHeader:SetPoint("TOPLEFT", lastDungeonHeader, "BOTTOMLEFT", 0, 0)
        else
            dungeonHeader:SetPoint("TOPLEFT", 0, -dungeonStartY)
        end

        dungeonHeader:SetPoint("RIGHT", 0, 0)
        dungeonHeader:Show()

        lastDungeonHeader = dungeonHeader
    end

    local slotStartX = (dungenHeight - dividerSize);
    local availableWidth = self:GetWidth() - slotStartX;
    local slotWidth = math.min(maxCellSize, availableWidth / #matrixData.slotHeaders)

    local lastSlotHeader = nil
    for i, slotHeader in ipairs(matrixData.slotHeaders) do
        slotHeader:SetWidth(slotWidth)
        if lastSlotHeader then
            slotHeader:SetPoint("TOPLEFT", lastSlotHeader, "TOPRIGHT", 0, 0)
        else
            slotHeader:SetPoint("TOPLEFT", slotStartX, 0)
        end
        slotHeader:SetPoint("BOTTOM", 0, 0)
        slotHeader:Show()

        lastSlotHeader = slotHeader
    end

    for dungeonHeader, itemButtonsPerDungeon in pairs(matrixData.itemButtons) do
        for slotHeader, itemButtonsFrame in pairs(itemButtonsPerDungeon) do
            itemButtonsFrame:DoLayout()
        end
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

function MPLM_DungeonFrameMixin:ScanDungeons()
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

