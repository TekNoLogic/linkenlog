
----------------------
--      Locals      --
----------------------

local L = setmetatable({}, {__index=function(t,i) return i end})
local db

local crafts = {2259, 2018, 7411, 4036, 45357, 25229, 2108, 3908, 2550}

local function announce()
	for _,spellid in pairs(crafts) do
		local name = GetSpellInfo(spellid)
		local spellink, tradelink = GetSpellLink(name)
		if tradelink then
			print("Found craft", name, tradelink)
			SendAddonMessage("linken", tradelink, "GUILD")
		end
	end
end


------------------------------
--      Util Functions      --
------------------------------

local function Print(...) print("|cFF33FF99Linken Log|r:", ...) end


-----------------------------
--      Event Handler      --
-----------------------------

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")


function f:ADDON_LOADED(event, addon)
	if addon:lower() ~= "linkenlog" then return end

	local factionrealm = UnitFactionGroup("player").. " ".. GetRealmName()

--~ 	/spew LinkenLogDB["Alliance Area 52"]
	LinkenLogDB = LinkenLogDB or {}
	LinkenLogDB[factionrealm] = LinkenLogDB[factionrealm] or {}
	db = LinkenLogDB[factionrealm]
	for _,spellid in pairs(crafts) do
		local name = GetSpellInfo(spellid)
		db[name] = db[name] or {}
	end

	-- Do anything you need to do after addon has loaded

--~ 	LibStub("tekKonfig-AboutPanel").new("AddonTemplate", "AddonTemplate") -- Make first arg nil if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end


function f:PLAYER_LOGIN()
--~ 	self:RegisterEvent("PLAYER_LOGOUT")
	self:RegisterEvent("CHAT_MSG_ADDON")

	announce()

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


function f:CHAT_MSG_ADDON(event, prefix, message, channel, sender, ...)
	if prefix ~= "linken" then return end
--~ 	local level, name = message:match("|Htrade:%d+:(%d+):.+|h%[(%w+)%]|h|r")
	local name = message:match("|Htrade:.+|h%[(%w+)%]|h|r")
	print(sender, message, name, ...)
	local timestamp = date("%m/%d %H:%M")
	local patch = GetBuildInfo()
	db[name][sender] = string.join("\t", patch, timestamp, message)
end




local panel = CreateFrame("Frame", "LinkenLogFrame", UIParent)
panel:SetWidth(384) panel:SetHeight(512)
panel:SetPoint("TOPLEFT", 0, -104)
panel:SetToplevel(true)

panel:SetAttribute("UIPanelLayout-defined", true)
panel:SetAttribute("UIPanelLayout-enabled", true)
panel:SetAttribute("UIPanelLayout-area", "left")
panel:SetAttribute("UIPanelLayout-whileDead", true)
table.insert(UISpecialFrames, "LinkenLogFrame")

panel:Hide()

--~ 		<HitRectInsets>
--~ 			<AbsInset left="0" right="30" top="0" bottom="75"/>
--~ 		</HitRectInsets>


local topleft = panel:CreateTexture(nil, "BACKGROUND")
topleft:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-General-TopLeft]])
topleft:SetWidth(256) topleft:SetHeight(256)
topleft:SetPoint("TOPLEFT", 2, -1)

local topright = panel:CreateTexture(nil, "BACKGROUND")
topright:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-General-TopRight]])
topright:SetWidth(128) topright:SetHeight(256)
topright:SetPoint("TOPLEFT", 258, -1)

local bottomleft = panel:CreateTexture(nil, "BACKGROUND")
bottomleft:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-General-BottomLeft]])
bottomleft:SetWidth(256) bottomleft:SetHeight(256)
bottomleft:SetPoint("TOPLEFT", 2, -257)

local bottomright = panel:CreateTexture(nil, "BACKGROUND")
bottomright:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-General-BottomRight]])
bottomright:SetWidth(128) bottomright:SetHeight(256)
bottomright:SetPoint("TOPLEFT", 258, -257)

