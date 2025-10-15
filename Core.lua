BarNone = CreateFrame("Frame")
BarNonePowerBarBorder = CreateFrame("Frame", "BarNonePowerBarBorder", UIParent, "BackdropTemplate")
BarNonePowerBarBorder:SetPoint("CENTER")
BarNonePowerBarBorder:SetFrameStrata("MEDIUM")
BarNonePowerBar = CreateFrame("StatusBar", "BarNonePowerBar", BarNonePowerBarBorder)
BarNonePowerBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
BarNonePowerBar:SetStatusBarColor(0, 1, 0)
BarNonePowerBar:SetMinMaxValues(0, 100)
BarNonePowerBar:SetValue(50)
BarNonePowerBar:SetFrameStrata("MEDIUM")

function BarNone:OnEvent(event, ...)
	self[event](self, event, ...)
end
BarNone:SetScript("OnEvent", BarNone.OnEvent)
BarNone:RegisterEvent("ADDON_LOADED")
BarNone:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
BarNone:RegisterEvent("UNIT_DISPLAYPOWER")

function BarNone:ADDON_LOADED(event, addOnName)
	if addOnName == "BarNone" then
		BarNoneDB = BarNoneDB or {}
		self.db = BarNoneDB
		-- TODO refactor this, i hate it, no way LUA is bad like this
		for k, v in pairs(self.defaults) do
			-- For simple values, just copy if missing
			if k ~= "colors" then
				if self.db[k] == nil then
					self.db[k] = v
				end
			else
				-- For colors, we need deeper checking
				self.db.colors = self.db.colors or {}

				-- Debug output for colors initialization

				-- Check each power type color
				for powerType, defaultColor in pairs(self.defaults.colors) do
					-- Initialize if missing
					if not self.db.colors[powerType] then
						self.db.colors[powerType] = CopyTable(defaultColor)
					else
						-- Make sure each color component is valid
						local color = self.db.colors[powerType]
						if type(color) ~= "table" or #color < 4 then
							-- Invalid format, reset to default
							self.db.colors[powerType] = CopyTable(defaultColor)
						else
							-- Ensure each component is a valid number
							for i = 1, 4 do
								if type(color[i]) ~= "number" or color[i] < 0 or color[i] > 1 then
									color[i] = defaultColor[i]
								end
							end
						end
					end
				end
			end
		end

		self:RegisterEvent("PLAYER_ENTERING_WORLD")

		self:InitializeOptions()
		self:UnregisterEvent(event)
	end
end

function BarNone:PLAYER_SPECIALIZATION_CHANGED(_, unit)
	if unit == "player" then
		self:UpdateBarColor()
	end
end

function BarNone:UNIT_DISPLAYPOWER(_, unit)
	if unit == "player" then
		self:UpdateBarColor()
	end
end

function BarNone:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
	print("|cff00ffffBarNone|r loaded. Type |cff00ff00/bn|r or |cff00ff00/barnone|r to open the options.")
	local width = self.db.width or 200
	local height = self.db.height or 20

	-- Border settings
	local edgeSize = math.max(8, math.floor(height * 0.4))
	local inset = math.max(2, math.floor(edgeSize * 0.25))

	BarNonePowerBarBorder:SetSize(width, height)
	BarNonePowerBarBorder:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = edgeSize,
		insets = { left = inset, right = inset, top = inset, bottom = inset },
	})
	BarNonePowerBarBorder:SetBackdropColor(0, 0, 0, 0.8)
	BarNonePowerBarBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
	BarNonePowerBarBorder:Show()

	-- Status bar fits inside the border
	BarNonePowerBar:ClearAllPoints()
	BarNonePowerBar:SetPoint("TOPLEFT", BarNonePowerBarBorder, "TOPLEFT", edgeSize * 0.3, -edgeSize * 0.3)
	BarNonePowerBar:SetPoint("BOTTOMRIGHT", BarNonePowerBarBorder, "BOTTOMRIGHT", -edgeSize * 0.3, edgeSize * 0.3)
	self:UpdateBarColor()
	BarNonePowerBar:Show()
end

-- Returns the player's current primary power type (e.g., "MANA", "RAGE", "ENERGY")
local function GetPlayerPowerType()
	local _, powerToken, _, _, _ = UnitPowerType("player")
	return powerToken
end

function BarNone:UpdateBarColor()
	local powerType = GetPlayerPowerType()
	local color = self.db.colors and self.db.colors[powerType]
	if color then
		BarNonePowerBar:SetStatusBarColor(unpack(color))
	else
		-- fallback color
		BarNonePowerBar:SetStatusBarColor(0, 1, 0)
	end
end

-- Slash commands
SLASH_BARNONE1 = "/bn"
SLASH_BARNONE2 = "/barnone"
function SlashCmdList.BARNONE(msg, editBox)
	Settings.OpenToCategory(BarNone.panel_main.name)
end
