-- Naxxramas fork addition.
-- Added by CosmicCuddle on 2026-10-02.
-- Requires the BotRaidConsumables.cpp system from CosmicCuddle/Mod-Naxxramas-Core.

if not MultiBot then return end

local ConsumablesUI = MultiBot.ConsumablesUI or {}
MultiBot.ConsumablesUI = ConsumablesUI

local MIN_LEVEL = 1
local MAX_LEVEL = 54
local MENU_FRAME_NAME = "ConsumablesMenu"
local DEFAULT_LEVEL = "54"

local function makeActionTooltip(title, description, actionText, commandText)
    local tip = title
        .. "\n|cffffffff" .. description .. "|r"
        .. "\n\n|cffff0000" .. actionText .. "|r"
        .. "\n|cff999999(Executed by: System)|r"

    if commandText and commandText ~= "" then
        tip = tip .. "\n\n|cff999999Command: " .. commandText .. "|r"
    end

    return tip
end

local DUNGEON_PROFILES = {
    {
        name = "Maraudon",
        command = "mara",
        icon = "ability_hunter_pet_devilsaur",
        tip = makeActionTooltip(
            "Maraudon",
            "Prepares eligible bots for Maraudon with level-appropriate role consumables and Nature Protection when usable.",
            "Left-click to prepare your bots for Maraudon",
            ".bot consumables mara"
        ),
    },
    {
        name = "SunkenTemple",
        command = "sunken",
        icon = "spell_nature_wispsplode",
        tip = makeActionTooltip(
            "Sunken Temple",
            "Prepares eligible bots for Sunken Temple with level-appropriate role consumables and Nature Protection when usable.",
            "Left-click to prepare your bots for Sunken Temple",
            ".bot consumables sunken"
        ),
    },
    {
        name = "BlackrockDepths",
        command = "brd",
        icon = "inv_misc_key_04",
        tip = makeActionTooltip(
            "Blackrock Depths",
            "Prepares eligible bots for Blackrock Depths and adds Fire Protection when usable.",
            "Left-click to prepare your bots for Blackrock Depths",
            ".bot consumables brd"
        ),
    },
    {
        name = "Scholomance",
        command = "scholo",
        icon = "spell_shadow_deathcoil",
        tip = makeActionTooltip(
            "Scholomance",
            "Prepares eligible bots for Scholomance and adds Shadow Protection when usable.",
            "Left-click to prepare your bots for Scholomance",
            ".bot consumables scholo"
        ),
    },
    {
        name = "StratholmeUndead",
        command = "stratud",
        icon = "spell_holy_senseundead",
        tip = makeActionTooltip(
            "Stratholme - Undead Side",
            "Use this while physically on the Undead/Service Entrance side. Eligible bots receive the appropriate role consumables and Shadow Protection when usable.",
            "Left-click to prepare your bots for Stratholme Undead",
            ".bot consumables stratud"
        ),
    },
    {
        name = "DireMaul",
        command = "dm",
        icon = "inv_misc_book_07",
        tip = makeActionTooltip(
            "Dire Maul",
            "The server automatically detects East, West, or North. East uses Nature Protection, West uses Shadow Protection, and North adds enhanced dungeon extras.",
            "Left-click to prepare your bots for your current Dire Maul wing",
            ".bot consumables dm"
        ),
    },
    {
        name = "LowerBlackrockSpire",
        command = "lbrs",
        icon = "ability_hunter_pet_wolf",
        tip = makeActionTooltip(
            "Lower Blackrock Spire",
            "Prepares eligible bots while you are physically in the Lower Blackrock Spire section of Blackrock Spire.",
            "Left-click to prepare your bots for Lower Blackrock Spire",
            ".bot consumables lbrs"
        ),
    },
    {
        name = "UpperBlackrockSpire",
        command = "ubrs",
        icon = "spell_fire_fire",
        tip = makeActionTooltip(
            "Upper Blackrock Spire",
            "Prepares eligible bots while you are physically in Upper Blackrock Spire. Adds Fire Protection and enhanced dungeon extras when usable.",
            "Left-click to prepare your bots for Upper Blackrock Spire",
            ".bot consumables ubrs"
        ),
    },
}

local function trim(value)
    if type(value) ~= "string" then
        return ""
    end

    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function showMessage(message, isError)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        if isError then
            UIErrorsFrame:AddMessage(message, 1, 0.25, 0.25, 1)
        else
            UIErrorsFrame:AddMessage(message, 0.25, 1, 0.25, 1)
        end
    end
end

function ConsumablesUI:SendConsumablesCommand(argument)
    argument = trim(argument)
    if argument == "" then
        return false
    end

    SendChatMessage(".bot consumables " .. argument, "SAY")
    return true
end

function ConsumablesUI:RunProfile(profile)
    if not profile or not profile.command then
        return false
    end

    if not self:SendConsumablesCommand(profile.command) then
        return false
    end

    if self.menu then
        self.menu:Hide()
    end

    showMessage("Bot Consumables: " .. profile.tip:match("^[^\n]+") .. " requested.", false)
    return true
end

function ConsumablesUI:RunCustomLevel(value)
    value = trim(value)

    if value == "" or string.find(value, "[^0-9]") then
        showMessage("Consumable level must be a whole number from 1 to 54.", true)
        return false
    end

    local level = tonumber(value)
    if not level or level < MIN_LEVEL or level > MAX_LEVEL then
        showMessage("Consumable level must be between 1 and 54.", true)
        return false
    end

    self.lastLevel = tostring(level)
    self:SendConsumablesCommand(self.lastLevel)
    showMessage("Bot Consumables: requested level " .. self.lastLevel .. ".", false)
    return true
end

