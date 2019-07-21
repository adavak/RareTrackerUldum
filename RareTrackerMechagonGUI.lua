local _, data = ...

local RTM = data.RTM

local entity_name_width = 208
local entity_status_width = 50 
local frame_padding = 4
local favorite_rares_width = 10

local shard_id_frame_height = 16

background_opacity = 0.4
front_opacity = 0.6

-- ####################################################################
-- ##                              GUI                               ##
-- ####################################################################

function RTM:InitializeShardNumberFrame()
	local f = CreateFrame("Frame", "RTM.shard_id_frame", self)
	f:SetSize(entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width, shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.status_text = f:CreateFontString(nil, nil, "GameFontNormal")
	f.status_text:SetPoint("TOPLEFT", 10 + 2 * favorite_rares_width + 2 * frame_padding, -3)
	f.status_text:SetText("Shard ID: Unknown")
	f:SetPoint("TOPLEFT", self, frame_padding, -frame_padding)
	
	return f
end

function RTM:InitializeFavoriteMarkerFrame()
	local f = CreateFrame("Frame", "RTM.RTMDB.favorite_rares_frame", self)
	f:SetSize(favorite_rares_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	
	f.checkboxes = {}
	local height_offset = -(2 * frame_padding + shard_id_frame_height)
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		f.checkboxes[npc_id] = CreateFrame("CheckButton", "RTM.shard_id_frame.checkbox["..i.."]", f)
		f.checkboxes[npc_id]:SetSize(10, 10)
		local texture = f.checkboxes[npc_id]:CreateTexture(nil, "BACKGROUND")
		texture:SetColorTexture(0, 0, 0, front_opacity)
		texture:SetAllPoints(f.checkboxes[npc_id])
		f.checkboxes[npc_id].texture = texture
		f.checkboxes[npc_id]:SetPoint("TOPLEFT", 1, -(i - 1) * 12 - 5)
		
		-- Add an action listener.
		f.checkboxes[npc_id]:SetScript("OnClick", 
			function()
				if RTMDB.favorite_rares[npc_id] then
					RTMDB.favorite_rares[npc_id] = nil
					f.checkboxes[npc_id].texture:SetColorTexture(0, 0, 0, front_opacity)
				else
					RTMDB.favorite_rares[npc_id] = true
					f.checkboxes[npc_id].texture:SetColorTexture(0, 1, 0, 1)
				end
			end
		);
	end
	
	f:SetPoint("TOPLEFT", self, frame_padding, height_offset)
	return f
end

function RTM:InitializeAliveMarkerFrame()
	local f = CreateFrame("Frame", "RTM.alive_marker_frame", self)
	f:SetSize(favorite_rares_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	
	f.checkboxes = {}
	local height_offset = -(2 * frame_padding + shard_id_frame_height)
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		f.checkboxes[npc_id] = CreateFrame("Button", "RTM.shard_id_frame.checkbox["..i.."]", f)
		
		f.checkboxes[npc_id]:SetSize(10, 10)
		local texture = f.checkboxes[npc_id]:CreateTexture(nil, "BACKGROUND")
		texture:SetColorTexture(0, 0, 0, front_opacity)
		texture:SetAllPoints(f.checkboxes[npc_id])
		f.checkboxes[npc_id].texture = texture
		f.checkboxes[npc_id]:SetPoint("TOPLEFT", 1, -(i - 1) * 12 - 5)
		f.checkboxes[npc_id]:RegisterForClicks("LeftButtonDown", "RightButtonDown")
		
		-- Add an action listener.
		f.checkboxes[npc_id]:SetScript("OnClick", 
			function(self, button, down)
				local name = RTM.rare_names[npc_id]
				local health = RTM.current_health[npc_id]
				local last_death = RTM.last_recorded_death[npc_id]
				local loc = RTM.current_coordinates[npc_id]
				
				if button == "LeftButton" then
					-- First, determine the target of our message.
					local target = nil
					
					if IsLeftControlKeyDown() or IsRightControlKeyDown() then
						if UnitInRaid("player") then
							target = "RAID"
						else
							target = "PARTY"
						end
					elseif IsLeftAltKeyDown() or IsRightAltKeyDown() then
						target = "SAY"
					else
						target = "CHANNEL"
					end
				
					if RTM.current_health[npc_id] then
						-- SendChatMessage
						if loc then
							SendChatMessage(string.format("<RTM> %s (%s%%) seen at ~(%.2f, %.2f)", name, health, loc.x, loc.y), target, nil, 1)
						else 
							SendChatMessage(string.format("<RTM> %s (%s%%) seen at ~(N/A)", name, health), target, nil, 1)
						end
					elseif RTM.last_recorded_death[npc_id] ~= nil then
						if GetServerTime() - last_death < 60 then
							SendChatMessage(string.format("<RTM> %s has died", name, GetServerTime() - last_death), target, nil, 1)
						else
							SendChatMessage(string.format("<RTM> %s was last seen ~%s minutes ago", name, math.floor((GetServerTime() - last_death) / 60)), target, nil, 1)
						end
					elseif RTM.is_alive[npc_id] then
						if loc then
							SendChatMessage(string.format("<RTM> %s seen alive, vignette at ~(%.2f, %.2f)", name, loc.x, loc.y), target, nil, 1)
						else
							SendChatMessage(string.format("<RTM> %s seen alive (vignette)", name), target, nil, 1)
						end
					end
				else
					-- does the user have tom tom? if so, add a waypoint if it exists.
					if TomTom ~= nil and loc then
						RTM.waypoints[npc_id] = TomTom:AddWaypointToCurrentZone(loc.x, loc.y, name)
					end
				end
			end
		);
	end
	
	f:SetPoint("TOPLEFT", self, 2 * frame_padding + favorite_rares_width, height_offset)
	return f
end

function RTM:InitializeInterfaceEntityNameFrame()
	local f = CreateFrame("Frame", "RTM.entity_name_frame", self)
	f:SetSize(entity_name_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.strings = {}
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		f.strings[npc_id] = f:CreateFontString(nil, nil, "GameFontNormal")
		f.strings[npc_id]:SetJustifyH("LEFT")
		f.strings[npc_id]:SetJustifyV("TOP")
		f.strings[npc_id]:SetPoint("TOPLEFT", 10, -(i - 1) * 12 - 4)
		f.strings[npc_id]:SetText(RTM.rare_names[npc_id])
	end
	
	f:SetPoint("TOPLEFT", self, 3 * frame_padding + 2 * favorite_rares_width, -(2 * frame_padding + shard_id_frame_height))
	return f
end

function RTM:InitializeInterfaceEntityStatusFrame()
	local f = CreateFrame("Frame", "RTM.entity_status_frame", self)
	f:SetSize(entity_status_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.strings = {}
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		f.strings[npc_id] = f:CreateFontString(nil, nil, "GameFontNormal")
		f.strings[npc_id]:SetPoint("TOP", 0, -(i - 1) * 12 - 4)
		f.strings[npc_id]:SetText("--")
		f.strings[npc_id]:SetJustifyH("LEFT")
		f.strings[npc_id]:SetJustifyV("TOP")
	end
	
	f:SetPoint("TOPRIGHT", self, -frame_padding, -(2 * frame_padding + shard_id_frame_height))
	return f
end

function RTM:UpdateStatus(npc_id)
	local status_text_frame = RTM.entity_status_frame.strings[npc_id]
	local alive_status_frame = RTM.alive_marker_frame.checkboxes[npc_id]

	if RTM.current_health[npc_id] then
		status_text_frame:SetText(RTM.current_health[npc_id].."%")
		alive_status_frame.texture:SetColorTexture(0, 1, 0, 1)
	elseif RTM.last_recorded_death[npc_id] ~= nil then
		local last_death = RTM.last_recorded_death[npc_id]
		status_text_frame:SetText(math.floor((GetServerTime() - last_death) / 60).."m")
		alive_status_frame.texture:SetColorTexture(0, 0, 1, front_opacity)
	elseif RTM.is_alive[npc_id] then
		status_text_frame:SetText("N/A")
		alive_status_frame.texture:SetColorTexture(0, 1, 0, 1)
	else
		status_text_frame:SetText("--")
		alive_status_frame.texture:SetColorTexture(0, 0, 0, front_opacity)
	end
end

function RTM:UpdateShardNumber(shard_number)
	if shard_number then
		RTM.shard_id_frame.status_text:SetText("Shard ID: "..(shard_number + 42))
	else
		RTM.shard_id_frame.status_text:SetText("Shard ID: Unknown")
	end
end

function RTM:CorrectFavoriteMarks()
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		
		if RTMDB.favorite_rares[npc_id] then
			self.favorite_rares_frame.checkboxes[npc_id].texture:SetColorTexture(0, 1, 0, 1)
		end
	end
end

function RTM:UpdateDailyKillMark(npc_id)
	if not RTM.completion_quest_ids[npc_id] then 
		return 
	end
	
	-- Multiple NPCs might share the same quest id.
	local completion_quest_id = RTM.completion_quest_ids[npc_id]
	local npc_ids = RTM.completion_quest_inverse[completion_quest_id]
	
	for key, npc_id in pairs(npc_ids) do
		if RTM.completion_quest_ids[npc_id] and IsQuestFlaggedCompleted(RTM.completion_quest_ids[npc_id]) then
			self.entity_name_frame.strings[npc_id]:SetText(RTM.rare_names[npc_id])
			self.entity_name_frame.strings[npc_id]:SetFontObject("GameFontRed")
		else
			self.entity_name_frame.strings[npc_id]:SetText(RTM.rare_names[npc_id])
			self.entity_name_frame.strings[npc_id]:SetFontObject("GameFontNormal")
		end
	end
end

function RTM:UpdateAllDailyKillMarks()
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		self:UpdateDailyKillMark(npc_id)
	end
end

function RTM:InitializeFavoriteIconFrame(f)
	f.favorite_icon = CreateFrame("Frame", "RTM.favorite_icon", f)
	f.favorite_icon:SetSize(10, 10)
	f.favorite_icon:SetPoint("TOPLEFT", f, frame_padding + 1, -(frame_padding + 3))

	f.favorite_icon.texture = f.favorite_icon:CreateTexture(nil, "OVERLAY")
	f.favorite_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerMechagon\\Icons\\Favorite.tga")
	f.favorite_icon.texture:SetSize(10, 10)
	f.favorite_icon.texture:SetPoint("CENTER", f.favorite_icon)
	
	f.favorite_icon.tooltip = CreateFrame("Frame", nil, UIParent)
	f.favorite_icon.tooltip:SetSize(300, 18)
	
	local texture = f.favorite_icon.tooltip:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.favorite_icon.tooltip)
	f.favorite_icon.tooltip.texture = texture
	f.favorite_icon.tooltip:SetPoint("TOPLEFT", f, 0, 19)
	f.favorite_icon.tooltip:Hide()
	
	f.favorite_icon.tooltip.text = f.favorite_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.favorite_icon.tooltip.text:SetJustifyH("LEFT")
	f.favorite_icon.tooltip.text:SetJustifyV("TOP")
	f.favorite_icon.tooltip.text:SetPoint("TOPLEFT", f.favorite_icon.tooltip, 5, -3)
	f.favorite_icon.tooltip.text:SetText("Click on the squares to add rares to your favorites.")
	
	f.favorite_icon:SetScript("OnEnter", 
		function(self)
			self.tooltip:Show()
		end
	);
	
	f.favorite_icon:SetScript("OnLeave", 
		function(self)
			self.tooltip:Hide()
		end
	);
end

function RTM:InitializeAnnounceIconFrame(f)
	f.broadcast_icon = CreateFrame("Frame", "RTM.broadcast_icon", f)
	f.broadcast_icon:SetSize(10, 10)
	f.broadcast_icon:SetPoint("TOPLEFT", f, 2 * frame_padding + favorite_rares_width + 1, -(frame_padding + 3))

	f.broadcast_icon.texture = f.broadcast_icon:CreateTexture(nil, "OVERLAY")
	f.broadcast_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerMechagon\\Icons\\Broadcast.tga")
	f.broadcast_icon.texture:SetSize(10, 10)
	f.broadcast_icon.texture:SetPoint("CENTER", f.broadcast_icon)
	f.broadcast_icon.icon_state = false
	
	f.broadcast_icon.tooltip = CreateFrame("Frame", nil, UIParent)
	f.broadcast_icon.tooltip:SetSize(273, 68)
	
	local texture = f.broadcast_icon.tooltip:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.broadcast_icon.tooltip)
	f.broadcast_icon.tooltip.texture = texture
	f.broadcast_icon.tooltip:SetPoint("TOPLEFT", f, 0, 69)
	f.broadcast_icon.tooltip:Hide()
	
	f.broadcast_icon.tooltip.text1 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text1:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text1:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text1:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -3)
	f.broadcast_icon.tooltip.text1:SetText("Click on the squares to announce rare timers.")
	
	f.broadcast_icon.tooltip.text2 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text2:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text2:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text2:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -15)
	f.broadcast_icon.tooltip.text2:SetText("Left click: report to general chat")
	
	f.broadcast_icon.tooltip.text3 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text3:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text3:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text3:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -27)
	f.broadcast_icon.tooltip.text3:SetText("Control-left click: report to party/raid chat")
	
	f.broadcast_icon.tooltip.text4 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text4:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text4:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text4:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -39)
	f.broadcast_icon.tooltip.text4:SetText("Alt-left click: report to say")
	  
	f.broadcast_icon.tooltip.text5 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text5:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text5:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text5:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -51)
	f.broadcast_icon.tooltip.text5:SetText("Right click: set waypoint if available")
	
	f.broadcast_icon:SetScript("OnEnter", 
		function(self)
			self.tooltip:Show()
		end
	);
	
	f.broadcast_icon:SetScript("OnLeave", 
		function(self)
			self.tooltip:Hide()
		end
	);
