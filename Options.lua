BarNone.defaults = {
	charSpecific = false,
	showMessage = true,
	width = 150,
	height = 30,
	colors = {
		-- Power colors based on WoW's default resource colors
		mana = { 0.0, 0.5, 1.0, 1.0 }, -- Blue
		rage = { 1.0, 0.0, 0.0, 1.0 }, -- Red
		focus = { 1.0, 0.5, 0.25, 1.0 }, -- Orange
		energy = { 1.0, 1.0, 0.0, 1.0 }, -- Yellow
		runicPower = { 0.0, 0.82, 1.0, 1.0 }, -- Cyan
		astralPower = { 0.0, 0.4, 0.9, 1.0 }, -- Light Blue
		insanity = { 0.7, 0.4, 0.9, 1.0 }, -- Purple
		fury = { 0.788, 0.259, 0.992, 1.0 }, -- Purple
	},
}

-- #region Registers
local function RegisterMainPanel(panel)
	panel.category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
	panel.category.ID = panel.name
	Settings.RegisterAddOnCategory(panel.category)
	return panel.category
end

local function RegisterSubPanel(parentPanel, panel)
	panel.parent = parentPanel.name
	panel.category = Settings.RegisterCanvasLayoutSubcategory(parentPanel.category, panel, panel.name, panel.name)
	panel.category.ID = panel.name
	return panel.category
end
-- #endregion

-- #region Render helpers
function CreatePanelTitle(panel, titleText, anchor, yOffset)
	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	anchor = anchor or panel
	yOffset = yOffset or -16
	title:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, yOffset)
	title:SetText(titleText)
	return title
end

function AddHorizontalRule(panel, anchor, yOffset, width, color)
	local rule = panel:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(unpack(color or { 0.5, 0.5, 0.5, 1 })) -- Default: gray
	rule:SetHeight(1)
	rule:SetWidth(width or 350)
	rule:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset or -8)
	return rule
end

function BarNone:CreateCheckbox(option, label, parent, updateFunc)
	local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	cb.Text:SetText(label)
	local function UpdateOption(value)
		BarNoneDB[option] = value
		cb:SetChecked(value)
		if updateFunc then
			updateFunc(value)
		end
	end
	UpdateOption(BarNoneDB[option])

	cb:HookScript("OnClick", function(_, btn, down)
		UpdateOption(cb:GetChecked())
	end)

	EventRegistry:RegisterCallback("BarNone.OnReset", function()
		UpdateOption(BarNone.defaults[option])
	end, cb)

	return cb
end
-- #endregion

