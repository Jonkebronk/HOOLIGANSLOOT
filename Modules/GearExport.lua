-- Modules/GearExport.lua
-- Export player's equipped gear in Sixty Upgrades format

local ADDON_NAME, NS = ...
local HooligansLoot = NS.addon
local Utils = NS.Utils

local GearExport = HooligansLoot:NewModule("GearExport")

-- Equipment slots: WoW slot ID -> Sixty Upgrades slot name (uppercase with underscores)
local SLOT_INFO = {
    { wowSlot = 1,  name = "HEAD" },
    { wowSlot = 2,  name = "NECK" },
    { wowSlot = 3,  name = "SHOULDERS" },
    { wowSlot = 15, name = "BACK" },
    { wowSlot = 5,  name = "CHEST" },
    { wowSlot = 9,  name = "WRISTS" },
    { wowSlot = 10, name = "HANDS" },
    { wowSlot = 6,  name = "WAIST" },
    { wowSlot = 7,  name = "LEGS" },
    { wowSlot = 8,  name = "FEET" },
    { wowSlot = 11, name = "FINGER_1" },
    { wowSlot = 12, name = "FINGER_2" },
    { wowSlot = 13, name = "TRINKET_1" },
    { wowSlot = 14, name = "TRINKET_2" },
    { wowSlot = 16, name = "MAIN_HAND" },
    { wowSlot = 17, name = "OFF_HAND" },
    { wowSlot = 18, name = "RANGED" },
}

-- Race name mapping (localized -> Sixty Upgrades format)
local RACE_MAP = {
    ["Human"] = "HUMAN",
    ["Dwarf"] = "DWARF",
    ["Night Elf"] = "NIGHT_ELF",
    ["Gnome"] = "GNOME",
    ["Draenei"] = "DRAENEI",
    ["Orc"] = "ORC",
    ["Undead"] = "UNDEAD",
    ["Tauren"] = "TAUREN",
    ["Troll"] = "TROLL",
    ["Blood Elf"] = "BLOOD_ELF",
}

