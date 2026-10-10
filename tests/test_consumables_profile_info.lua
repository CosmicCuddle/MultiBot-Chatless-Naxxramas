-- WoW 3.3.5a regression: dungeon menu order, profile right-click help
-- and unchanged left-click commands. Mock-only: no Playerbot is affected.
MultiBot = {}
StaticPopupDialogs = {}
local popups, sent, messages = {}, {}, {}
CANCEL, OKAY = "Cancel", "Okay"
UIErrorsFrame = {AddMessage=function(_, value) messages[#messages+1]=value end}
StaticPopup_Show=function(key,a,b)
    popups[#popups+1]={key=key,title=a,description=b}
end
SendChatMessage=function(command,channel)
    assert(channel=="SAY")
    sent[#sent+1]=command
end

local menu={
    buttons={},
    Hide=function(self) self.visible=false end,
    Show=function(self) self.visible=true end,
    IsShown=function(self) return self.visible end,
    HookScript=function(self,event,callback) self.hooks=self.hooks or {}; self.hooks[event]=callback end,
}
menu.addButton=function(name,x,y,icon,tooltip)
    local button={name=name,x=x,y=y,icon=icon,tooltip=tooltip}
    menu.buttons[#menu.buttons+1]=button
    return button
end
local root={buttons={}}
root.addButton=function(name,x,y,icon,tooltip)
    local button={name=name,x=x,y=y,icon=icon,tooltip=tooltip}
    root.buttons[#root.buttons+1]=button
    return button
end
root.addFrame=function(name,x,y,w,h,height)
    assert(name=="ConsumablesMenu" and height==9*34)
    menu.parentInfo={name=name,x=x,y=y,width=w,height=h,contentHeight=height}
    return menu
end
MultiBot.BindShiftRightSwapButtons=function() end

dofile("UI/MultiBotConsumablesUI.lua")
local ui=assert(MultiBot.InitializeConsumablesUI(root))
assert(ui.initialized and ui.menu==menu)
assert(#menu.buttons==9,"Eight dungeons + Help icon required")
assert(StaticPopupDialogs.MULTIBOT_CONSUMABLES_PROFILE_INFO,
    "Right-click profile info popup must be registered")
assert(StaticPopupDialogs.MULTIBOT_CONSUMABLES_HELP,
    "Existing general consumables Help must remain")
local expected={
    {name="Maraudon", cmd="mara", school="Nature", cap="54"},
    {name="SunkenTemple", cmd="sunken", school="Nature", cap="54"},
    {name="BlackrockDepths", cmd="brd", school="Fire", cap="60"},
    {name="Scholomance", cmd="scholo", school="Shadow", cap="60"},
    {name="StratholmeUndead", cmd="stratud", school="Shadow", cap="60"},
    {name="DireMaul", cmd="dm", school="Wing auto-detected", cap="60"},
    {name="LowerBlackrockSpire", cmd="lbrs", school="no special protection", cap="60"},
    {name="UpperBlackrockSpire", cmd="ubrs", school="Fire", cap="60"},
}
for index, item in ipairs(expected) do
    local button=menu.buttons[index]
    assert(button.name=="Consumables"..item.name,
        "Dungeon name/icon association must not change: "..item.name)
    assert(button.y==(8-index)*34,
        "Screen positions must reverse: Maraudon top, Upper Blackrock Spire bottom")
    assert(button.tooltip:find("Right-click: see expected consumables",1,true))
    assert(type(button.doRight)=="function" and type(button.doLeft)=="function",
        "Both mouse buttons must be handled independently")
    local oldCommands=#sent
    local oldMessages=#messages
    button.doRight()
    assert(#sent==oldCommands and #messages==oldMessages,
        "Right-click must be read-only; never apply consumables")
    local shown=assert(popups[#popups])
    assert(shown.key=="MULTIBOT_CONSUMABLES_PROFILE_INFO")
    assert(shown.description:find("Level cap: "..item.cap,1,true),
        "Dungeon cap must match Naxxramas Core for "..item.name)
    assert(shown.description:find(item.school,1,true),
        "Protection / wing distinction must match the server for "..item.name)
    assert(shown.title and shown.title~="",
        "Popup must show dungeon profile name")
    button.doLeft()
    assert(sent[#sent]==".bot consumables "..item.cmd and #sent==oldCommands+1,
        "Left-click must keep each dungeon command paired with its original icon")
end

local help=menu.buttons[9]
assert(help.name=="ConsumablesHelp" and help.y==8*34,
    "General Help must remain separate from the eight dungeon profiles")
local before=#sent
help.doLeft()
assert(#sent==before,"General Help must not issue consumables command")
assert(popups[#popups].key=="MULTIBOT_CONSUMABLES_HELP")
assert(MultiBot.InitializeConsumablesUI(root)==ui and #menu.buttons==9,
    "Repeated initialization must not duplicate dungeon buttons")
print("Dungeon screen order, all right-click detail popups, 8 left-click commands and Help passed")