end


function RTM:InitializeInterface()
	self:SetSize(entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding, shard_id_frame_height + 3 * frame_padding + #RTM.rare_ids * 12 + 8)
	local texture = self:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, background_opacity)
	texture:SetAllPoints(self)
	self.texture = texture
	self:SetPoint("CENTER")
	
	-- Create a sub-frame for the entity names.
	self.shard_id_frame = self:InitializeShardNumberFrame()
	self.favorite_rares_frame = self:InitializeFavoriteMarkerFrame()
	self.alive_marker_frame = self:InitializeAliveMarkerFrame()
	self.entity_name_frame = self:InitializeInterfaceEntityNameFrame()
	self.entity_status_frame = self:InitializeInterfaceEntityStatusFrame()

	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	
	-- Add icons for the favorite and broadcast columns.
	RTM:InitializeFavoriteIconFrame(self)
	RTM:InitializeAnnounceIconFrame(self)
	
	-- Create a reset button.
	self.reload_button = CreateFrame("Button", "RTM.reload_button", self)
	self.reload_button:SetSize(10, 10)
	self.reload_button:SetPoint("TOPRIGHT", self, -2 * frame_padding, -(frame_padding + 3))

	self.reload_button.texture = self.reload_button:CreateTexture(nil, "OVERLAY")
	self.reload_button.texture:SetTexture("Interface\\AddOns\\RareTrackerMechagon\\Icons\\Reload.tga")
	self.reload_button.texture:SetSize(10, 10)
	self.reload_button.texture:SetPoint("CENTER", self.reload_button)
	
	self.reload_button:SetScript("OnClick", 
		function()
			if RTM.current_shard_id then
				print("<RTM> Resetting current rare timers and requesting up-to-date data.")
				RTM.is_alive = {}
				RTM.current_health = {}
				RTM.last_recorded_death = {}
				RTM.recorded_entity_death_ids = {}
				RTM.current_coordinates = {}
				RTM.reported_spawn_uids = {}
				RTM.reported_vignettes = {}
				
				-- Reset the cache.
				RTMDB.previous_records[RTM.current_shard_id] = nil
				
				-- Re-register your arrival in the shard.
				RTM:RegisterArrival(RTM.current_shard_id)
			else
				print("<RTM> Please target a non-player entity prior to reloading, such that the addon can determine the current shard id.")
			end
		end
	);
	
	self:Hide()
