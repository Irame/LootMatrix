---@class LM_Private
local private = select(2, ...)

local L = private.L

---@class LM_ButtonStateBehavior : ButtonStateBehaviorMixin, Button
---@field atlasKey string
LM_ButtonStateBehaviorMixin = CreateFromMixins(ButtonStateBehaviorMixin);

function LM_ButtonStateBehaviorMixin:OnButtonStateChanged()
	local atlas = self.atlasKey;
	if self:IsDownOver() or self:IsOver() then
		atlas = atlas.."-hover";
	elseif self:IsDown() then
		atlas = atlas.."-pressed";
	end

	self:GetNormalTexture():SetAtlas(atlas, TextureKitConstants.IgnoreAtlasSize);
end

---@class LM_SettingsButton : LM_ButtonStateBehavior
LM_SettingsButtonMixin = CreateFromMixins(LM_ButtonStateBehaviorMixin);

---@param mainFrame LM_MainFrame
function LM_SettingsButtonMixin:Init(mainFrame)
    self.mainFrame = mainFrame
end

function LM_SettingsButtonMixin:OnClick()
    MenuUtil.CreateContextMenu(self, function(button, rootDescription)
        rootDescription:CreateTitle(L["Settings"])
        rootDescription:CreateCheckbox(L["Use Short Dungeon Names"],
            function ()
                return private.db.global.useShortDungeonNames
            end,
            function ()
                private.db.global.useShortDungeonNames = not private.db.global.useShortDungeonNames
                self.mainFrame:UpdateMatrix()
            end)
    end)
end

---@class LM_MainFrame : PortraitFrameFlatTemplate, TabSystemOwnerTemplate
---@field Filter WowStyle1DropdownTemplate
---@field ResetFilterButton IconButtonTemplate
---@field ResizeButton PanelResizeButtonTemplate
---@field Stat1Search WowStyle1DropdownTemplate
---@field Stat2Search WowStyle1DropdownTemplate
---@field SlotSelect WowStyle1DropdownTemplate
---@field HideOtherItems ResizeCheckButtonTemplate
---@field SettingsButton LM_SettingsButton
---@field DungeonsFrame LM_DungeonFrame
---@field RaidFrame LM_RaidFrame
---@field TabSystem TabSystemTemplate
LM_MainFrameMixin = {}

function LM_MainFrameMixin:OnLoad()
    TabSystemOwnerMixin.OnLoad(self)

    self:SetPortraitToAsset([[Interface\EncounterJournal\UI-EJ-PortraitIcon]])
    self:SetTitle(L["Loot Matrix"])

    self.HideOtherItems:SetLabelText(L["Hide Others"])

    self:RegisterEvent("EJ_LOOT_DATA_RECIEVED")

    self.ResizeButton:Init(self, 1100, 670, 1100*1.5, 670*1.5);
end

function LM_MainFrameMixin:Init()
    -- this is required for the SpellBookItemAutoCastTemplate to be available
    PlayerSpellsFrame_LoadUI();

    self:SetupFilterDropdown()
    self:SetupStatSearchDropdown()
    self:SetupSlotsDropdown()
    self:SetupHideOtherItemsCheckbox()
    self:SetupTabs()
    self.SettingsButton:Init(self)
end

function LM_MainFrameMixin:GetCurrentFrame()
    return self.tabIdToFrame[self:GetTab()]
end

function LM_MainFrameMixin:DoScan()
    self:GetCurrentFrame():DoScan()
end

function LM_MainFrameMixin:UpdateMatrix()
    self:GetCurrentFrame():UpdateMatrix()
end

function LM_MainFrameMixin:UpdateSearchGlow()
    self:GetCurrentFrame():UpdateSearchGlow()
end

function LM_MainFrameMixin:OnShow()
    if EncounterJournal and EncounterJournal:IsShown() then
        EncounterJournal:Hide()
    end

    self:DoScan()

    if not self.EncounterJournalShowHooked then
        hooksecurefunc(EncounterJournal, "Show", function()
            self:Hide()
        end)
        self.EncounterJournalShowHooked = true
    end
end

function LM_MainFrameMixin:OnEvent(event, ...)
    if event == "EJ_LOOT_DATA_RECIEVED" then
        if self:IsShown() and not self.RescanTimer then
            self.RescanTimer = C_Timer.NewTimer(0.2, function()
                self:DoScan()
                self.RescanTimer = nil
            end)
        end
    end
end

function LM_MainFrameMixin:UpdatSizeConstraints(innerMinWidth, innerMinHeight, innerMaxWidth, innerMaxHeight)
    local absoulteMinWidth = 925

    local minHeight = innerMinHeight + 140
    local minWidth = math.max(absoulteMinWidth, innerMinWidth + 80)

    local maxHeight = innerMaxHeight + 140
    local maxWidth = math.max(absoulteMinWidth, innerMaxWidth + 80)

    self.ResizeButton.minHeight = minHeight
    self.ResizeButton.minWidth = minWidth
    self.ResizeButton.maxHeight = maxHeight
    self.ResizeButton.maxWidth = maxWidth

    if self:GetHeight() < minHeight then
        self:SetHeight(minHeight)
    end
    if self:GetWidth() < minWidth then
        self:SetWidth(minWidth)
    end
    if self:GetHeight() > maxHeight then
        self:SetHeight(maxHeight)
    end
    if self:GetWidth() > maxWidth then
        self:SetWidth(maxWidth)
    end