function BarNone:InitializeOptions()
	-- Helper function to dynamically add options offsets
	function AttachControl(element, anchorElement, yOffset)
		if anchorElement == self.panel_main then
			element:SetPoint("TOPLEFT", anchorElement, "TOPLEFT", 20, -20)
		else
			element:SetPoint("TOPLEFT", anchorElement, "BOTTOMLEFT", 0, yOffset)
		end
		return element
	end

	-- #region Main settings panel
	self.panel_main = CreateFrame("Frame")
	self.panel_main.name = "BarNone"

	-- #region Size settings
	local sizeTitle = CreatePanelTitle(self.panel_main, "Size")
	-- Bar width
	local width_slider = CreateFrame("Slider", nil, self.panel_main, "OptionsSliderTemplate")
	AttachControl(width_slider, sizeTitle, -30)
	width_slider:SetMinMaxValues(50, 1000)
	width_slider:SetValue(BarNoneDB.width)
	width_slider:SetValueStep(1)
	width_slider:SetWidth(200)
	width_slider.Text:SetText("Width: " .. BarNoneDB.width)
	width_slider.Low:SetText("50")
	width_slider.High:SetText("1000")
	width_slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value)
		BarNoneDB.width = value
		self.Text:SetText("Width: " .. value)
	end)

	-- Bar height
	local height_slider = CreateFrame("Slider", nil, self.panel_main, "OptionsSliderTemplate")
	AttachControl(height_slider, width_slider, -40)
	height_slider:SetMinMaxValues(10, 100)
	height_slider:SetValue(BarNoneDB.height)
	height_slider:SetValueStep(1)
	height_slider:SetWidth(200)
	height_slider.Text:SetText("Height: " .. BarNoneDB.height)
	height_slider.Low:SetText("10")
	height_slider.High:SetText("100")
	height_slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value)
		BarNoneDB.height = value
		self.Text:SetText("Height: " .. value)
	end)

	-- Reset all size options
	local btn_reset = CreateFrame("Button", nil, self.panel_main, "UIPanelButtonTemplate")
	AttachControl(btn_reset, height_slider, -40)
	btn_reset:SetText("Reset Sizes")
	btn_reset:SetWidth(150)
	btn_reset:SetScript("OnClick", function()
		local opts = { "width", "height" }
		-- Reset each option in the list to its default value
		for _, opt in ipairs(opts) do
			BarNoneDB[opt] = self.defaults[opt]
		end

		-- Update the UI to reflect the new values
		width_slider:SetValue(BarNoneDB.width)
		height_slider:SetValue(BarNoneDB.height)

		-- Notify the user
		print("BarNone: Size settings have been reset to defaults.")
	end)
	-- #endregion

	-- #region Power options
	local powerHr = AddHorizontalRule(self.panel_main, btn_reset, -30)
	local powerTitle = CreatePanelTitle(self.panel_main, "Power", powerHr, -20)

	RegisterMainPanel(self.panel_main)
	-- #endregion

	-- #region Power Colors subpanel
	self.colorSwatches = {}
	local panel_colors = CreateFrame("Frame")
	panel_colors.name = "Power Colors"
	RegisterSubPanel(self.panel_main, panel_colors)

	-- Add a title
	local colors_title = CreatePanelTitle(panel_colors, "Power Type Color Overrides")
	-- Add a description
	local colors_desc = panel_colors:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	colors_desc:SetPoint("TOPLEFT", colors_title, "BOTTOMLEFT", 0, -10)
	colors_desc:SetText("Customize the color for each power type. Click the colored box to select a new color.")

	-- Helper function to create color pickers
	local function CreateColorPicker(powerType, label, previousElement)
		local frame = CreateFrame("Frame", nil, panel_colors)
		frame:SetSize(300, 26)
		-- Position relative to the previous element
		if previousElement == colors_desc then
			frame:SetPoint("TOPLEFT", previousElement, "BOTTOMLEFT", 0, -16)
		else
			frame:SetPoint("TOPLEFT", previousElement, "BOTTOMLEFT", 0, -10)
		end

		-- Label
		local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		text:SetPoint("LEFT", frame, "LEFT", 0, 0)
		text:SetText(label)
		text:SetWidth(120)

		-- Create color swatch button
		local swatch = CreateFrame("Button", nil, frame, "ColorSwatchTemplate")
		swatch:SetPoint("LEFT", text, "RIGHT", 10, 0)
		swatch:SetSize(32, 32)

		if not swatch:GetNormalTexture() then
			swatch:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
		end
		local swatchBg = swatch:GetNormalTexture()

		local color = BarNoneDB.colors[powerType]
		local defaultColor = self.defaults.colors[powerType] or { 1, 1, 1, 1 }

		local r, g, b, a = unpack(defaultColor) -- Default to the power's default color
		if color and type(color) == "table" then
			r = color[1] or defaultColor[1]
			g = color[2] or defaultColor[2]
			b = color[3] or defaultColor[3]
			a = color[4] or defaultColor[4]
		end

		swatchBg:SetVertexColor(r, g, b)
		self.colorSwatches[powerType] = swatch -- Store swatch for refreshing render

		-- Color picker function
		swatch:SetScript("OnClick", function()
			-- Safety check - if we still don't have valid color data, create it now
			if not BarNoneDB.colors[powerType] or type(BarNoneDB.colors[powerType]) ~= "table" then
				if self.defaults.colors[powerType] then
					BarNoneDB.colors[powerType] = CopyTable(self.defaults.colors[powerType])
					print("Restored default color for " .. powerType)
				else
					BarNoneDB.colors[powerType] = { 1, 1, 1, 1 } -- Fallback to white only if no default exists
				end
			end

			-- Get the color values directly, not through unpack which can fail
			r = tonumber(BarNoneDB.colors[powerType][1]) or 1
			g = tonumber(BarNoneDB.colors[powerType][2]) or 1
			b = tonumber(BarNoneDB.colors[powerType][3]) or 1
			a = tonumber(BarNoneDB.colors[powerType][4]) or 1

			-- Add a highlight effect when clicked
			-- Make sure we don't exceed valid color values (0-1 range)
			local hr = math.min(r + 0.1, 1)
			local hg = math.min(g + 0.1, 1)
			local hb = math.min(b + 0.1, 1)

			-- Apply highlight and then restore
			swatch:GetNormalTexture():SetVertexColor(hr, hg, hb)
			C_Timer.After(0.1, function()
				swatch:GetNormalTexture():SetVertexColor(r, g, b)
			end)

			-- Define our color callback function
			local function myColorCallback(restore)
				local newR, newG, newB, newA

				if restore then
					return
				end

				newR, newG, newB, newA = 1, 1, 1, 1

				newR, newG, newB = ColorPickerFrame:GetColorRGB()
				newA = OpacitySliderFrame and OpacitySliderFrame:GetValue() or 1.0

				newR = math.max(0, math.min(1, newR))
				newG = math.max(0, math.min(1, newG))
				newB = math.max(0, math.min(1, newB))
				newA = math.max(0, math.min(1, newA))

				swatchBg:SetVertexColor(newR, newG, newB)
				BarNoneDB.colors[powerType] = { newR, newG, newB, newA }
			end

			ColorPickerFrame.hasOpacity = true
			ColorPickerFrame.opacity = a

			-- Store current values for the cancel function
			-- Create a new table with explicit values, not references
			ColorPickerFrame.previousValues = {
				tonumber(r) or 1,
				tonumber(g) or 1,
				tonumber(b) or 1,
				tonumber(a) or 1,
			}

			ColorPickerFrame.func = myColorCallback
			ColorPickerFrame.opacityFunc = myColorCallback
			ColorPickerFrame.cancelFunc = myColorCallback

			-- Set the current color and show the frame
			-- Safety check to make sure colors are valid
			if not r or not g or not b or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
				print("BarNone: Error - Invalid color values for " .. powerType .. ". Using default color.")
				-- Set to white as fallback
				r, g, b, a = 1, 1, 1, 1
				self.db.colors[powerType] = { 1, 1, 1, 1 }
			end

			r = math.max(0, math.min(1, tonumber(r) or 1))
			g = math.max(0, math.min(1, tonumber(g) or 1))
			b = math.max(0, math.min(1, tonumber(b) or 1))
			a = math.max(0, math.min(1, tonumber(a) or 1))

			local info = {}
			info.r, info.g, info.b, info.a = r, g, b, a

			local originalColor = { r, g, b, a }

			info.swatchFunc = myColorCallback
			info.opacityFunc = myColorCallback

			info.cancelFunc = function()
				BarNoneDB.colors[powerType] = CopyTable(originalColor)
				swatchBg:SetVertexColor(unpack(originalColor))
				print("Color change cancelled.")
			end

			info.opacity = a
			info.previousValues = originalColor

			ColorPickerFrame:SetupColorPickerAndShow(info)
		end)

		local reset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		reset:SetPoint("LEFT", swatch, "RIGHT", 25, 0)
		reset:SetText("Reset")
		reset:SetWidth(50)
		reset:SetHeight(20)
		reset:SetScript("OnClick", function()
			local defaultColor = self.defaults.colors[powerType]
			if defaultColor and type(defaultColor) == "table" and #defaultColor >= 4 then
				-- Safely get color values with fallbacks
				local r = tonumber(defaultColor[1])
				local g = tonumber(defaultColor[2]) or 1
				local b = tonumber(defaultColor[3]) or 1
				local a = tonumber(defaultColor[4]) or 1

				-- Copy the default color
				BarNoneDB.colors[powerType] = { r, g, b, a }

				-- Update the swatch
				if swatch:GetNormalTexture() then
					swatch:GetNormalTexture():SetVertexColor(r, g, b)
				end
			else
				local fallbackColor = { 1, 1, 1, 1 } -- White as ultimate fallback

				-- Common power type colors in WoW
				if powerType == "mana" then
					fallbackColor = { 0, 0.5, 1.0, 1.0 } -- Blue
				elseif powerType == "rage" then
					fallbackColor = { 1.0, 0, 0, 1.0 } -- Red
				elseif powerType == "energy" then
					fallbackColor = { 1.0, 1.0, 0, 1.0 } -- Yellow
				elseif powerType == "focus" then
					fallbackColor = { 1.0, 0.5, 0.25, 1.0 } -- Orange
				elseif powerType == "runicPower" then
					fallbackColor = { 0, 0.82, 1.0, 1.0 } -- Cyan
				end

				BarNoneDB.colors[powerType] = fallbackColor
				if swatch:GetNormalTexture() then
					swatch:GetNormalTexture():SetVertexColor(unpack(fallbackColor))
				end
				-- Notify about the fallback
				print("BarNone: Default color for " .. powerType .. " not found or invalid. Using fallback color.")
			end
		end)

		return frame
	end

	-- Create color pickers for each power type
	local manaColor = CreateColorPicker("mana", "Mana:", colors_desc)
	local rageColor = CreateColorPicker("rage", "Rage:", manaColor)
	local focusColor = CreateColorPicker("focus", "Focus:", rageColor)
	local energyColor = CreateColorPicker("energy", "Energy:", focusColor)
	local astralColor = CreateColorPicker("astralPower", "Astral Power:", energyColor)
	local insanityColor = CreateColorPicker("insanity", "Insanity:", astralColor)
	local runicColor = CreateColorPicker("runicPower", "Runic Power:", insanityColor)
	local furyColor = CreateColorPicker("fury", "Fury:", runicColor)

	-- Create a reset all button
	local resetAllColors = CreateFrame("Button", nil, panel_colors, "UIPanelButtonTemplate")
	resetAllColors:SetPoint("TOPLEFT", furyColor, "BOTTOMLEFT", 0, -20)
	resetAllColors:SetText("Reset All Colors")
	resetAllColors:SetWidth(150)
	resetAllColors:SetScript("OnClick", function()
		BarNoneDB.colors = CopyTable(self.defaults.colors)
		-- Refresh all swatches
		for powerType, swatch in pairs(self.colorSwatches) do
			local color = BarNoneDB.colors[powerType] or { 1, 1, 1, 1 }
			if swatch and swatch:GetNormalTexture() then
				swatch:GetNormalTexture():SetVertexColor(color[1], color[2], color[3])
			end
		end
	end)
	-- #endregion

	-- #region Misc sub panel
	local panel_misc = CreateFrame("Frame")
	panel_misc.name = "Misc"
	RegisterSubPanel(self.panel_main, panel_misc)

	-- Add a title
	local miscTitle = CreatePanelTitle(panel_misc, "Miscellaneous Settings")

	local charSpecific = self:CreateCheckbox("charSpecific", "Character specific", panel_misc)
	charSpecific:SetPoint("TOPLEFT", miscTitle, "BOTTOMLEFT", 0, -16)

	local showMessage = self:CreateCheckbox("showMessage", "Show command usage message on login", panel_misc)
	AttachControl(showMessage, charSpecific, -20)
	-- #endregion
end

-- a bit more efficient to register/unregister the event when it fires a lot
function BarNone:UpdateEvent(value, event)
	if value then
		self:RegisterEvent(event)
	else
		self:UnregisterEvent(event)
	end
end
