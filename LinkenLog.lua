
----------------------
--      Locals      --
----------------------

local L = setmetatable({}, {__index=function(t,i) return i end})
local db, Refresh, Resize

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
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("CHAT_MSG_GUILD")

	announce()

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

local mypatch = GetBuildInfo()
local function Save(name, sender, source, message, link)
	local timestamp = date("%m/%d %H:%M")
	db[name][sender] = string.join("\t", mypatch, timestamp, source, message, link)
	Resize()
	Refresh()
end

function f:CHAT_MSG_GUILD(event, message, sender, ...)
	if sender == GetUnitName("player", false) then return end
	local link, name = message:match("(|c[^|]+|Htrade:.+|h%[(%w+)%]|h|r)")
	if link then
		Save(name, sender, "Guild chat", message, link)
	end
end

function f:CHAT_MSG_ADDON(event, prefix, message, channel, sender, ...)
	if prefix ~= "linken" then return end
	local name = message:match("|Htrade:.+|h%[(.+)%]|h|r")
	Save(name, sender, "Addon channel", " ", message)
end


function f:CHAT_MSG_SYSTEM(event, msg)
	if string.find(msg, L["has come online"]) then announce() end
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

local function HideTooltip() GameTooltip:Hide() end
local function ShowTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText("Click and press Ctrl-C to copy")
end

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
	butt:SetScript("OnLeave", function() GameTooltip:Hide() end)
	butt:SetScript("OnEnter", function(self)
		if self.note ~= " " then
			GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
			GameTooltip:SetText(self.note)
		end
	end)

	table.insert(rows, butt)
	lastbutt = butt
end


local offset = 0
function Refresh()
	if not panel:IsVisible() then return end

	local i = 0
	for _,spellid in pairs(crafts) do
		local trade = GetSpellInfo(spellid)
		for name,val in pairs(db[trade]) do
			i = i + 1
			if (i-offset) > 0 and (i-offset) <= NUMROWS then
				local patch, timestamp, source, note, link = string.split("\t", val)
				local row = rows[i-offset]
				local skill = link:match("|Htrade:%d+:(%d+):")
				row.name:SetText(name)
				row.note = note
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
end

local orig = scroll:GetScript("OnValueChanged")
scroll:SetScript("OnValueChanged", function(self, newoffset, ...)
	offset = math.floor(newoffset)
	Refresh()
	return orig(self, offset, ...)
end)

local firstshow = true
function Resize()
	local i = 0
	for _,vals in pairs(db) do for name,val in pairs(vals) do i = i + 1 end end
	scroll:SetMinMaxValues(0, math.max(0, i-NUMROWS))
end
panel:SetScript("OnShow", function(self)
	Resize()
	if firstshow then scroll:SetValue(0); firstshow = nil end
	Refresh()
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