end

RTM:InitializeInterface()

-- ####################################################################
-- ##                       Options Interface                        ##
-- ####################################################################



-- Options:
-- Select warning sound
-- Reset Favorites
-- Show/hide minimap icon
-- Enable debug prints

-- The provided sound options.
local sound_options = {}
sound_options[''] = -1
sound_options["Rubber Ducky"] = 566121
sound_options["Cartoon FX"] = 566543
sound_options["Explosion"] = 566982
sound_options["Shing!"] = 566240
sound_options["Wham!"] = 566946
sound_options["Simon Chime"] = 566076
sound_options["War Drums"] = 567275
sound_options["Scourge Horn"] = 567386
sound_options["Pygmy Drums"] = 566508
sound_options["Cheer"] = 567283
sound_options["Humm"] = 569518
sound_options["Short Circuit"] = 568975
sound_options["Fel Portal"] = 569215
sound_options["Fel Nova"] = 568582
sound_options["PVP Flag"] = 569200
sound_options["Beware!"] = 543587
sound_options["Laugh"] = 564859
sound_options["Not Prepared"] = 552503
sound_options["I am Unleashed"] = 554554
sound_options["I see you"] = 554236

local sound_options_inverse = {}
for key, value in pairs(sound_options) do
	sound_options_inverse[value] = key