local title = panel:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
title:SetText("Linken Log")
title:SetPoint("CENTER", 6, 232)


local portrait = panel:CreateTexture(nil, "ARTWORK")
portrait:SetWidth(60) portrait:SetHeight(60)
portrait:SetPoint("TOPLEFT", 7, -6)
SetPortraitTexture(portrait, "player")

panel:SetScript("OnEvent", function(self, event, unit) if unit == "player" then SetPortraitTexture(portrait, unit) end end)
panel:RegisterEvent("UNIT_PORTRAIT_UPDATE")


local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
close:SetPoint("CENTER", panel, "TOPRIGHT", -44, -25)
close:SetScript("OnClick", function() HideUIPanel(panel) end)


local lasticon
for _,spellid in pairs(crafts) do
	local name, _, texture = GetSpellInfo(spellid)

	local icon = CreateFrame("Button", nil, panel)
	icon:SetWidth(24) icon:SetHeight(24)
	icon:SetNormalTexture(texture)

	local back = icon:CreateTexture(nil, "BACKGROUND")
	back:SetTexture([[Interface\SpellBook\SpellBook-SkillLineTab]])
	back:SetTexCoord(0, 7/8, 0, 7/8)
	back:SetWidth(36*24/20) back:SetHeight(36*24/20)
	back:SetPoint("LEFT", -2, 0)

	if lasticon then
		icon:SetPoint("TOP", lasticon, "BOTTOM", 0, -16)
	else
		icon:SetPoint("TOPLEFT", panel, "TOPRIGHT", -33, -50)
	end
	lasticon = icon
end

local rows, lastbutt = {}
local NUMROWS = 22
for i=1,NUMROWS do
	local butt = CreateFrame("Button", nil, panel)
	butt:SetWidth(318) butt:SetHeight(16)
	if lastbutt then butt:SetPoint("TOP", lastbutt, "BOTTOM") else butt:SetPoint("TOPLEFT", 23, -77) end

	local name = butt:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	name:SetPoint("LEFT", 5, 0)
	butt.name = name

	local detail = butt:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	detail:SetPoint("LEFT", 100, 0)
	butt.detail = detail

	local time = butt:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	time:SetPoint("RIGHT", -5, 0)
	butt.time = time

	butt:SetScript("OnClick", function(self)
		local link = self.link:match("|H(trade:.+)|h.+|h|r")
		SetItemRef(link, self.link, "LeftButton")
	end)

	table.insert(rows, butt)
	lastbutt = butt
end

panel:SetScript("OnShow", function(self)
	local i, mypatch = 0, GetBuildInfo()
	for _,spellid in pairs(crafts) do
		local trade = GetSpellInfo(spellid)
		for name,val in pairs(db[trade]) do
			i = i + 1
			if i <= NUMROWS then
				local patch, timestamp, link = string.split("\t", val)
				local row = rows[i]
				local skill = link:match("|Htrade:%d+:(%d+):")
				row.name:SetText(name)
				row.detail:SetText(trade.." ("..skill..")")
				row.time:SetText((patch ~= mypatch and "|cffff0000" or "")..timestamp)
				row.link = val
				row:Show()
			end
		end
	end
	if i < NUMROWS then
		for j=(i+1),10 do rows[j]:Hide() end
	end
end)


-----------------------------
--      Slash Handler      --
-----------------------------

SLASH_LINKENLOG1 = "/linken"
SlashCmdList.LINKENLOG = function(msg)
	-- Do crap here
	ShowUIPanel(panel)
end


----------------------------------------
--      Quicklaunch registration      --
----------------------------------------

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:GetDataObjectByName("LinkenLog") or ldb:NewDataObject("LinkenLog", {type = "launcher", icon = "Interface\\Icons\\Spell_Nature_GroundingTotem"})
dataobj.OnClick = function() ShowUIPanel(panel) end
