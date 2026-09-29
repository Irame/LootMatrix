---@type string
local addonName = ...

---@class LM_Private
local private = select(2, ...)

---@alias SetID number
---@alias TokenID number
---@alias ItemID number
---@alias ClassID number
---@alias SpecID number

---@type table<string, ClassID>
local classID = {
    WARRIOR = 1,
    PALADIN = 2,
    HUNTER = 3,
    ROGUE = 4,
    PRIEST = 5,
    DEATHKNIGHT = 6,
    SHAMAN = 7,
    MAGE = 8,
    WARLOCK = 9,
    MONK = 10,
    DRUID = 11,
    DEMONHUNTER = 12,
    EVOKER = 13,
}

---@type table<TokenID, table<TokenID, Enum.InventoryType[]>>
local tokenSets = {
	-- #region MID: Season 1
	[249358] = { [249358] = { Enum.InventoryType.IndexHeadType }, [249366] = { Enum.InventoryType.IndexShoulderType }, [249350] = { Enum.InventoryType.IndexChestType }, [249354] = { Enum.InventoryType.IndexHandType }, [249362] = { Enum.InventoryType.IndexLegsType }, }, -- Plate
	[249357] = { [249357] = { Enum.InventoryType.IndexHeadType }, [249365] = { Enum.InventoryType.IndexShoulderType }, [249349] = { Enum.InventoryType.IndexChestType }, [249353] = { Enum.InventoryType.IndexHandType }, [249361] = { Enum.InventoryType.IndexLegsType }, }, -- Mail
	[249356] = { [249356] = { Enum.InventoryType.IndexHeadType }, [249364] = { Enum.InventoryType.IndexShoulderType }, [249348] = { Enum.InventoryType.IndexChestType }, [249352] = { Enum.InventoryType.IndexHandType }, [249360] = { Enum.InventoryType.IndexLegsType }, }, -- Leather
	[249355] = { [249355] = { Enum.InventoryType.IndexHeadType }, [249363] = { Enum.InventoryType.IndexShoulderType }, [249347] = { Enum.InventoryType.IndexChestType }, [249351] = { Enum.InventoryType.IndexHandType }, [249359] = { Enum.InventoryType.IndexLegsType }, }, -- Cloth
	[249367] = { [249367] = { Enum.InventoryType.IndexHeadType, Enum.InventoryType.IndexShoulderType, Enum.InventoryType.IndexChestType, Enum.InventoryType.IndexHandType, Enum.InventoryType.IndexLegsType }, }, -- Omni
    -- #endregion
	-- #region MID: Season 2
	[270917] = { [270917] = { Enum.InventoryType.IndexHeadType }, [270925] = { Enum.InventoryType.IndexShoulderType }, [270929] = { Enum.InventoryType.IndexChestType }, [270913] = { Enum.InventoryType.IndexHandType }, [270921] = { Enum.InventoryType.IndexLegsType }, }, -- Plate
	[270916] = { [270916] = { Enum.InventoryType.IndexHeadType }, [270924] = { Enum.InventoryType.IndexShoulderType }, [270928] = { Enum.InventoryType.IndexChestType }, [270912] = { Enum.InventoryType.IndexHandType }, [270920] = { Enum.InventoryType.IndexLegsType }, }, -- Mail
	[270915] = { [270915] = { Enum.InventoryType.IndexHeadType }, [270923] = { Enum.InventoryType.IndexShoulderType }, [270927] = { Enum.InventoryType.IndexChestType }, [270911] = { Enum.InventoryType.IndexHandType }, [270919] = { Enum.InventoryType.IndexLegsType }, }, -- Leather
	[270914] = { [270914] = { Enum.InventoryType.IndexHeadType }, [270922] = { Enum.InventoryType.IndexShoulderType }, [270926] = { Enum.InventoryType.IndexChestType }, [270910] = { Enum.InventoryType.IndexHandType }, [270918] = { Enum.InventoryType.IndexLegsType }, }, -- Cloth
	[270909] = { [270909] = { Enum.InventoryType.IndexHeadType, Enum.InventoryType.IndexShoulderType, Enum.InventoryType.IndexChestType, Enum.InventoryType.IndexHandType, Enum.InventoryType.IndexLegsType }, }, -- Omni
    -- #endregion
}