-- Tooltip scanner for extracting enchant names
local scanTooltip = CreateFrame("GameTooltip", "HooligansGearExportScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Export dialog frame
local exportFrame = nil

function GearExport:OnEnable()
    -- Nothing to do on enable
end

-- Parse item link to extract itemID, enchantID, and gem IDs
-- Classic/TBC item link format: item:ID:enchant:gem1:gem2:gem3:gem4:suffix:unique
function GearExport:ParseItemLink(itemLink)
    if not itemLink then return nil end

    local itemString = itemLink:match("item:([%-?%d:]+)")
    if not itemString then return nil end

    local parts = {strsplit(":", itemString)}

    return {
        itemID = tonumber(parts[1]) or 0,
        enchantID = tonumber(parts[2]) or 0,
        gem1 = tonumber(parts[3]) or 0,
        gem2 = tonumber(parts[4]) or 0,
        gem3 = tonumber(parts[5]) or 0,
        gem4 = tonumber(parts[6]) or 0,
    }
end

-- Get enchant name from item link by scanning tooltip
-- Enchants appear as green text in the tooltip
function GearExport:GetEnchantFromTooltip(itemLink)
    if not itemLink then return nil end

    scanTooltip:ClearLines()
    scanTooltip:SetHyperlink(itemLink)

    -- Scan tooltip lines for enchant (green text)
    for i = 2, scanTooltip:NumLines() do
        local line = _G["HooligansGearExportScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            local r, g, b = line:GetTextColor()

            -- Green text (enchants are green: r≈0, g≈1, b≈0)
            if text and g > 0.9 and r < 0.2 and b < 0.2 then
                -- Filter out socket bonuses and other green text
                if not text:match("^Socket Bonus:") and
                   not text:match("^Equip:") and
                   not text:match("^Use:") and
                   not text:match("^Requires") and
                   not text:match("^Classes:") and
                   not text:match("^Durability") and
                   not text:match("^<") then
                    return text  -- This is the enchant name
                end
            end
        end
    end

    return nil
end

-- Get enchant info - uses tooltip scanning for accurate names
function GearExport:GetEnchantInfo(enchantID, itemLink)
    if not enchantID or enchantID == 0 then return nil end

    -- Use tooltip scanning to get the actual enchant name
    local enchantName = self:GetEnchantFromTooltip(itemLink)

    if enchantName then
        return {
            name = enchantName,
            id = enchantID,
        }
    end

    -- Fallback if tooltip scanning fails
    return {
        name = "Enchant",
        id = enchantID,
    }
end

-- Get gem info from gem item ID
function GearExport:GetGemInfo(gemID)
    if not gemID or gemID == 0 then return nil end

    local name = GetItemInfo(gemID)

    return {
        id = gemID,
        name = name or "Gem",
    }
end

-- Get all equipped gear as items array with full info (Sixty Upgrades format)
function GearExport:GetEquippedGear()
    local items = {}

    for _, slotInfo in ipairs(SLOT_INFO) do
        local itemLink = GetInventoryItemLink("player", slotInfo.wowSlot)

        if itemLink then
            local parsed = self:ParseItemLink(itemLink)
            if parsed and parsed.itemID > 0 then
                local itemName = GetItemInfo(parsed.itemID) or Utils.GetItemName(itemLink) or "Unknown"

                local item = {
                    name = itemName,
                    id = parsed.itemID,
                    slot = slotInfo.name,
                    gems = {},
                }

                -- Add enchant if present (pass itemLink for tooltip scanning)
                local enchant = self:GetEnchantInfo(parsed.enchantID, itemLink)
                if enchant then
                    item.enchant = enchant
                end

                -- Add gems if present
                for _, gemID in ipairs({parsed.gem1, parsed.gem2, parsed.gem3, parsed.gem4}) do
                    local gem = self:GetGemInfo(gemID)
                    if gem then
                        table.insert(item.gems, gem)
                    end
                end

                -- Remove empty gems array for cleaner output
                if #item.gems == 0 then
                    item.gems = nil
                end

                table.insert(items, item)
            end
        end
    end

    return items
end

-- Export gear in Sixty Upgrades JSON format
function GearExport:ExportToJSON()
    local playerName = UnitName("player")
    local _, classFile = UnitClass("player")
    local level = UnitLevel("player")
    local race = UnitRace("player")
    local faction = UnitFactionGroup("player")

    local items = self:GetEquippedGear()

    local exportData = {
        character = {
            name = playerName,
            level = level,
            gameClass = classFile,  -- Already uppercase (e.g., "WARRIOR")
            race = RACE_MAP[race] or race:upper():gsub(" ", "_"),
            faction = faction:upper(),
        },
        items = items,
    }

    return Utils.ToJSON(exportData), #items
end

-- Create the export dialog frame
function GearExport:CreateExportFrame()
    if exportFrame then return exportFrame end

    local frame = CreateFrame("Frame", "HooligansLootGearExportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(450, 400)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 20,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
    frame:SetBackdropBorderColor(0.6, 0.5, 0.3, 1)

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -15)
    frame.title:SetText(HooligansLoot.colors.primary .. "HOOLIGANS|r Loot - Gear Export")

    -- Close button
    local closeX = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeX:SetPoint("TOPRIGHT", -2, -2)
    closeX:SetScript("OnClick", function() frame:Hide() end)

    -- Player info
    frame.playerInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.playerInfo:SetPoint("TOP", frame.title, "BOTTOM", 0, -5)
    frame.playerInfo:SetTextColor(0.7, 0.7, 0.7)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "HooligansLootGearExportScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -55)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 45)

    -- Edit box
    local editBox = CreateFrame("EditBox", "HooligansLootGearExportEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetAutoFocus(true)
    editBox:EnableMouse(true)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)

    scrollFrame:SetScrollChild(editBox)
    frame.editBox = editBox

    -- Instructions
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("BOTTOMLEFT", 15, 15)
    instructions:SetText("Press Ctrl+C to copy")
    instructions:SetTextColor(0.7, 0.7, 0.7)

    tinsert(UISpecialFrames, "HooligansLootGearExportFrame")

    exportFrame = frame
    return frame
end

-- Refresh the export data
function GearExport:RefreshExport()
    if not exportFrame or not exportFrame:IsShown() then return end

    local exportString, itemCount = self:ExportToJSON()

    if exportString then
        exportFrame.editBox:SetText(exportString)
        exportFrame.editBox:HighlightText()

        local playerName = UnitName("player")
        local _, className = UnitClass("player")
        exportFrame.playerInfo:SetText(playerName .. " (" .. (className or "?") .. ") - " .. itemCount .. " items")
    else
        exportFrame.editBox:SetText("Error: Unknown error")
    end
end

-- Show the gear export dialog
function GearExport:ShowDialog()
    local frame = self:CreateExportFrame()
    frame:Show()
    self:RefreshExport()
end

-- Hide the dialog
function GearExport:HideDialog()
    if exportFrame then
        exportFrame:Hide()
    end
end
