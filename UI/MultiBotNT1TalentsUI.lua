-- Naxxramas NT1 Playerbot talent importer for WoW 3.3.5a.
-- Client-side paste/preview/apply interface for the separately maintained
-- Naxxramas Core command. The server remains authoritative for all changes.
-- No changes to mod-playerbots or the MultiBot bridge are required.
if not MultiBot then return end

local Talents = MultiBot.NT1Talents or {}
MultiBot.NT1Talents = Talents

local MAX_COMMAND_LENGTH = 255 -- WoW 3.3.5a chat transport limit; fail closed.
local MAX_CODE_LENGTH = 2048 -- Naxxramas Core parser limit.
local EXAMPLE = "NT1:vanilla:warrior:3g-1"
local CLASSES = {
    warrior=true, paladin=true, hunter=true, rogue=true, priest=true,
    deathknight=true, shaman=true, mage=true, warlock=true, druid=true,
}
local ERAS = {vanilla=true, tbc=true, wotlk=true}
local WINDOW_NAME = "MultiBotNT1TalentsWindow"

local function trim(value)
    return type(value) == "string" and
        value:match("^%s*(.-)%s*$") or ""
end

local function message(value, isError)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage("NT1 Talents: " .. value,
            isError and 1 or 0.35, isError and 0.3 or 1, 0.3, 1)
    end
end

-- A lightweight syntax check only. The server enforces real bot ownership,
-- talent IDs, class/era levels, prerequisites and available points.
function Talents:ValidateCode(text, botClass)
    local code = trim(text)
    if code == "" then
        return nil, "Paste an NT1 talent code first."
    end
    if #code > MAX_CODE_LENGTH then
        return nil, "This NT1 code exceeds the server's 2048-character limit."
    end
    local era, class, body = code:match("^NT1:([a-z]+):([a-z]+):(.*)$")
    if not era or not ERAS[era] or not CLASSES[class] then
        return nil, "Expected NT1:era:class:talent-ranks (example below)."
    end
    if botClass and CLASSES[botClass] and class ~= botClass then
        return nil, "Code is for " .. class .. ", but the selected bot is " .. botClass .. "."
    end
    if body == "" then
        return nil, "The code has no selected talents. Empty builds are not applied."
    end
    local count, seen = 0, {}
    for part in (body .. "."):gmatch("(.-)%.") do
        count = count + 1
        if count > 120 then return nil, "The code has too many talent entries." end
        local id, rank = part:match("^([0-9a-z]+)%-([1-9])$")
        if not id or not rank or seen[id] then
            return nil, "Invalid or duplicate talent entry in NT1 code."
        end
        seen[id] = true
    end
    return code, nil
end

local function getTarget()
    if not UnitExists or not UnitExists("target") or
        not UnitIsPlayer or not UnitIsPlayer("target") or
        (UnitIsUnit and UnitIsUnit("target", "player")) then
        return nil, "Target the Playerbot whose talents you want to set."
    end
    local name = UnitName and UnitName("target")
    if type(name) ~= "string" or name == "" or name:find("[%s%c]") then
        return nil, "The selected bot has no usable character name."
    end
    local classToken
    if type(UnitClass) == "function" then
        local _, token = UnitClass("target")
        classToken = token
    end
    local class = type(classToken) == "string" and
        classToken:lower():gsub("[^a-z]", "") or nil
    local guid = UnitGUID and UnitGUID("target") or nil
    return {name=name, class=class, guid=guid}, nil
end

function Talents:SendToTarget(action, text)
    if action ~= "apply" and action ~= "preview" then
        return false, "Unknown talent action."
    end
    local target, reason = getTarget()
    if not target then return false, reason end
    if not self.boundTarget or target.name ~= self.boundTarget.name or
        (self.boundTarget.guid and target.guid ~= self.boundTarget.guid) then
        return false, "Target changed. Reopen Talents for the correct bot."
    end
    local code, invalid = self:ValidateCode(text, target.class)
    if not code then return false, invalid end

    local command = ".naxxbot talents " .. action .. " " .. target.name .. " " .. code
    if #command > MAX_COMMAND_LENGTH then
        return false, "Code is too long for one 3.3.5a chat command. No command sent."
    end
    -- Intentional GM/server command path. This is not a Playerbots whisper,
    -- nor a new generic command-execution/fallback facility.
    SendChatMessage(command, "SAY")
    return true, "Command sent for " .. target.name ..
        ". Check server chat for " .. action .. " result."