function ConsumablesUI:EnsureDialogs()
    if self.dialogsReady or not StaticPopupDialogs then
        return
    end

    StaticPopupDialogs["MULTIBOT_CONSUMABLES_LEVEL"] = {
        text = "Custom Consumable Level\n\nEnter a level from 1 to 54.\n\nThis option only works inside a non-raid dungeon. The server will never prepare a bot above its real level or above the current dungeon's level cap.",
        button1 = "Apply",
        button2 = CANCEL or "Cancel",
        hasEditBox = true,
        maxLetters = 2,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnShow = function(popup)
            local editBox = popup and popup.editBox
            if not editBox then
                return
            end

            if editBox.SetNumeric then
                editBox:SetNumeric(true)
            end
            editBox:SetText(ConsumablesUI.lastLevel or DEFAULT_LEVEL)
            editBox:SetFocus()
            editBox:HighlightText()
        end,
        OnAccept = function(popup)
            local editBox = popup and popup.editBox
            local value = editBox and editBox:GetText() or ""
            ConsumablesUI:RunCustomLevel(value)
        end,
        EditBoxOnEnterPressed = function(editBox)
            if not editBox then
                return
            end
            local value = editBox:GetText() or ""
            if ConsumablesUI:RunCustomLevel(value) then
                local parent = editBox:GetParent()
                if parent then
                    parent:Hide()
                end
            end
        end,
    }

    StaticPopupDialogs["MULTIBOT_CONSUMABLES_HELP"] = {
        text = "How Bot Consumables Work\n\nNamed dungeon buttons use a dedicated server profile for the dungeon or wing you are physically inside.\n\nBots are prepared by class/spec role with suitable elixirs, food, scrolls, healing potions, mana potions where appropriate, and any profile-specific protection or extras.\n\nThe custom Level option accepts 1-54 and is for non-raid dungeons. The effective level is safely capped by the requested level, each bot's real level, and the dungeon level cap.\n\nThe server tracks the consumable auras it applied and can warn when tracked buffs need refreshing. Leaving the allowed instance clears that profile.\n\nRight-click the main Consumables button to open or close the dungeon profile bar.",
        button1 = OKAY or "Okay",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    self.dialogsReady = true
end

function ConsumablesUI:ShowLevelPrompt()
    self:EnsureDialogs()
    if StaticPopup_Show then
        StaticPopup_Show("MULTIBOT_CONSUMABLES_LEVEL")
    end
end

function ConsumablesUI:ShowHelp()
    self:EnsureDialogs()
    if StaticPopup_Show then
        StaticPopup_Show("MULTIBOT_CONSUMABLES_HELP")
    end
end

function ConsumablesUI:ToggleMenu()
    if not self.menu then
        return
    end

    if self.menu:IsShown() then
        self.menu:Hide()
    else
        self.menu:Show()
    end
end

function MultiBot.InitializeConsumablesUI(tRight)
    if ConsumablesUI.initialized then
        return ConsumablesUI
    end

    if not tRight or not tRight.addButton or not tRight.addFrame then
        return nil
    end

    ConsumablesUI:EnsureDialogs()

    local mainButton = tRight.addButton(
        "Consumables",
        102,
        0,
        "INV_Alchemy_Elixir_05",
        "Bot Consumables"
            .. "\n|cffffffffPrepare grouped or controlled Playerbots with dungeon-appropriate consumables from the Naxxramas Core consumable system.|r"
            .. "\n\n|cffff0000Left-click to set a custom consumable level (1-54)|r"
            .. "\n|cff999999(Executed by: System)|r"
            .. "\n\n|cffff0000Right-click to show or hide the dungeon profile bar|r"
            .. "\n|cff999999(Executed by: System)|r"
    )

    local menuHeight = (#DUNGEON_PROFILES + 1) * 34
    local menu = tRight.addFrame(MENU_FRAME_NAME, 102, 34, 32, 32, menuHeight)
    menu._mbDropdownManaged = true
    menu:Hide()

    mainButton.doLeft = function()
        ConsumablesUI:ShowLevelPrompt()
    end

    mainButton.doRight = function()
        ConsumablesUI:ToggleMenu()
    end

    if MultiBot.BindShiftRightSwapButtons then
        MultiBot.BindShiftRightSwapButtons(tRight, "RightRoot", {
            { name = "Consumables", frameName = MENU_FRAME_NAME },
        })
    end

    for index, profile in ipairs(DUNGEON_PROFILES) do
        local profileButton = menu.addButton(
            "Consumables" .. profile.name,
            0,
            (index - 1) * 34,
            profile.icon,
            profile.tip
        )

        profileButton.doLeft = function()
            ConsumablesUI:RunProfile(profile)
        end
    end

    local helpButton = menu.addButton(
        "ConsumablesHelp",
        0,
        #DUNGEON_PROFILES * 34,
        "INV_Misc_QuestionMark",
        "Bot Consumables Help"
            .. "\n|cffffffffExplains named dungeon profiles, custom consumable levels, bot eligibility, protection effects, and aura tracking.|r"
            .. "\n\n|cffff0000Left-click to open the consumable system explanation|r"
            .. "\n|cff999999(Executed by: System)|r"
    )

    helpButton.doLeft = function()
        menu:Hide()
        ConsumablesUI:ShowHelp()
    end

    menu:HookScript("OnHide", function()
        if MultiBot.RequestClickBlockerUpdate then
            MultiBot.RequestClickBlockerUpdate(menu)
        end
    end)

    ConsumablesUI.initialized = true
    ConsumablesUI.mainButton = mainButton
    ConsumablesUI.menu = menu
    ConsumablesUI.helpButton = helpButton
    ConsumablesUI.lastLevel = ConsumablesUI.lastLevel or DEFAULT_LEVEL

    return ConsumablesUI
end
