
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
			SendAddonMessage("linken", tradelink, "GUILD")
		end
	end
end


-----------------------------
--      Event Handler      --
-----------------------------

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")


function f:ADDON_LOADED(event, addon)
	if addon:lower() ~= "linkenlog" then return end

	local factionrealm = UnitFactionGroup("player").. " ".. GetRealmName()

	LinkenLogDB = LinkenLogDB or {}
	LinkenLogDB[factionrealm] = LinkenLogDB[factionrealm] or {}
	db = LinkenLogDB[factionrealm]
	for _,spellid in pairs(crafts) do
		local name = GetSpellInfo(spellid)
		db[name] = db[name] or {}
	end

	LibStub("tekKonfig-AboutPanel").new(nil, "LinkenLog") -- Make first arg nil if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end


function f:PLAYER_LOGIN()
	self:RegisterEvent("CHAT_MSG_ADDON")

	announce()

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


function f:CHAT_MSG_ADDON(event, prefix, message, channel, sender, ...)
	if prefix ~= "linken" then return end
	local name = message:match("|Htrade:.+|h%[(%w+)%]|h|r")
	local timestamp = date("%m/%d %H:%M")
	local patch = GetBuildInfo()
	db[name][sender] = string.join("\t", patch, timestamp, "Addon channel", " ", message)
end


local panel = LibStub("tekPanel").new("LinkenLogFrame", "Linken Log")


--~ local lasticon
--~ for _,spellid in pairs(crafts) do
--~ 	local name, _, texture = GetSpellInfo(spellid)

--~ 	local icon = CreateFrame("Button", nil, panel)
--~ 	icon:SetWidth(24) icon:SetHeight(24)
--~ 	icon:SetNormalTexture(texture)

--~ 	local back = icon:CreateTexture(nil, "BACKGROUND")
--~ 	back:SetTexture([[Interface\SpellBook\SpellBook-SkillLineTab]])
--~ 	back:SetTexCoord(0, 7/8, 0, 7/8)
--~ 	back:SetWidth(36*24/20) back:SetHeight(36*24/20)
--~ 	back:SetPoint("LEFT", -2, 0)

--~ 	if lasticon then
--~ 		icon:SetPoint("TOP", lasticon, "BOTTOM", 0, -16)
--~ 	else
--~ 		icon:SetPoint("TOPLEFT", panel, "TOPRIGHT", -33, -50)
--~ 	end
--~ 	lasticon = icon
--~ end


local function OnClick(self)
	local patch, timestamp, source, note, tradelink = string.split("\t", self.link)
	local link = tradelink:match("|H(trade:.+)|h.+|h|r")
	SetItemRef(link, tradelink, "LeftButton")
end


local NUMROWS = 22
local SCROLLSTEP = math.floor(NUMROWS/3)
local scrollbox = CreateFrame("Frame", nil, panel)
scrollbox:SetPoint("TOPLEFT", 0, -78)
scrollbox:SetPoint("BOTTOMRIGHT", -43, 82)
local scroll = LibStub("tekKonfig-Scroll").new(scrollbox, 0, SCROLLSTEP)


local rows, lastbutt = {}
local function OnMouseWheel(self, val) scroll:SetValue(scroll:GetValue() - val*SCROLLSTEP) end
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
	time:SetPoint("RIGHT", -25, 0)
	butt.time = time

	butt:EnableMouseWheel(true)
	butt:SetScript("OnMouseWheel", OnMouseWheel)
	butt:SetScript("OnClick", OnClick)

	table.insert(rows, butt)
	lastbutt = butt
end


local orig = scroll:GetScript("OnValueChanged")
scroll:SetScript("OnValueChanged", function(self, offset, ...)
	offset = math.floor(offset)
	local i, mypatch = 0, GetBuildInfo()
	for _,spellid in pairs(crafts) do
		local trade = GetSpellInfo(spellid)
		for name,val in pairs(db[trade]) do
			i = i + 1
			if (i-offset) > 0 and (i-offset) <= NUMROWS then
				local patch, timestamp, source, note, link = string.split("\t", val)
				local row = rows[i-offset]
				local skill = link:match("|Htrade:%d+:(%d+):")
				row.name:SetText(name)
				row.detail:SetText(trade.." ("..skill..")")
				row.time:SetText((patch ~= mypatch and "|cffff0000" or "")..timestamp)
				row.link = val
				row:Show()
			end
		end
	end
	if (i-offset) < NUMROWS then
		for j=(i-offset+1),NUMROWS do rows[j]:Hide() end
	end

	return orig(self, offset, ...)
end)

local firstshow = true
panel:SetScript("OnShow", function(self)
	local i = 0
	for _,vals in pairs(db) do for name,val in pairs(vals) do i = i + 1 end end
	scroll:SetMinMaxValues(0, math.max(0, i-NUMROWS))
	if firstshow then scroll:SetValue(0); firstshow = nil end
end)


-----------------------------
--      Slash Handler      --
-----------------------------

SLASH_LINKENLOG1 = "/linken"
SlashCmdList.LINKENLOG = function(msg) ShowUIPanel(panel) end


----------------------------------------
--      Quicklaunch registration      --
----------------------------------------

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:GetDataObjectByName("LinkenLog") or ldb:NewDataObject("LinkenLog", {type = "launcher", icon = "Interface\\Icons\\Spell_Nature_GroundingTotem"})
dataobj.OnClick = SlashCmdList.LINKENLOG
