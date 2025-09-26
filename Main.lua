---@type string
local addonName = ...

---@class LM_Private
local private = select(2, ...)

---@class LootMatrix : AceAddon, AceConsole-3.0
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")
private.addon = addon

---@type LM_MainFrame
LM_MainFrame = LM_MainFrame

function addon:OnInitialize()
    tinsert(UISpecialFrames, LM_MainFrame:GetName())

    self:RegisterChatCommand("mplm", "ChatCommandHandler");
    self:RegisterChatCommand("lm", "ChatCommandHandler");
    private:IntiializeDatabase()
end

function addon:OnEnable()
    LM_MainFrame:Init()
end

function addon:ChatCommandHandler(args)
    private:ToggleMatrixFrame()
end

function LM_OnAddonCompartmentClick()
    private:ToggleMatrixFrame()
end

function private:ToggleMatrixFrame()
    LM_MainFrame:SetShown(LM_MainFrame:IsShown() == false)
end