-----------------------------------------------------------------------------------------------
-- Client Lua Script for Needy
-- A Needy Fork
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
require "Item"
 
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
	"totalRolls"
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
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("needy", 				"OnNeedyOn", self)
		Apollo.RegisterSlashCommand("rolls", 				"OnNeedyRolls", self)
		Apollo.RegisterEventHandler("LootRollUpdate",		"OnGroupLoot", self)
		
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
	Print(tItem:GetItemType())
	if self.btRuneTypes[self.tUI.ItemTypeToSigilEnum[tItem:GetItemType()]] then
		if self.nGreedRunes == eNeedy.need then
			self:Need(itemID)
			return true
		else
			self:Gred(itemID)
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


-----------------------------------------------------------------------------------------------
-- Needy Instance
-----------------------------------------------------------------------------------------------
local NeedyInst = Needy:new()
NeedyInst:Init()
