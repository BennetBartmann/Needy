-----------------------------------------------------------------------------------------------
-- Client Lua Script for Needy
-- A Greedy Fork
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
require "Item"
require "ChatSystemLib"

-----------------------------------------------------------------------------------------------
-- Needy Module Definition
-----------------------------------------------------------------------------------------------
local Needy = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local eNeedy = {}
eNeedy.greed = 1
eNeedy.need = 2
eNeedy.disabled = 3

local tNeedySettings = { 
	"nGreedEquipment",
	"nGreedMisc",
	"nGreedSurvivalist",
	"nGreedFragments",
	"nGreedRunes",
	"btRuneTypes",
	"bEquipPass",
	"bGreedAll",
	"eGreedQuality",
	"totalRolls",
	"tNeedySetOne",
	"tNeedySetTwo",
	"setName"
}


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Needy:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
	
	o.restored = false
	o.needFlag = false
	
    return o
end

function Needy:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = "Needy"
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Needy OnLoad
-----------------------------------------------------------------------------------------------
function Needy:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Needy.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Needy OnDocLoaded
-----------------------------------------------------------------------------------------------
function Needy:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "NeedyForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
		if self.totalRolls == nil then
			self.totalRolls = 0
		end
		

		
		if self.tNeedySetOne == nil then
			Print ("Durch 1")
			self.tNeedySetOne = {
				"nGreedEquipment",
				"nGreedMisc",
				"nGreedSurvivalist",
				"nGreedFragments",
				"nGreedRunes",
				"btRuneTypes",
				"bEquipPass",
				"bGreedAll",
				"eGreedQuality"
				}
				
			self:DefaultSettingsFor(self.tNeedySetOne)
		end
		
		if self.tNeedySetTwo == nil then
			Print ("Durch 2")
			self.tNeedySetTwo = {
				"nGreedEquipment",
				"nGreedMisc",
				"nGreedSurvivalist",
				"nGreedFragments",
				"nGreedRunes",
				"btRuneTypes",
				"bEquipPass",
				"bGreedAll",
				"eGreedQuality"
				}
			self:DefaultSettingsFor(self.tNeedySetTwo)
		end
		
		if self.setName == nil then
			self.setName = 1
			self:saveSet()
		end
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("needy", 				"OnNeedyOn", self)
		Apollo.RegisterSlashCommand("rolls", 				"OnNeedyRolls", self)
		Apollo.RegisterSlashCommand("needysetone", 			"setSetOne", self)
		Apollo.RegisterSlashCommand("needysettwo", 			"setSetTwo", self)
		Apollo.RegisterEventHandler("LootRollUpdate",		"OnGroupLoot", self)
		Apollo.RegisterEventHandler("Group_AcceptInvite",	"OnGroupAcceptInvite", self)		-- ()
		Apollo.RegisterTimerHandler("NotifySettings", "NotifySettings", self)


		
		--look up imporant form elements now (so we don't have to search again each time)
		self.tUI = {}
		self.tUI.wndEquipment = self.wndMain:FindChild("EquipmentFrame")
		self.tUI.wndRunes = self.wndMain:FindChild("RuneFrame")
		self.tUI.wndMisc = self.wndMain:FindChild("MiscFrame")
		self.tUI.wndRarity = self.wndMain:FindChild("RarityTypesFrame")
		self.tUI.wndSurvivalist = self.wndMain:FindChild("GreedOnSurvivalistLoot")
		self.tUI.wndFragments = self.wndMain:FindChild("FragmentFrame")
		
		self.tUI.btnAir = self.wndMain:FindChild("RuneAirButton")
		self.tUI.btnEarth = self.wndMain:FindChild("RuneEarthButton")
		self.tUI.btnFire = self.wndMain:FindChild("RuneFireButton")
		self.tUI.btnFusion = self.wndMain:FindChild("RuneFusionButton")
		self.tUI.btnLife = self.wndMain:FindChild("RuneLifeButton")
		self.tUI.btnLogic = self.wndMain:FindChild("RuneLogicButton")
		self.tUI.btnWater = self.wndMain:FindChild("RuneWaterButton")
		
		self.tUI.btnEquipPass = self.wndMain:FindChild("EquipmentPassButton")
		self.tUI.btnGreedAll = self.wndMain:FindChild("GreedAllButton")
		
		--set up converter tables
		self.tUI.BtnToQuality = {}
		self.tUI.BtnToQuality[1] = Item.CodeEnumItemQuality.Average
		self.tUI.BtnToQuality[2] = Item.CodeEnumItemQuality.Good
		self.tUI.BtnToQuality[3] = Item.CodeEnumItemQuality.Excellent
		self.tUI.BtnToQuality[4] = Item.CodeEnumItemQuality.Superb
		self.tUI.BtnToQuality[5] = Item.CodeEnumItemQuality.Legendary
		self.tUI.BtnToQuality[6] = Item.CodeEnumItemQuality.Artifact
		
		self.tUI.QualityToBtn = {}
		self.tUI.QualityToBtn[Item.CodeEnumItemQuality.Average] = 1
		self.tUI.QualityToBtn[Item.CodeEnumItemQuality.Good] = 2
		self.tUI.QualityToBtn[Item.CodeEnumItemQuality.Excellent] = 3
		self.tUI.QualityToBtn[Item.CodeEnumItemQuality.Superb] = 4
		self.tUI.QualityToBtn[Item.CodeEnumItemQuality.Legendary] = 5
		self.tUI.QualityToBtn[Item.CodeEnumItemQuality.Artifact] = 6
		
		self.tUI.ItemTypeToSigilEnum = {}
		self.tUI.ItemTypeToSigilEnum[339] = Item.CodeEnumSigilType.Water
		self.tUI.ItemTypeToSigilEnum[340] = Item.CodeEnumSigilType.Life
		self.tUI.ItemTypeToSigilEnum[341] = Item.CodeEnumSigilType.Earth
		self.tUI.ItemTypeToSigilEnum[342] = Item.CodeEnumSigilType.Fusion
		self.tUI.ItemTypeToSigilEnum[343] = Item.CodeEnumSigilType.Fire
		self.tUI.ItemTypeToSigilEnum[344] = Item.CodeEnumSigilType.Logic
		self.tUI.ItemTypeToSigilEnum[345] = Item.CodeEnumSigilType.Air
		
		
		-- Do additional Addon initialization here
		self.crbAddon = Apollo.GetAddon("NeedVsGreed")
		self.crbChat = Apollo.GetAddon("ChatLog")
		
		if GameLib.GetLootRolls() then
			self:OnGroupLoot()
		end
	end
end

function Needy:OnGroupAcceptInvite()
	Print ("Ausgeloest 1")
	Apollo.CreateTimer("NotifySettings", 3, false)
end

function Needy:NotifySettings()
	Print ("Ausgeloest 2")
	self:sendGroupMessage("I use Needy my Settings are:")
	if self.bGreedAll then
		self:sendGroupMessage("I Greed on all non-needable Items")
	end
	if self.bEquipPass then
		self:sendGroupMessage("I Pass on all non Needable Equipment items")
	end
	if self.nGreedEquipment == eNeedy.greed then
		self:sendGroupMessage ("I greed on all Equipment with quality "..self:getQualityString(self.eGreedQuality).." and lower")
	end
	if self.nGreedRunes == eNeedy.need then
		self:sendGroupMessage ("I need on Sigils")
	end
	if self.nGreedRunes == eNeedy.greed then
		self:sendGroupMessage ("I greed on Sigils")
	end
	if self.nGreedFragments == eNeedy.need then
		self:sendGroupMessage ("I need on Fragments")
	end
	if self.nGreedFragments == eNeedy.greed then
		self:sendGroupMessage ("I greed on Fragments")
	end
	if self.nGreedSurvivalist == eNeedy.need then
		self:sendGroupMessage ("I need on Survivalist Loot")
	end
	if self.nGreedSurvivalist == eNeedy.greed then
		self:sendGroupMessage ("I greed on survivalist Loot")
	end
	if self.nGreedMisc == eNeedy.need then
		self:sendGroupMessage ("I need on Everything else")
	end
	if self.nGreedMisc == eNeedy.greed then
		self:sendGroupMessage ("I greed on Everything else")
	end
end
function Needy:getQualityString(quality)
	if quality == 1 then
		return "white"
	end
	if quality == 2 then
		return "green"
	end
	if quality == 3 then
		return "blue"
	end
	if quality == 4 then
		return "eternal"
	end
	if quality == 5 then
		return "quality above eternal"
	end	
end
function Needy:setSetOne()
	Print("Loading Set One")
	self:saveSet()
	self:loadSetOne()
	self.setName = 1
	self.wndMain:Close()
end

function Needy:setSetTwo()
	Print("Loading Set Two")
	self:saveSet()
	self:loadSetTwo()
	self.setName = 2
	self.wndMain:Close()
end

function Needy:saveSet()
	if self.setName == 1 then
		Print("Saving Set One")
		self:saveSetOne()
	end
	if self.setName == 2 then
		Print("Saving Set Two")
		self:saveSetTwo()
	end
end

function Needy:overtakeSet(setToBeSet, newSet)
	setToBeSet.nGreedEquipment = newSet.nGreedEquipment
	setToBeSet.nGreedMisc = newSet.nGreedMisc
	setToBeSet.nGreedSurvivalist = newSet.nGreedSurvivalist
	setToBeSet.nGreedFragments = newSet.nGreedFragments
	setToBeSet.btRuneTypes = newSet.btRuneTypes
	setToBeSet.bEquipPass = newSet.bEquipPass
	setToBeSet.bGreedAll = newSet.bGreedAll
	setToBeSet.eGreedQuality = newSet.eGreedQuality
end

function Needy:saveSetOne()
	self.tNeedySetOne.nGreedEquipment = self.nGreedEquipment
	self.tNeedySetOne.nGreedMisc = self.nGreedMisc
	self.tNeedySetOne.nGreedSurvivalist = self.nGreedSurvivalist
	self.tNeedySetOne.nGreedFragments = self.nGreedFragments
	self.tNeedySetOne.btRuneTypes = self.btRuneTypes
	self.tNeedySetOne.bEquipPass = self.bEquipPass
	self.tNeedySetOne.bGreedAll = self.bGreedAll
	self.tNeedySetOne.eGreedQuality = self.eGreedQuality
end

function Needy:saveSetTwo()
	self.tNeedySetTwo.nGreedEquipment = self.nGreedEquipment
	self.tNeedySetTwo.nGreedMisc = self.nGreedMisc
	self.tNeedySetTwo.nGreedSurvivalist = self.nGreedSurvivalist
	self.tNeedySetTwo.nGreedFragments = self.nGreedFragments
	self.tNeedySetTwo.btRuneTypes = self.btRuneTypes
	self.tNeedySetTwo.bEquipPass = self.bEquipPass
	self.tNeedySetTwo.bGreedAll = self.bGreedAll
	self.tNeedySetTwo.eGreedQuality = self.eGreedQuality
end


function Needy:loadSetOne()
	self.nGreedEquipment = self.tNeedySetOne.nGreedEquipment
	self.nGreedMisc = self.tNeedySetOne.nGreedMisc
	self.nGreedSurvivalist = self.tNeedySetOne.nGreedSurvivalist
	self.nGreedFragments = self.tNeedySetOne.nGreedFragments
	self.btRuneTypes = self.tNeedySetOne.btRuneTypes
	self.bEquipPass = self.tNeedySetOne.bEquipPass
	self.bGreedAll = self.tNeedySetOne.bGreedAll
	self.eGreedQuality = self.tNeedySetOne.eGreedQuality
end

function Needy:loadSetTwo()
	self.nGreedEquipment = self.tNeedySetTwo.nGreedEquipment
	self.nGreedMisc = self.tNeedySetTwo.nGreedMisc
	self.nGreedSurvivalist = self.tNeedySetTwo.nGreedSurvivalist
	self.nGreedFragments = self.tNeedySetTwo.nGreedFragments
	self.btRuneTypes = self.tNeedySetTwo.btRuneTypes
	self.bEquipPass = self.tNeedySetTwo.bEquipPass
	self.bGreedAll = self.tNeedySetTwo.bGreedAll
	self.eGreedQuality = self.tNeedySetTwo.eGreedQuality
end

-----------------------------------------------------------------------------------------------
-- Needy Functions
-----------------------------------------------------------------------------------------------
function Needy:OnNeedyRolls()
	Print(self.totalRolls)
end
-- Define general functions here
function Needy:OnGroupLoot()
	--look for settings to be sure
	if not self.restored then
		self:DefaultSettings()
	end
	
	--get list of loot
	local tLoot = GameLib.GetLootRolls()
	
	--greed on everything that fits the criteria
	for idx, tCurrentElement in ipairs(tLoot) do
		self.needFlag = false
		self:RollOnIt(tCurrentElement)
	end
end

function Needy:RollOnIt(tCurrentElement)
	local nLootID = tCurrentElement.nLootId
	local tItem = tCurrentElement.itemDrop
	
	if self.bGreedAll then
		if self:GreedNonNeedables(nLootID) then
			return
		end
	end
	
	if tItem:IsEquippable() then
		if self:RollOnEquipables(tItem, nLootID) then
			return
		end
	end
	
	if self.nGreedRunes < eNeedy.disabled and tItem:GetItemType() <= 345 and tItem:GetItemType() >= 339 then
		self:RollOnRunes(tCurrentElement, nLootID)
		return
	end
	
	if self.nGreedSurvivalist < eNeedy.disabled and tItem:GetItemId() <= 43013 and tItem:GetItemId() >= 42996 then
		self:RollOnThis(self.nGreedSurvivalist, nLootID)
		return
	end
	
	if self.nGreedFragments < eNeedy.disabled and tItem:GetItemId() <= 29613 and tItem:GetItemId() >= 29609 then
		self:RollOnThis(self.nGreedFragments,nLootID)
		return
	end
	
	if self.nGreedMisc < eNeedy.disabled then
		self:RollOnThis(self.nGreedMisc, nLootID)
	end
end

function Needy:RollOnThis(option,itemID)
	if option== eNeedy.need then 
		self:Need(itemID)
	else
		self:Greed(itemID)
	end
end

function Needy:RollOnRunes(tLoot, itemID)
	local tItem = tLoot.itemDrop
	if self.btRuneTypes[self.tUI.ItemTypeToSigilEnum[tItem:GetItemType()]] then
		if self.nGreedRunes == eNeedy.need then
			self:Need(itemID)
			return true
		else
			self:Greed(itemID)
			return true
		end
	else
		return false
	end
end

--If not Needable, then Greed
function Needy:GreedNonNeedables(lootID)
	if not GameLib.IsNeedRollAllowed(lootID) then
		self:Greed(lootID)
		self:InformCarbine()
		return true
	end
	return false
end

function Needy:Need(lootID)
	GameLib.RollOnLoot(lootID, true)
	self.totalRolls = self.totalRolls + 1
	self:InformCarbine()
end

function Needy:Greed(lootID)
	GameLib.RollOnLoot(lootID, false)
	self.totalRolls = self.totalRolls + 1
	self:InformCarbine()
end

function Needy:RollOnEquipables(tItem,lootID)
	--equipment
	if self.bEquipPass then 
		self:Pass(itemID)
	end
	if self.nGreedEquipment == eNeedy.need then
		self:GreedIfNeedNotAllowed(lootID)
		return true
	elseif self.nGreedEquipment == eNeedy.greed then
		return self:GreedOnLowQuality(self.eGreedQuality + 1, tItem, lootID)
	end
end
function Needy:Pass(itemID)
	GameLib.PassOnLoot(itemID)
	self.totalRolls = self.totalRolls + 1
	self:InformCarbine()
end
function Needy:GreedOnLowQuality(quality, tItem, lootID)
	if quality > tItem:GetItemQuality() then
		self:Greed(lootID)
		return true
	else
		return false
	end
end

function Needy:GreedIfNeedNotAllowed(lootID)
	if GameLib.IsNeedRollAllowed(lootID) then
		self:Need(lootID)
	else
		self:Greed(lootID)
	end	
end
function Needy:InformCarbine()
	if self.crbAddon ~= nil then
		local crbWindow = self.crbAddon.wndMain
		if not crbWindow then return end
		if crbWindow:GetData() == nLootID then
			crbWindow:Close()
		end
	end
end

-- for the button in options menu
function Needy:OnConfigure()
	self:OnNeedyOn()
end

-- set default settings
function Needy:DefaultSettings()
	self.nGreedEquipment = eNeedy.need
	self.nGreedMisc = eNeedy.disabled
	self.nGreedSurvivalist = eNeedy.disabled
	self.nGreedFragments = eNeedy.disabled
	self.nGreedRunes = eNeedy.greed

	self.btRuneTypes = {}
	self.btRuneTypes[Item.CodeEnumSigilType.Air] = false
	self.btRuneTypes[Item.CodeEnumSigilType.Earth] = false
	self.btRuneTypes[Item.CodeEnumSigilType.Fire] = false
	self.btRuneTypes[Item.CodeEnumSigilType.Water] = false
	self.btRuneTypes[Item.CodeEnumSigilType.Fusion] = false
	self.btRuneTypes[Item.CodeEnumSigilType.Life] = false
	self.btRuneTypes[Item.CodeEnumSigilType.Logic] = false
	
	self.bEquipPass = false
	self.bGreedAll = false
	
	self.eGreedQuality = Item.CodeEnumItemQuality.Good
	self.totalRolls = 0
	self.restored = true
end

-- set default settings
function Needy:DefaultSettingsFor(option)
	option.nGreedEquipment = eNeedy.need
	option.nGreedMisc = eNeedy.disabled
	option.nGreedSurvivalist = eNeedy.disabled
	option.nGreedFragments = eNeedy.disabled
	option.nGreedRunes = eNeedy.greed

	option.btRuneTypes = {}
	option.btRuneTypes[Item.CodeEnumSigilType.Air] = false
	option.btRuneTypes[Item.CodeEnumSigilType.Earth] = false
	option.btRuneTypes[Item.CodeEnumSigilType.Fire] = false
	option.btRuneTypes[Item.CodeEnumSigilType.Water] = false
	option.btRuneTypes[Item.CodeEnumSigilType.Fusion] = false
	option.btRuneTypes[Item.CodeEnumSigilType.Life] = false
	option.btRuneTypes[Item.CodeEnumSigilType.Logic] = false
	
	option.bEquipPass = false
	option.bGreedAll = false
	
	option.eGreedQuality = Item.CodeEnumItemQuality.Good
	option.totalRolls = 0
	option.restored = true
end

-- Save User Settings
function Needy:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	local tSave = {}
	for idx,property in ipairs(tNeedySettings) do tSave[property] = self[property] end
	
	return tSave
end


-- Restore Saved User Settings
function Needy:OnRestore(eType, t)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	
	for idx,property in ipairs(tNeedySettings) do
		if t[property] ~= nil then self[property] = t[property] end
	end
	
	self.restored = true
end

function Needy:reloadSettings(t)
	for idx,property in ipairs(t) do
		if t[property] ~= nil then self[property] = t[property] end
	end
end

-----------------------------------------------------------------------------------------------
-- NeedyForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function Needy:OnApply()
	--save the settings.
	self.nGreedEquipment = self.tUI.wndEquipment:GetRadioSel("Equipment_ButtonGroup")
	self.nGreedMisc = self.tUI.wndMisc:GetRadioSel("Misc_ButtonGroup")
	self.nGreedSurvivalist = self.tUI.wndSurvivalist:GetRadioSel("Surv_ButtonGroup")
	self.nGreedFragments = self.tUI.wndFragments:GetRadioSel("Frag_ButtonGroup")
	self.nGreedRunes = self.tUI.wndRunes:GetRadioSel("Rune_ButtonGroup")
	
	self.btRuneTypes[Item.CodeEnumSigilType.Air] = self.tUI.btnAir:IsChecked()
	self.btRuneTypes[Item.CodeEnumSigilType.Earth] = self.tUI.btnEarth:IsChecked()
	self.btRuneTypes[Item.CodeEnumSigilType.Fire] = self.tUI.btnFire:IsChecked()
	self.btRuneTypes[Item.CodeEnumSigilType.Fusion] = self.tUI.btnFusion:IsChecked()
	self.btRuneTypes[Item.CodeEnumSigilType.Life] = self.tUI.btnLife:IsChecked()
	self.btRuneTypes[Item.CodeEnumSigilType.Logic] = self.tUI.btnLogic:IsChecked()
	self.btRuneTypes[Item.CodeEnumSigilType.Water] = self.tUI.btnWater:IsChecked()
	
	self.eGreedQuality = self.tUI.BtnToQuality[self.tUI.wndRarity:GetRadioSel("Rarity_RadioGroup")]
	self.bEquipPass = self.tUI.btnEquipPass:IsChecked()
	self.bGreedAll = self.tUI.btnGreedAll:IsChecked()
	self.wndMain:Close() -- hide the window
end

function Needy:OnAllRunes()
	if self.tUI.btnAir:IsChecked() then --dont use air as dirty toggle check
		self.tUI.btnAir:SetCheck(false)
		self.tUI.btnEarth:SetCheck(false)
		self.tUI.btnFire:SetCheck(false)
		self.tUI.btnFusion:SetCheck(false)
		self.tUI.btnLife:SetCheck(false)
		self.tUI.btnLogic:SetCheck(false)
		self.tUI.btnWater:SetCheck(false)
	else
		self.tUI.btnAir:SetCheck(true)
		self.tUI.btnEarth:SetCheck(true)
		self.tUI.btnFire:SetCheck(true)
		self.tUI.btnFusion:SetCheck(true)
		self.tUI.btnLife:SetCheck(true)
		self.tUI.btnLogic:SetCheck(true)
		self.tUI.btnWater:SetCheck(true)
	end
end

-- when the Cancel button is clicked
function Needy:OnCancel()
	self.wndMain:Close() -- hide the window
end

-- on SlashCommand "/Needy" or opening via options menu
function Needy:OnNeedyOn()
	--look for settings to be sure
	if not self.restored then
		self:DefaultSettings()
	end
	--make the UI show current settings.
	--Equip settings
	self.tUI.wndEquipment:SetRadioSel("Equipment_ButtonGroup",self.nGreedEquipment)
	self.tUI.wndRarity:SetRadioSel("Rarity_RadioGroup", self.tUI.QualityToBtn[self.eGreedQuality])
	
	--Misc settings
	self.tUI.wndMisc:SetRadioSel("Misc_ButtonGroup", self.nGreedMisc)
	
	--Survivalist settings
	self.tUI.wndSurvivalist:SetRadioSel("Surv_ButtonGroup", self.nGreedSurvivalist)

	--Fragment Settings
	self.tUI.wndFragments:SetRadioSel("Frag_ButtonGroup", self.nGreedFragments)
	--rune settings
	self.tUI.wndRunes:SetRadioSel("Rune_ButtonGroup", self.nGreedRunes)
	
	self.tUI.btnAir:SetCheck(self.btRuneTypes[Item.CodeEnumSigilType.Air])
	self.tUI.btnEarth:SetCheck(self.btRuneTypes[Item.CodeEnumSigilType.Earth])
	self.tUI.btnFire:SetCheck(self.btRuneTypes[Item.CodeEnumSigilType.Fire])
	self.tUI.btnFusion:SetCheck(self.btRuneTypes[Item.CodeEnumSigilType.Fusion])
	self.tUI.btnLife:SetCheck(self.btRuneTypes[Item.CodeEnumSigilType.Life])
	self.tUI.btnLogic:SetCheck(self.btRuneTypes[Item.CodeEnumSigilType.Logic])
	self.tUI.btnWater:SetCheck(self.btRuneTypes[Item.CodeEnumSigilType.Water])
	
	self.tUI.btnEquipPass:SetCheck(self.bEquipPass)
	self.tUI.btnGreedAll:SetCheck(self.bGreedAll)
	self.wndMain:Invoke() -- show the window
end
-----
-- helper for Chat Messages
function Needy:sendGroupMessage(message)
	for _,channel in pairs(ChatSystemLib.GetChannels()) do
		if channel:GetType() == ChatSystemLib.ChatChannel_Party then
			channel:Send("[Needy] " .. message)
		end
	end
end
-----------------------------------------------------------------------------------------------
-- Needy Instance
-----------------------------------------------------------------------------------------------
local NeedyInst = Needy:new()
NeedyInst:Init()
