-- Standalone WoW 3.3.5a UI/transport regression for NT1 playerbot import.
-- Uses a minimal mocked frame surface. Does not change character data.
MultiBot = {}
UISpecialFrames = {}
local frames, commands, errors = {}, {}, {}
local currentTarget = {name="Testwarrior", class="WARRIOR", guid="Player-01"}
local Frame = {}
Frame.__index = Frame
function Frame:SetWidth(value) self.width=value end
function Frame:SetHeight(value) self.height=value end
function Frame:SetSize(width, height) self.width=width self.height=height end
function Frame:SetPoint(...) self.position={...} end
function Frame:SetText(value) self.text=value end
function Frame:GetText() return self.text end
function Frame:SetJustifyH(value) self.justify=value end
function Frame:SetTextColor(...) self.color={...} end
function Frame:SetFontObject(value) self.font=value end
function Frame:SetAutoFocus() end
function Frame:SetMaxLetters(value) self.maxLetters=value end
function Frame:SetFrameStrata() end
function Frame:SetMovable() end
function Frame:SetClampedToScreen() end
function Frame:EnableMouse() end
function Frame:RegisterForDrag() end
function Frame:SetBackdrop() end
function Frame:SetBackdropColor() end
function Frame:SetBackdropBorderColor() end
function Frame:SetFocus() self.focused=true end
function Frame:ClearFocus() self.focused=false end
function Frame:SetScript(event, callback) self.scripts[event]=callback end
function Frame:Show() self.visible=true end
function Frame:Hide() self.visible=false end
function Frame:IsShown() return self.visible end
function Frame:CreateFontString()
    return setmetatable({scripts={}},Frame)
end
function CreateFrame(kind,name,parent,template)
    local f=setmetatable({kind=kind,name=name,parent=parent,template=template,scripts={}},Frame)
    frames[#frames+1]=f
    if name then _G[name]=f end
    return f
end
UIParent=CreateFrame("Frame","UIParent")
UIErrorsFrame={AddMessage=function(_,value) errors[#errors+1]=value end}
function UnitExists(unit) return unit=="target" and currentTarget ~= nil end
function UnitIsPlayer(unit) return unit=="target" and currentTarget ~= nil end
function UnitIsUnit(unit,other) return unit=="target" and other=="player" and currentTarget and currentTarget.name=="Actualplayer" end
function UnitName(unit) return unit=="target" and currentTarget and currentTarget.name end
function UnitGUID(unit) return unit=="target" and currentTarget and currentTarget.guid end
function UnitClass(unit) return unit=="target" and "Warrior","WARRIOR" end
function SendChatMessage(command,channel)
    assert(channel=="SAY","NT1 commands must use the actual Naxxramas GM command pathway")
    commands[#commands+1]=command
end

dofile("UI/MultiBotNT1TalentsUI.lua")
local importer=assert(MultiBot.NT1Talents)
local created={}
local right={addButton=function(name,x,y,icon,tip)
    local button={name=name,x=x,y=y,icon=icon,tip=tip}
    created[#created+1]=button
    return button
end}
assert(MultiBot.InitializeNT1TalentsUI(right)==importer)
assert(#created==1 and created[1].name=="NT1Talents" and created[1].x==136,
    "One new right-side NT1 talents button should be present")
assert(created[1].tip:find("Naxxramas Core",1,true))
assert(MultiBot.InitializeNT1TalentsUI(right)==importer and #created==1,
    "Repeated initialization must not duplicate toolbar buttons")
assert(importer:ValidateCode("NT1:vanilla:warrior:2t-1", "warrior"))
assert(not importer:ValidateCode("NT1:vanilla:mage:2t-1", "warrior"),
    "Client must reject a code for the wrong target class")
assert(not importer:ValidateCode("NT1:vanilla:warrior:"),
    "An empty build cannot be applied accidentally")
assert(not importer:ValidateCode("NT1:vanilla:warrior:2t-1.2t-2"),
    "Duplicate talent entries are invalid")
assert(not importer:ValidateCode("NT1:vanilla:warrior:2t-1\n.naxxbot talents apply OtherPlayer NT1:"),
    "Chat-command injection must be rejected")
assert(not importer:ValidateCode("NT1:vanilla:warrior:2t-10"),
    "Rank 10 is not valid in NT1")
assert(not importer:ValidateCode("NT1:other:warrior:2t-1"),
    "Unknown eras are rejected")

currentTarget=nil
assert(not importer:Open(),"No target must not show the importer")
assert(#commands==0,"Target errors must never issue commands")
currentTarget={name="Actualplayer",guid="Player-99",class="WARRIOR"}
assert(not importer:Open(),"Do not allow own player character as bot target")
currentTarget={name="Testwarrior",guid="Player-01",class="WARRIOR"}
assert(importer:Open(),"Selected bot must open the NT1 paste window")
local popup=assert(importer.window)
assert(popup.visible and importer.input.maxLetters==2048)
assert(importer.targetLabel.text:find("Testwarrior",1,true))
assert(#UISpecialFrames==1 and UISpecialFrames[1]=="MultiBotNT1TalentsWindow")
assert(#commands==0,"Opening the paste dialog must never send an apply")

local code="NT1:vanilla:warrior:2t-1"
importer.input:SetText(code)
local ok=importer:SendToTarget("preview",importer.input:GetText())
assert(ok and #commands==1 and commands[1]==
    ".naxxbot talents preview Testwarrior "..code,
    "Preview should send the exact read-only Naxxramas Core command")
assert(popup.visible,"Preview must keep input available")

-- Code must never silently be sent to a new target.
currentTarget={name="Otherwarrior",guid="Player-02",class="WARRIOR"}
assert(not importer:SendToTarget("apply",code))
assert(#commands==1)
currentTarget={name="Testwarrior",guid="Player-03",class="WARRIOR"}
assert(not importer:SendToTarget("apply",code),
    "Same visible name with a different GUID must not be accepted")
assert(#commands==1)
currentTarget={name="Testwarrior",guid="Player-01",class="WARRIOR"}

-- WoW chat has a finite payload: do not issue truncated high-rank NT1 codes.
local longCode="NT1:vanilla:warrior:"..string.rep("abcd-1.",38).."abcd-1"
assert(importer:ValidateCode(longCode,"warrior"))
assert(not importer:SendToTarget("apply",longCode))
assert(#commands==1,"Oversized chat payload must not reach the server")

importer.input:SetText(code)
importer.input.scripts.OnEnterPressed(importer.input)
assert(#commands==2 and commands[2]==
    ".naxxbot talents apply Testwarrior "..code,
    "Enter should send exactly the selected bot's NT1 apply command")
assert(not popup.visible,"Successful apply submission closes popup")
assert(importer:Open(),"Reopen should work")
assert(importer.input.text=="","Reopen must not reuse a dangerous previously pasted code")
assert(#UISpecialFrames==1,"ESC registration must never duplicate")
importer.input.scripts.OnEscapePressed(importer.input)
assert(not popup.visible and not importer.input.focused,
    "Escape should cancel the window without sending commands")
assert(#commands==2)

print("NT1 Bot Talents: toolbar, preview/apply, strict syntax, bound target, transport limit and Escape passed")
