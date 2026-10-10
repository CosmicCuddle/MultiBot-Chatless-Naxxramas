-- Behavior tests for the Naxxramas right-toolbar visibility configuration.
-- Run under Lua 5.1. No actual WoW client or addon SavedVariables changed.
MultiBot = {}
local updated = 0
MultiBot.RequestClickBlockerUpdate = function() updated = updated + 1 end

-- MainUI.lua installs the visibility helper before creating any live frames.
dofile("UI/MultiBotMainUI.lua")
assert(type(MultiBot.RefreshNaxxramasRightButtons) == "function")

local function makeButton()
    return {
        visible=true, x=0, y=0,
        setPoint=function(selfOrX, xOrY, maybeY)
            -- MultiBot's wrappers deliberately use button.setPoint(x,y),
            -- not a colon method. Handle exactly that call.
            assert(type(selfOrX)=="number" and type(xOrY)=="number" and maybeY==nil)
        end,
        Show=function(self) self.visible=true end,
        Hide=function(self) self.visible=false end,
    }
end
local consumables = makeButton()
local talents = makeButton()
consumables.setPoint = function(x,y) consumables.x=x consumables.y=y end
talents.setPoint = function(x,y) talents.x=x talents.y=y end

local menu = {visible=false, Hide=function(self) self.visible=false end}
local popup = {visible=false, Hide=function(self) self.visible=false end}
local edit = {focused=false,ClearFocus=function(self) self.focused=false end}
MultiBot.NT1Talents = {window=popup,input=edit}
local buttons = {ShowBotConsumables={state=false},ShowNT1Talents={state=false}}
MultiBot.frames = {
    MultiBar = {frames = {
        Main = {buttons=buttons},
        Right = {buttons={Consumables=consumables,NT1Talents=talents},
            frames={ConsumablesMenu=menu}},
    }},
}

-- Clean install: both features hidden, no visible orphan subpanel.
menu.visible=true
popup.visible=true
edit.focused=true
MultiBot.RefreshNaxxramasRightButtons()
assert(not consumables.visible and not talents.visible,
    "Both Naxxramas features must be hidden on fresh settings")
assert(not menu.visible and not popup.visible and not edit.focused,
    "Hidden parent must also close menu and pending NT1 paste popup")

buttons.ShowBotConsumables.state=true
MultiBot.RefreshNaxxramasRightButtons()
assert(consumables.visible and consumables.x==102 and not talents.visible,
    "Consumables only occupies its original right-hand slot")

buttons.ShowBotConsumables.state=false
buttons.ShowNT1Talents.state=true
MultiBot.RefreshNaxxramasRightButtons()
assert(not consumables.visible and talents.visible and talents.x==102,
    "NT1 only must move into first available Naxxramas slot")

buttons.ShowBotConsumables.state=true
MultiBot.RefreshNaxxramasRightButtons()
assert(consumables.visible and consumables.x==102 and talents.visible and talents.x==136,
    "Both enabled must appear side by side without collision")

buttons.ShowNT1Talents.state=false
popup.visible=true
edit.focused=true
MultiBot.RefreshNaxxramasRightButtons()
assert(not talents.visible and consumables.visible and consumables.x==102,
    "Turning NT1 off must not hide Consumables")
assert(not popup.visible and not edit.focused,
    "Turning NT1 off must dismiss the import popup safely")
assert(updated >= 5, "Button state changes must refresh click blockers")

-- Integration checks for saved settings and default-off toggles.
local function read(path)
    local f=assert(io.open(path,"r"))
    local content=f:read("*a")
    f:close()
    return content
end
local main=read("UI/MultiBotMainUI.lua")
local init=read("Core/MultiBotInit.lua")
local handler=read("Core/MultiBotHandler.lua")
for _,key in ipairs({"ShowBotConsumables","ShowNT1Talents"}) do
    assert(main:find('name = "'..key..'"',1,true),
        "Config menu missing "..key)
    assert(main:find('disabled = true',1,true),
        "New Naxxramas toggles should be off initially")
    assert(main:find('toggleNaxxramasControl(button, "'..key..'")',1,true),
        "Config toggle does not persist its own saved state")
    assert(handler:find('restoreEnableOnlyLeftToggle("'..key..'"',1,true),
        "Enabled Naxxramas toggle is not restored from SavedVariables")
    assert(handler:find('setSavedMainBarValue("'..key..'"',1,true),
        "Naxxramas toggle state not saved on logout")
end
assert(init:find('MultiBot.RefreshNaxxramasRightButtons()',1,true),
    "Initial render must hide both right-hand buttons before restoring saved state")
assert(not main:find('MultiBot.ActionToGroup("naxxbot',1,true),
    "Visibility switches must not execute bot talent commands")
print("Naxxramas right-toolbar default hidden, independent toggles, positioning, menu close and persistence hooks passed")
