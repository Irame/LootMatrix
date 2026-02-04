---@class LM_Private
local private = select(2, ...)

---@class LM_ItemButton : Button
---@field itemLink string
---@field Icon Texture
---@field Border Texture
---@field Stat1 FontString
---@field Stat2 FontString
---@field ItemLevel FontString
---@field AutoCastOverlay SpellBookItemAutoCastTemplate
---@field SpellActivationAlert? ActionButtonSpellAlertTemplate
LM_ItemButtonMixin = {}

---@param itemInfoOrLink? EncounterJournalItemInfo | string
function LM_ItemButtonMixin:Init(itemInfoOrLink)
    local function FinishInit()
        self:UpdateStats()
        self:UpdateBorder()
        self:Show()
    end

    local argType = type(itemInfoOrLink)
    if argType == "table" then
        self.itemLink = itemInfoOrLink.link
        self.Icon:SetTexture(itemInfoOrLink.icon)
        self.ItemLevel:Hide()

        FinishInit()
    elseif argType == "string" then
        local item = Item:CreateFromItemLink(itemInfoOrLink)
        item:ContinueOnItemLoad(function ()
            self.itemLink = item:GetItemLink()
            self.Icon:SetTexture(item:GetItemIcon())
            self.ItemLevel:SetText(tostring(item:GetCurrentItemLevel()))
            self.ItemLevel:SetTextColor(item:GetItemQualityColor().color:GetRGB())
            self.ItemLevel:Show()

            FinishInit()
        end)
    else
        self.itemLink = nil
        self:Hide()
        return
    end
end

function LM_ItemButtonMixin:Reset()
    self.itemLink = nil
    self:HideStrongHighlight()
    self:HideWeakHighlight()
end

function LM_ItemButtonMixin:ShowStrongHighlight()
    self:HideWeakHighlight()

    ActionButtonSpellAlertManager:ShowAlert(self)

    local width, height = self:GetSize()
    self.SpellActivationAlert.ProcStartFlipbook:SetSize(width*3.5, height*3.5)
end

function LM_ItemButtonMixin:HideStrongHighlight()
    ActionButtonSpellAlertManager:HideAlert(self)
end

function LM_ItemButtonMixin:ShowWeakHighlight()
    self:HideStrongHighlight()
    self.AutoCastOverlay:SetShown(true);
    self.AutoCastOverlay:ShowAutoCastEnabled(true);
end

function LM_ItemButtonMixin:HideWeakHighlight()
    self.AutoCastOverlay:ShowAutoCastEnabled(false);
    self.AutoCastOverlay:SetShown(false);
end

function LM_ItemButtonMixin:UpdateStats()
    if self.itemLink then
        local statInfo = private:GetSortedStatsInfo(self.itemLink)

        if statInfo[1] then
            self.Stat1:SetText(statInfo[1].statName)
        else
            self.Stat1:SetText("")
        end

        if statInfo[2] then
            self.Stat2:SetText(statInfo[2].statName)
        else
            self.Stat2:SetText("")
        end
    else
        self.Stat1:SetText("")
        self.Stat2:SetText("")
    end
end

function LM_ItemButtonMixin:UpdateBorder()
    local _, _, itemQuality = C_Item.GetItemInfo(self.itemLink);
    itemQuality = itemQuality or Enum.ItemQuality.Epic;
    if C_ItemSocketInfo.IsArtifactRelicItem(self.itemLink) then
        self.Border:SetTexture([[Interface\Artifacts\RelicIconFrame]]);
    else
        self.Border:SetTexture([[Interface\Common\WhiteIconFrame]]);
    end
    local color = BAG_ITEM_QUALITY_COLORS[itemQuality];
    self.Border:SetVertexColor(color.r, color.g, color.b);
end

function LM_ItemButtonMixin:GetPreviewClassAndSpec()
    local classID, specID = EJ_GetLootFilter();
    if specID == 0 then
        local spec = GetSpecialization();
        if spec and classID == select(3, UnitClass("player")) then
            specID = GetSpecializationInfo(spec, nil, nil, nil, UnitSex("player"));
        else
            specID = -1;
        end
    end
    return classID, specID;
end

function LM_ItemButtonMixin:OnUpdate()
    if GameTooltip:IsOwned(self) then
        if IsModifiedClick("DRESSUP") then
            ShowInspectCursor();
        else
            ResetCursor();
        end
    end
end

function LM_ItemButtonMixin:ShowItemTooltip()
    if not self.itemLink then return end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    -- itemLink may not be available until after a GET_ITEM_INFO_RECEIVED event
    if self.itemLink then
        local classID, specID = self:GetPreviewClassAndSpec();
        GameTooltip:SetHyperlink(self.itemLink, classID, specID);
        self.tooltipHasLink = true
    end
    GameTooltip_ShowCompareItem();
end

function LM_ItemButtonMixin:OnEnter()
    self:ShowItemTooltip()
    self:SetScript("OnUpdate", self.OnUpdate);
end

function LM_ItemButtonMixin:OnLeave()
    GameTooltip:Hide();
    self:SetScript("OnUpdate", nil);
    ResetCursor();
end

function LM_ItemButtonMixin:OnClick()
    HandleModifiedItemClick(self.itemLink);
end

function LM_ItemButtonMixin:OnSizeChanged(width, height)
    self.Stat2:SetPoint("BOTTOM", 0, height/8-1)

    if self.SpellActivationAlert then
        self.SpellActivationAlert:SetSize(width * 1.4, height * 1.4)
        self.SpellActivationAlert.ProcStartFlipbook:SetSize(width*3.5, height*3.5)
    end
end
