BarNone = CreateFrame("Frame")

function BarNone:OnEvent(event, ...)
	self[event](self, event, ...)
end
BarNone:SetScript("OnEvent", BarNone.OnEvent)
BarNone:RegisterEvent("ADDON_LOADED")

function BarNone:ADDON_LOADED(event, addOnName)
	if addOnName == "BarNone" then
		BarNoneDB = BarNoneDB or {}
		self.db = BarNoneDB
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
				print("DEBUG: Initializing color defaults")
				
				-- Check each power type color
				for powerType, defaultColor in pairs(self.defaults.colors) do
					print("DEBUG:   Processing " .. powerType)
					-- Initialize if missing
					if not self.db.colors[powerType] then
						print("DEBUG:     Creating new color for " .. powerType)
						self.db.colors[powerType] = CopyTable(defaultColor)
					else
						print("DEBUG:     Checking existing color for " .. powerType)
						-- Make sure each color component is valid
						local color = self.db.colors[powerType]
						if type(color) ~= "table" or #color < 4 then
							-- Invalid format, reset to default
							print("DEBUG:     Invalid format, resetting to default")
							self.db.colors[powerType] = CopyTable(defaultColor)
						else
							-- Ensure each component is a valid number
							for i = 1, 4 do
								if type(color[i]) ~= "number" or color[i] < 0 or color[i] > 1 then
									print("DEBUG:     Invalid component " .. i .. ", resetting")
									color[i] = defaultColor[i]
								end
							end
						end
					end
				end
			end
		end

		local version, build, _, tocversion = GetBuildInfo()
		print(format("The current WoW build is %s (%d) and TOC is %d", version, build, tocversion))

		self:RegisterEvent("PLAYER_ENTERING_WORLD")

		self:InitializeOptions()
		self:UnregisterEvent(event)
	end
end

function BarNone:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
	print("|cff00ffffBarNone|r loaded. Type |cff00ff00/bn|r or |cff00ff00/barnone|r to open the options.")
end

-- Slash commands
SLASH_BARNONE1 = "/bn"
SLASH_BARNONE2 = "/barnone"
function SlashCmdList.BARNONE(msg, editBox)
	Settings.OpenToCategory(BarNone.panel_main.name)
end
