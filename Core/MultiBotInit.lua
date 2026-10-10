MultiBot.MB_PAGE_DEFAULT = string.format("%d/%d", 0, 0)

-- MULTIBAR --
local tMultiBar = MultiBot.addFrame("MultiBar", -363, 144, 36)
MultiBot.PromoteFrame(tMultiBar)
tMultiBar:SetMovable(true)
tMultiBar:SetClampedToScreen(true)

-- LEFT --
local tLeft = tMultiBar.addFrame("Left", -76, 2, 32)
MultiBot.PromoteFrame(tLeft)

if MultiBot.InitializeLeftCoreUI then
	MultiBot.InitializeLeftCoreUI(tLeft)
end

MultiBot.BuildAttackUI(tLeft)

MultiBot.BuildFleeUI(tLeft)

if MultiBot.BuildFormationUI then
	MultiBot.BuildFormationUI(tLeft)
elseif MultiBot.dprint then
	MultiBot.dprint("INIT", "BuildFormationUI missing at init time")
end

if MultiBot.InitializeBeastUI then
	MultiBot.InitializeBeastUI(tLeft)
end

if MultiBot.InitializeCreatorUI then
	MultiBot.InitializeCreatorUI(tLeft)
end

if MultiBot.InitializeUnitsRootUI then
	MultiBot.InitializeUnitsRootUI(tMultiBar)
end

if MultiBot.InitializeMainUI then
	MultiBot.InitializeMainUI(tMultiBar)
end

MultiBot.BuildGmUI(tMultiBar)

-- RIGHT --
local tRight = tMultiBar.addFrame("Right", 34, 2, 32)
MultiBot.PromoteFrame(tRight)

MultiBot._lastIncMode  = "WHISPER"
MultiBot._lastCompMode = "WHISPER"
MultiBot._lastAllMode       = "WHISPER"
MultiBot._awaitingQuestsAll = false
MultiBot._buildingAllQuests = false
MultiBot._blockOtherQuests = false

if MultiBot.InitializeQuestsMenu then
    MultiBot.InitializeQuestsMenu(tRight)
end

if MultiBot.InitializeGroupActionsUI then
	MultiBot.InitializeGroupActionsUI(tRight)
end

if MultiBot.InitializeConsumablesUI then
	MultiBot.InitializeConsumablesUI(tRight)
end

if MultiBot.InitializeNT1TalentsUI then
	MultiBot.InitializeNT1TalentsUI(tRight)
end

-- Both custom right-side controls are opt-in. Hiding them here prevents
-- a flash of visible buttons before the saved main-bar settings restore.
if MultiBot.RefreshNaxxramasRightButtons then
	MultiBot.RefreshNaxxramasRightButtons()
end

MultiBot.InitializeInventoryFrame()

MultiBot.InitializeItemusFrame()

MultiBot.InitializeIconosFrame()

MultiBot.InitializeSpellBookFrame()

if MultiBot.InitializeCharacterInfoFrame then
	MultiBot.InitializeCharacterInfoFrame()
end

if MultiBot.InitializeBankFrame then
	MultiBot.InitializeBankFrame()
end

if MultiBot.InitializeRewardFrame then
	MultiBot.InitializeRewardFrame()
end

if MultiBot.InitializeTalentFrameModule then
    MultiBot.InitializeTalentFrameModule()
end

if MultiBot.InitializeRTSCUI then
	MultiBot.InitializeRTSCUI(tMultiBar)
end

MultiBot.state = true
print("MultiBot")