---@type table<SetID, { tokenSetID: TokenID|TokenID[], classID?: ClassID, specID?: SpecID|SpecID[] }>
local setIDs = {
	-- #region MID: Season 1
	[1990] = { tokenSetID = { 249358, 249367}, classID = classID.WARRIOR },
	[1985] = { tokenSetID = { 249358, 249367}, classID = classID.PALADIN },
	[1982] = { tokenSetID = { 249357, 249367}, classID = classID.HUNTER },
	[1987] = { tokenSetID = { 249356, 249367}, classID = classID.ROGUE },
	[1986] = { tokenSetID = { 249355, 249367}, classID = classID.PRIEST },
	[1978] = { tokenSetID = { 249358, 249367}, classID = classID.DEATHKNIGHT },
	[1988] = { tokenSetID = { 249357, 249367}, classID = classID.SHAMAN },
	[1983] = { tokenSetID = { 249355, 249367}, classID = classID.MAGE },
	[1989] = { tokenSetID = { 249355, 249367}, classID = classID.WARLOCK },
	[1984] = { tokenSetID = { 249356, 249367}, classID = classID.MONK },
	[1980] = { tokenSetID = { 249356, 249367}, classID = classID.DRUID },
	[1979] = { tokenSetID = { 249356, 249367}, classID = classID.DEMONHUNTER },
	[1981] = { tokenSetID = { 249357, 249367}, classID = classID.EVOKER },
	-- #endregion
	-- #region MID: Season 2
	[2067] = { tokenSetID = { 270917, 270909 }, classID = classID.WARRIOR },
	[2062] = { tokenSetID = { 270917, 270909 }, classID = classID.PALADIN },
	[2059] = { tokenSetID = { 270916, 270909 }, classID = classID.HUNTER },
	[2064] = { tokenSetID = { 270915, 270909 }, classID = classID.ROGUE },
	[2063] = { tokenSetID = { 270914, 270909 }, classID = classID.PRIEST },
	[2055] = { tokenSetID = { 270917, 270909 }, classID = classID.DEATHKNIGHT },
	[2065] = { tokenSetID = { 270916, 270909 }, classID = classID.SHAMAN },
	[2060] = { tokenSetID = { 270914, 270909 }, classID = classID.MAGE },
	[2066] = { tokenSetID = { 270914, 270909 }, classID = classID.WARLOCK },
	[2061] = { tokenSetID = { 270915, 270909 }, classID = classID.MONK },
	[2057] = { tokenSetID = { 270915, 270909 }, classID = classID.DRUID },
	[2056] = { tokenSetID = { 270915, 270909 }, classID = classID.DEMONHUNTER },
	[2058] = { tokenSetID = { 270916, 270909 }, classID = classID.EVOKER },
	-- #endregion
}

---@type table<TokenID, Enum.InventoryType>
local slotFixes = {
	-- #region MID: Season 1
    [250054] = Enum.InventoryType.IndexChestType,  -- Priest
    [249973] = Enum.InventoryType.IndexChestType,  -- Death Knight
    [249982] = Enum.InventoryType.IndexChestType,  -- Shaman
    [250063] = Enum.InventoryType.IndexChestType,  -- Mage
    [250045] = Enum.InventoryType.IndexChestType,  -- Warlock
    [250027] = Enum.InventoryType.IndexChestType,  -- Druid
	-- #endregion
	-- #region MID: Season 2
    [271558] = Enum.InventoryType.IndexChestType,  -- Priest
    [271486] = Enum.InventoryType.IndexChestType,  -- Shaman
    [271567] = Enum.InventoryType.IndexChestType,  -- Mage
    [271549] = Enum.InventoryType.IndexChestType,  -- Warlock
    [271531] = Enum.InventoryType.IndexChestType,  -- Druid
	-- #endregion
}

