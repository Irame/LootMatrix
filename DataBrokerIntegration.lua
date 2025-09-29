---@type string
local addonName = ...

---@class LM_Private
local private = select(2, ...)

local ldb = LibStub("LibDataBroker-1.1", true)

if not ldb then return end

ldb:NewDataObject(addonName, {
    type = "launcher",
    icon = "Interface\\Addons\\" .. addonName .. "\\Images\\Icon",
    OnClick = function(frame, button)
        private:ToggleMatrixFrame()
    end,
})
