---@class MPLM_Private
local private = select(2, ...)

---@class RowInfo
---@field loot number[]

---@class MPLM_RowHeader : Frame
MPLM_RowHeaderMixin = {}

--- Subclasses should override this to initialize the header with the row info
---@param rowInfo RowInfo
function MPLM_RowHeaderMixin:Init(rowInfo)
    self.info = rowInfo
end

---@class MPLM_SlotHeader : Frame
---@field Label FontString
---@field EquippedItem1Button MPLM_ItemButton
---@field EquippedItem2Button MPLM_ItemButton
---@field SlotHighlight Texture
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

function MPLM_SlotHeaderMixin:SetHighlight(value)
    self.SlotHighlight:SetShown(value)
end

function MPLM_SlotHeaderMixin:Reset()
    self.SlotHighlight:Hide()
end

---@class MPLM_MatrixFrame : Frame
---@field rowTemplate? string
MPLM_MatrixFrameMixin = {}

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

function MPLM_MatrixFrameMixin:OnLoad()
    self.rowHeaderPool = CreateFramePool("Frame", self, self.rowTemplate or "MPLM_RowHeaderTemplate", FramePoolDefaultReset)
    self.slotHeaderPool = CreateFramePool("Frame", self, "MPLM_SlotHeaderTemplate", FramePoolDefaultReset)
    self.itemButtonPool = CreateFramePool("Button", nil, "MPLM_ItemButtonTemplate", FramePoolDefaultReset)
    self.itemButtonContainerPool = CreateObjectPool(ItemButtonContainerPoolCreate, ObjectPoolDefaultReset)

    ---@type table<number, EncounterJournalItemInfo>
    self.itemCache = {}

    ---@type RowInfo[]
    self.rowInfos = {}

    self.parent = self:GetParent() --[[@as MPLM_MainFrame]]
end

--- Subclasses should override this to gather the row info for the matrix
---@return RowInfo[]
function MPLM_MatrixFrameMixin:GatherRowInfo()
    return {}
end

function MPLM_MatrixFrameMixin:DoScan()
    self.rowInfos = self:GatherRowInfo()
    self:UpdateMatrix()
end

function MPLM_MatrixFrameMixin:UpdateMatrix()
    self.matrixFrames = self:BuildMatrix()
    self:UpdatSizeConstraints(self.matrixFrames)
    self:LayoutMatrix(self.matrixFrames)
    self:UpdateSearchGlow()
end

function MPLM_MatrixFrameMixin:OnSizeChanged()
    if self.matrixFrames then
        self:LayoutMatrix(self.matrixFrames)
    end
end

---@param itemLink string
---@return integer|true|false|nil matchResult 2 = strong match, 1 = weak match, true = all stats match, false = no match, nil = invalid item link
function MPLM_MatrixFrameMixin:MatchWithStatSearch(itemLink)
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

function MPLM_MatrixFrameMixin:UpdateSearchGlow()
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

---@param matrixFrames MatrixFrames
function MPLM_MatrixFrameMixin:UpdatSizeConstraints(matrixFrames)
    local minHeight = #matrixFrames.rowHeaders * 65
    local minWidth = #matrixFrames.slotHeaders * 65

    local maxHeight = minHeight * 1.5
    local maxWidth = #matrixFrames.slotHeaders * 110

    self.parent:UpdatSizeConstraints(minWidth, minHeight, maxWidth, maxHeight)
end

--- Returns a table of loot slots that are present in the current row infos
function MPLM_MatrixFrameMixin:GetLootSlotsPresent()
	---@type table<Enum.ItemSlotFilterType, boolean>
    local isLootSlotPresent = {};
	for i, rowInfo in ipairs(self.rowInfos) do
        for j, itemId in ipairs(rowInfo.loot) do
            local itemInfo = self.itemCache[itemId]
            if itemInfo then
                isLootSlotPresent[itemInfo.filterType] = true;
            end
        end
	end
	return isLootSlotPresent;
end