end

local function styledLabel(parent, text, x, y, width, color)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    if color then label:SetTextColor(unpack(color)) end
    return label
end

local function button(parent, name, x, y, width, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 25)
    b:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
    b:SetText(name)
    b:SetScript("OnClick", callback)
    return b
end

function Talents:EnsureWindow()
    if self.window then return self.window end
    local window = CreateFrame("Frame", WINDOW_NAME, UIParent)
    window:SetWidth(560)
    window:SetHeight(238)
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    window:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() end)
    window:SetBackdrop({
        bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=false, edgeSize=28,
        insets={left=8,right=8,top=8,bottom=8},
    })
    window:SetBackdropColor(0.035, 0.03, 0.045, 0.98)
    window:SetBackdropBorderColor(0.68, 0.54, 0.30, 1)

    local title = styledLabel(window, "NT1 TALENT IMPORT  |  PLAYERBOT", 22, -18, 470,
        {1, 0.84, 0.42})
    if _G.GameFontNormalLarge then title:SetFontObject(_G.GameFontNormalLarge) end
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -7, -6)

    self.targetLabel = styledLabel(window, "", 22, -48, 510, {1, 0.84, 0.42})
    styledLabel(window,
        "Paste a build copied from N Talent Calculator or the Resource Hub website.",
        22, -73, 516)
    styledLabel(window, "Example: " .. EXAMPLE, 22, -91, 515,
        {0.69, 0.85, 1})

    local input = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    input:SetPoint("TOPLEFT", window, "TOPLEFT", 32, -120)
    input:SetSize(490, 28)
    input:SetAutoFocus(false)
    input:SetMaxLetters(MAX_CODE_LENGTH)
    input:SetText("")
    self.input = input

    self.status = styledLabel(window, "No command sent.", 22, -159, 516)
    styledLabel(window,
        "Applying changes bot talents. Preview first; server restrictions still apply.",
        22, -180, 518, {1, 0.67, 0.44})

    local function submit(action)
        local ok, reason = Talents:SendToTarget(action, input:GetText())
        Talents.status:SetText(reason)
        message(reason, not ok)
        if ok and action == "apply" then
            input:ClearFocus()
            window:Hide()
        end
        return ok
    end
    button(window, "Preview", 22, 16, 110, function() submit("preview") end)
    button(window, "Apply talents", 138, 16, 130, function() submit("apply") end)
    button(window, "Cancel", 274, 16, 110, function()
        input:ClearFocus()
        window:Hide()
    end)

    -- Requested keyboard shortcut: pressing Enter applies to the bot the
    -- user selected when opening this window (not a newly selected player).
    input:SetScript("OnEnterPressed", function() submit("apply") end)
    input:SetScript("OnEscapePressed", function()
        input:ClearFocus()
        window:Hide()
    end)
    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, WINDOW_NAME)
    end
    window:Hide()
    self.window = window
    return window
end

function Talents:Open()
    local target, reason = getTarget()
    if not target then message(reason, true); return false end
    self.boundTarget = target
    local window = self:EnsureWindow()
    self.targetLabel:SetText("Selected bot: " .. target.name ..
        "  |  Paste a matching " .. (target.class or "class") .. " build.")
    self.status:SetText("Preview is read-only; Apply changes talents. Check server response.")
    self.input:SetText("")
    window:Show()
    self.input:SetFocus()
    return true
end

function MultiBot.InitializeNT1TalentsUI(tRight)
    if Talents.mainButton then return Talents end
    if not tRight or not tRight.addButton then return nil end
    local b = tRight.addButton(
        "NT1Talents", 136, 0,
        "Interface\\AddOns\\MultiBot\\Textures\\Talent.blp",
        "NT1 Talents - selected Playerbot" ..
        "\n|cffffffffTarget a bot and paste an NT1 build from N Talent Calculator or the website.|r" ..
        "\n|cffffaa55Apply changes actual bot talents. Preview is read-only.|r" ..
        "\n\n|cffff0000Left-click: open NT1 build paste box|r" ..
        "\n|cff999999Requires Naxxramas Core BotTalentImport AccessMode 1 or 2.|r"
    )
    b.doLeft = function() Talents:Open() end
    Talents.mainButton = b
    return Talents
end