end

function RTM:IntializeSoundSelectionMenu(parent_frame)
	local f = CreateFrame("frame", "RTM.options_panel.sound_selection", parent_frame, "UIDropDownMenuTemplate")
	UIDropDownMenu_SetWidth(f, 140)
	UIDropDownMenu_SetText(f, sound_options_inverse[RTMDB.selected_sound_number])
	
	f.onClick = function(self, sound_id, arg2, checked)
		RTMDB.selected_sound_number = sound_id
		UIDropDownMenu_SetText(f, sound_options_inverse[RTMDB.selected_sound_number])
		PlaySoundFile(RTMDB.selected_sound_number)
	end
	
	f.initialize = function(self, level, menuList)
		local info = UIDropDownMenu_CreateInfo()
		
		for key, value in pairs(sound_options) do
			info.text = key
			info.arg1 = value
			info.func = f.onClick
			info.menuList = key
			info.checked = RTMDB.selected_sound_number == value
			UIDropDownMenu_AddButton(info)
		end
	end
	
	f.label = f:CreateFontString(nil, "BORDER", "GameFontNormal")
	f.label:SetJustifyH("LEFT")
	f.label:SetText("Favorite sound alert")
	f.label:SetPoint("TOPLEFT", parent_frame)
	
	f:SetPoint("TOPLEFT", f.label, -20, -13)
	
	return f