---@param itemInfo EncounterJournalItemInfo
function MPLM_MatrixFrameMixin:IsItemVisible(itemInfo)
    return itemInfo
        and itemInfo.filterType
        and itemInfo.link
        and private:IsSlotActive(itemInfo.filterType)
        and (not self.parent.hideOtherItems or self:MatchWithStatSearch(itemInfo.link))
        and true or false
end

---@param rowInfo RowInfo
function MPLM_MatrixFrameMixin:HasRowVisibleItems(rowInfo)
    for i, itemId in ipairs(rowInfo.loot) do
        if self:IsItemVisible(self.itemCache[itemId]) then
            return true
        end
    end
end

---@class MatrixFrames
---@field rowHeaders MPLM_RowHeader[]
---@field slotHeaders MPLM_SlotHeader[]
---@field itemButtons table<MPLM_RowHeader, table<MPLM_SlotHeader, ItemButtonContainer>>

function MPLM_MatrixFrameMixin:BuildMatrix()
    self.rowHeaderPool:ReleaseAll()
    self.slotHeaderPool:ReleaseAll()
    self.itemButtonPool:ReleaseAll()
    self.itemButtonContainerPool:ReleaseAll()

    ---@type MatrixFrames
    local matrixFrames = {
        rowHeaders = {},
        slotHeaders = {},
        itemButtons = {},
    }

    local rowToHeader = {}
    for i, rowInfo in ipairs(self.rowInfos) do
        if self:HasRowVisibleItems(rowInfo) then
            local rowHeader = self.rowHeaderPool:Acquire() --[[@as MPLM_RowHeader]]
            rowHeader:Init(rowInfo)

            rowToHeader[i] = rowHeader
            tinsert(matrixFrames.rowHeaders, rowHeader)
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

    for i, rowInfo in ipairs(self.rowInfos) do
        local rowHeader = rowToHeader[i]

        if rowHeader then
            local itemButtonsFrames = {}
            for j, itemId in ipairs(rowInfo.loot) do
                local itemInfo = self.itemCache[itemId]

                if self:IsItemVisible(itemInfo) then
                    local slotHeader = slotToHeader[itemInfo.filterType]
                    local currentButtonContainer = itemButtonsFrames[slotHeader]
                    if not currentButtonContainer then
                        currentButtonContainer = self.itemButtonContainerPool:Acquire() --[[@as ItemButtonContainer]]
                        currentButtonContainer:Init(2, 2, self, rowHeader, slotHeader)
                        itemButtonsFrames[slotHeader] = currentButtonContainer
                    end

                    local itemButton = self.itemButtonPool:Acquire() --[[@as MPLM_ItemButton]]
                    itemButton:Init(itemInfo)

                    currentButtonContainer:AddButton(itemButton)
                end
            end

            matrixFrames.itemButtons[rowHeader] = itemButtonsFrames
        end
    end

    return matrixFrames
end

---@param matrixData MatrixFrames
function MPLM_MatrixFrameMixin:LayoutMatrix(matrixData)
    local dividerSize = 5
    local rowStartY = 5 + 35
    local maxCellSize = 110

    local availableHeight = self:GetHeight() - rowStartY;
    local rowHeight = math.min(maxCellSize, availableHeight / #matrixData.rowHeaders)

    local lastRowHeader = nil
    for i, rowHeader in ipairs(matrixData.rowHeaders) do
        rowHeader:SetHeight(rowHeight)
        if lastRowHeader then
            rowHeader:SetPoint("TOPLEFT", lastRowHeader, "BOTTOMLEFT", 0, 0)
        else
            rowHeader:SetPoint("TOPLEFT", 0, -rowStartY)
        end

        rowHeader:SetPoint("RIGHT", 0, 0)
        rowHeader:Show()

        lastRowHeader = rowHeader
    end

    local slotStartX = (rowHeight - dividerSize);
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

    for rowHeader, itemButtonsPerRow in pairs(matrixData.itemButtons) do
        for slotHeader, itemButtonsFrame in pairs(itemButtonsPerRow) do
            itemButtonsFrame:DoLayout()
        end
    end
end