end

function LM_MainFrameMixin:SetupFilterDropdown()

    local function GetClassFilter()
        local filterClassID, filterSpecID = EJ_GetLootFilter();
        return filterClassID;
    end

    local function GetSpecFilter()
        local filterClassID, filterSpecID = EJ_GetLootFilter();
        return filterSpecID;
    end

    local function SetClassAndSpecFilter(classID, specID)
        EJ_SetLootFilter(classID, specID);
        if EncounterJournal_OnFilterChanged then
            EncounterJournal_OnFilterChanged(EncounterJournal);
        end
        self.SlotSelect:GenerateMenu()
        self:DoScan()
    end

    local function ResetFilter()
        local _, playerClassId = UnitClassBase("player")
        local playerSpecId = GetSpecializationInfo(GetSpecialization())
        SetClassAndSpecFilter(playerClassId, playerSpecId)
        self.Filter:GenerateMenu()
    end

    ClassMenu.InitClassSpecDropdown(self.Filter, GetClassFilter, GetSpecFilter, SetClassAndSpecFilter);
    self.ResetFilterButton:SetOnClickHandler(ResetFilter);
    self.ResetFilterButton:SetTooltipInfo(nil, L["Reset filter to your current class/spec."]);
end

function LM_MainFrameMixin:SetupStatSearchDropdown()
    local function UpdateOnSelection()
        if self.hideOtherItems then
            self:UpdateMatrix()
        else
            self:UpdateSearchGlow()
        end
    end

    do
        local function IsSelected(value)
            return private.db.char.stat1SearchValue == value
        end

        local function SetSelected(value)
            private.db.char.stat1SearchValue = value
            UpdateOnSelection()
        end

        self.Stat1Search:SetupMenu(function(dropdown, rootDescription)
            rootDescription:CreateRadio(L["All Stats"], IsSelected, SetSelected, nil);

            for key, shortName in pairs(private.statsShortened) do
                rootDescription:CreateRadio(_G[key], IsSelected, SetSelected, key);
            end
        end);
    end

    do
        local function IsSelected(value)
            return private.db.char.stat2SearchValue == value
        end

        local function SetSelected(value)
            private.db.char.stat2SearchValue = value
            UpdateOnSelection()
        end

        self.Stat2Search:SetupMenu(function(dropdown, rootDescription)
            rootDescription:CreateRadio(L["All Stats"], IsSelected, SetSelected, nil);

            for key, shortName in pairs(private.statsShortened) do
                rootDescription:CreateRadio(_G[key], IsSelected, SetSelected, key);
            end
        end);
    end
end

function LM_MainFrameMixin:SetupSlotsDropdown()
    local function IsSelected(slot)
        return private:IsSlotActive(slot)
    end

    local function SetSelected(slot)
        private:SetSlotActive(slot, not private:IsSlotActive(slot))
        self:UpdateMatrix()
    end

    local function SetAllSelect(value)
        private:SetAllSlotsActive(value)
        self:UpdateMatrix()
    end

    self.SlotSelect:SetupMenu(function(dropdown, rootDescription)
        rootDescription:CreateButton(L["Select All"], SetAllSelect, true)
        rootDescription:CreateButton(L["Unselect All"], SetAllSelect, false)

        rootDescription:CreateDivider()

        for i, filter in ipairs(private.slotFilterOrdered) do
            rootDescription:CreateCheckbox(private.slotFilterToSlotName[filter], IsSelected, SetSelected, filter);
        end
    end);
end

function LM_MainFrameMixin:SetupHideOtherItemsCheckbox()
    local function HideOtherItemsToggled()
        self.hideOtherItems = not self.hideOtherItems
        self:UpdateMatrix()
    end

	self.HideOtherItems:SetControlChecked(self.hideOtherItems);
	self.HideOtherItems:SetCallback(HideOtherItemsToggled);
end

function LM_MainFrameMixin:SetupTabs()
    self:SetTabSystem(self.TabSystem)
	self.dungeonsTabId = self:AddNamedTab(DUNGEONS, self.DungeonsFrame)
	self.raidTabId = self:AddNamedTab(RAID, self.RaidFrame)

    self.tabIdToFrame = {
        [self.dungeonsTabId] = self.DungeonsFrame,
        [self.raidTabId] = self.RaidFrame,
    }

    self:SetTab(self.dungeonsTabId)
end

function LM_MainFrameMixin:SetTab(tabId)
    TabSystemOwnerMixin.SetTab(self, tabId)
    self:DoScan()
end