end

function RTM:IntializeMinimapCheckbox(parent_frame)
	local f = CreateFrame("CheckButton", "RTM.options_panel.minimap_checkbox", parent_frame, "ChatConfigCheckButtonTemplate");
	getglobal(f:GetName() .. 'Text'):SetText(" Show minimap icon");
	f.tooltip = "Show or hide the minimap button.";
	f:SetScript("OnClick", 
		function()
			local zone_id = C_Map.GetBestMapForUnit("player")
		
			RTMDB.minimap_icon_enabled = not RTMDB.minimap_icon_enabled
			if not RTMDB.minimap_icon_enabled then
				RTM.icon:Hide("RTM_icon")
			elseif RTM.target_zones[C_Map.GetBestMapForUnit("player")] then
				RTM.icon:Show("RTM_icon")
			end
		end
	);
	f:SetChecked(RTMDB.minimap_icon_enabled)
	f:SetPoint("TOPLEFT", parent_frame, 0, -53)
end

function RTM:IntializeDebugCheckbox(parent_frame)
	local f = CreateFrame("CheckButton", "RTM.options_panel.debug_checkbox", parent_frame, "ChatConfigCheckButtonTemplate");
	getglobal(f:GetName() .. 'Text'):SetText(" Enable debug mode");
	f.tooltip = "Show or hide the minimap button.";
	f:SetScript("OnClick", 
		function()
			RTMDB.debug_enabled = not RTMDB.debug_enabled
		end
	);
	f:SetChecked(RTMDB.debug_enabled)
	f:SetPoint("TOPLEFT", parent_frame, 0, -75)
end

function RTM:IntializeScaleSlider(parent_frame)
	local f = CreateFrame("Slider", "RTM.options_panel.scale_slider", parent_frame, "OptionsSliderTemplate")
	f.tooltip = "Set the scale of the rare window.";
	f:SetMinMaxValues(0.5, 2)
	f:SetValueStep(0.05)
	f:SetValue(RTMDB.window_scale)
	RTM:SetScale(RTMDB.window_scale)
	f:Enable()
	
	f:SetScript("OnValueChanged", 
		function(self, value)
			-- Round the value to the nearest step value.
			value = math.floor(value * 20) / 20
		
			RTMDB.window_scale = value
			self.label:SetText("Rare window scale "..string.format("(%.2f)", RTMDB.window_scale))
			RTM:SetScale(RTMDB.window_scale)
		end
	);
	
	f.label = f:CreateFontString(nil, "BORDER", "GameFontNormal")
	f.label:SetJustifyH("LEFT")
	f.label:SetText("Rare window scale "..string.format("(%.2f)", RTMDB.window_scale))
	f.label:SetPoint("TOPLEFT", parent_frame, 0, -103)
	
	f:SetPoint("TOPLEFT", f.label, 5, -15)
end

function RTM:InitializeConfigMenu()
	RTM.options_panel = CreateFrame("Frame", "RTM.options_panel", UIParent)
	RTM.options_panel.name = "RareTrackerMechagon"
	InterfaceOptions_AddCategory(RTM.options_panel)
	
	RTM.options_panel.frame = CreateFrame("Frame", "RTM.options_panel.frame", RTM.options_panel)
	RTM.options_panel.frame:SetPoint("TOPLEFT", RTM.options_panel, 11, -14)
	RTM.options_panel.frame:SetSize(500, 500)

	RTM.options_panel.sound_selector = RTM:IntializeSoundSelectionMenu(RTM.options_panel.frame)
	RTM.options_panel.minimap_checkbox = RTM:IntializeMinimapCheckbox(RTM.options_panel.frame)
	RTM.options_panel.debug_checkbox = RTM:IntializeDebugCheckbox(RTM.options_panel.frame)
	RTM.options_panel.scale_slider = RTM:IntializeScaleSlider(RTM.options_panel.frame)
end




