---@type table<Enum.InventoryType, Enum.ItemSlotFilterType>
local invTypeToSlotFilter = {
    [Enum.InventoryType.IndexHeadType]             = Enum.ItemSlotFilterType.Head,
    [Enum.InventoryType.IndexNeckType]             = Enum.ItemSlotFilterType.Neck,
    [Enum.InventoryType.IndexShoulderType]         = Enum.ItemSlotFilterType.Shoulder,
    [Enum.InventoryType.IndexCloakType]            = Enum.ItemSlotFilterType.Cloak,
    [Enum.InventoryType.IndexChestType]            = Enum.ItemSlotFilterType.Chest,
    [Enum.InventoryType.IndexRobeType]             = Enum.ItemSlotFilterType.Chest,
    [Enum.InventoryType.IndexWristType]            = Enum.ItemSlotFilterType.Wrist,
    [Enum.InventoryType.IndexHandType]             = Enum.ItemSlotFilterType.Hand,
    [Enum.InventoryType.IndexWaistType]            = Enum.ItemSlotFilterType.Waist,
    [Enum.InventoryType.IndexLegsType]             = Enum.ItemSlotFilterType.Legs,
    [Enum.InventoryType.IndexFeetType]             = Enum.ItemSlotFilterType.Feet,
    [Enum.InventoryType.IndexFingerType]           = Enum.ItemSlotFilterType.Finger,
    [Enum.InventoryType.IndexTrinketType]          = Enum.ItemSlotFilterType.Trinket,
    [Enum.InventoryType.IndexWeaponType]           = Enum.ItemSlotFilterType.MainHand,
    [Enum.InventoryType.IndexWeaponmainhandType]   = Enum.ItemSlotFilterType.MainHand,
    [Enum.InventoryType.Index2HweaponType]         = Enum.ItemSlotFilterType.MainHand,
    [Enum.InventoryType.IndexRangedType]           = Enum.ItemSlotFilterType.MainHand,
    [Enum.InventoryType.IndexRangedrightType]      = Enum.ItemSlotFilterType.MainHand,
    [Enum.InventoryType.IndexThrownType]           = Enum.ItemSlotFilterType.MainHand,
    [Enum.InventoryType.IndexShieldType]           = Enum.ItemSlotFilterType.OffHand,
    [Enum.InventoryType.IndexHoldableType]         = Enum.ItemSlotFilterType.OffHand,
    [Enum.InventoryType.IndexWeaponoffhandType]    = Enum.ItemSlotFilterType.OffHand,
}

local prefix = {
	class = "class-",
	spec  = "spec-",
}

---@class LM_SetItemInfo
---@field itemID number
---@field filterType Enum.ItemSlotFilterType

---@type table<TokenID, table<string, LM_SetItemInfo[]>>
local tokenItems = nil

local function fillTokenItems()
    tokenItems = {}

    ---@param setID SetID
    ---@return table<Enum.InventoryType, ItemID>
    local function GetItemSetInfo(setID)
        local info = {};
        for _, item in ipairs(C_LootJournal.GetItemSetItems(setID)) do
            -- Enum.InventoryType is 0 based but GetItemSetItems returns it 1 based
            -- see https://wowpedia.fandom.com/wiki/Enum.InventoryType
            local invType = item.invType-1

            -- Some items have the wrong invType, so we fix them here
            if slotFixes[item.itemID] then
                invType = slotFixes[item.itemID]
            end

            info[invType] = item.itemID;
        end
        return info;
    end

    ---@type table<SetID, table<Enum.InventoryType, ItemID>>
    local setItems = {}

    ---@param setID SetID
    ---@param tokenSetIDs TokenID|TokenID[]
    ---@param targetKey string
    local function SetTokenItems(setID, tokenSetIDs, targetKey)
        setItems[setID] = setItems[setID] or GetItemSetInfo(setID)

        tokenSetIDs = type(tokenSetIDs) == "table" and tokenSetIDs or { tokenSetIDs }
        for _, tokenSetID in pairs(tokenSetIDs) do
            for tokenID, invTypes in pairs(tokenSets[tokenSetID] or {}) do
                for _, invType in pairs(invTypes) do
                    local setItemId = setItems[setID][invType]
                    if setItemId then
                        tokenItems[tokenID] = tokenItems[tokenID] or {}
                        tokenItems[tokenID][targetKey] = tokenItems[tokenID][targetKey] or {}
                        tinsert(tokenItems[tokenID][targetKey], {
                            itemID = setItemId,
                            filterType = invTypeToSlotFilter[invType],
                        })
                    end
                end
            end
        end
    end

    for setID, data in pairs(setIDs) do
        if data.specID then
            local specIDs = data.specID
            specIDs = type(specIDs) == "table" and specIDs or { specIDs }
            for _, specID in pairs(specIDs) do
                SetTokenItems(setID, data.tokenSetID, prefix.spec..specID)
            end
        else
            SetTokenItems(setID, data.tokenSetID, prefix.class..data.classID)
        end
    end
end

---@param tokenId TokenID
---@param classID ClassID
---@param specID? SpecID
---@return LM_SetItemInfo[]|nil
function private:GetItemsForToken(tokenId, classID, specID)
    if not tokenItems then
        fillTokenItems()
    end

    local tokenData = tokenItems[tokenId]
    if not tokenData then
        return nil
    end

    if specID then
        local specKey = prefix.spec..specID
        if tokenData[specKey] then
            return tokenData[specKey]
        end
    end

    return tokenData[prefix.class..classID]
end


