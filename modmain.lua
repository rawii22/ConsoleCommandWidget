--[[
References for "Text Edit Widget":
	- prefabs/homesign.lua
	- components/writeable.lua
	- writeables.lua
	- widgets/writeablewidget.lua
	
PlayerHud:ShowWriteableWidget(writeable, config)
    - components/playerhud.lua
	- [shows a widget you can write in, used for writing in the "homesign" prefab]
	
If want to bind custom buttons to console history:
	- consolecommands.lua > GetConsoleHistory()

TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION/CONTROL_CONTROLLER_ALTACTION/[number representing key/mouse press])
    - components/playercontroller.lua

Button:OnControl(control, down)
    - widgets/button.lua
	- [runs when any input (represented by integer, control, -- eg. Primary Action/Secondary Action) is triggered (up/down) while mouse is over a button]
Button:SetControl(ctrl)
    - widgets/button/lua
	- [sets the control (integer) that will trigger the button's ondown/onclick/onwhile functions]

--]]

local LETTERS = GetModConfigData("LETTERS")
local DISABLE_KEYS = GetModConfigData("DISABLE_KEYS")
local ADMIN_ONLY = GetModConfigData("ADMIN_ONLY")
local CONTROL_LEFT_MOUSE = GLOBAL.CONTROL_ACCEPT  --29
local CONTROL_RIGHT_MOUSE = 1
local BUTTON_SPACING = 75
local HOME_TO_HIDDEN_MOVETIME = 1
local CURRENT_TO_HOME_MOVETIME = 0.5

local Player
local SignGenerator = GLOBAL.require("signgenerator")
local Widget = GLOBAL.require("widgets/widget")
local Image = GLOBAL.require("widgets/image")
local ImageButton = GLOBAL.require("widgets/imagebutton")
local Button = GLOBAL.require("widgets/button")
local io = GLOBAL.require("io")

local dir_vert = -2
local dir_horiz = -1
local anchor_vert = 1
local anchor_horiz = 1
local margin_dir_vert = 1
local margin_dir_horiz = 1
local margin_size_x = 0
local margin_size_y = 0

local modname = "ConsoleCommandWidget"
local workshopID = "ConsoleCommandWidget" --"workshop-1862534310"       --------------------change to workshopID for mod releases; DON"T FORGET!!!

local commands = {
	nextphase = "TheWorld:PushEvent(\"ms_nextphase\")",
	--stoprain = "TheWorld:PushEvent(\"ms_forceprecipitation\", false)",
	--startrain = "TheWorld:PushEvent(\"ms_forceprecipitation\", true)", refer to bottom of file
	supergodmode = "c_supergodmode()",
	creativemode = "ThePlayer.components.builder:GiveAllRecipes()",
	reset = "c_reset()",
	resetsanity = "ThePlayer.components.sanity:SetPercent(1)",
	speedmult1 = "ThePlayer.components.locomotor:SetExternalSpeedMultiplier(ThePlayer, \"c_speedmult\", 1)",
	speedmult4 = "ThePlayer.components.locomotor:SetExternalSpeedMultiplier(ThePlayer, \"c_speedmult\", 4)",
	speedmult35 = "ThePlayer.components.locomotor:SetExternalSpeedMultiplier(ThePlayer, \"c_speedmult\", 35)",
	revealmapallplayers = "for k,v in pairs(AllPlayers) do for x=-1600,1600,35 do for y=-1600,1600,35 do v.player_classified.MapExplorer:RevealArea(x,0,y) end end end",
	setautumn = "TheWorld:PushEvent(\"ms_setseason\", \"autumn\")",
	save = "c_save()",
}

local function PositionPanel(controls, screensize, resizescale, oldrootscale, background, command_button, hidebutton, command_list)
	local hudscale = controls.top_root:GetScale()
	local screenw_full, screenh_full = GLOBAL.unpack(screensize)
	local screenw = screenw_full/hudscale.x
	local screenh = screenh_full/hudscale.y
	local background_h, background_w = background:GetSize()
	background_h = background_h * background:GetLooseScale() --scaled the same as defined in InitButtons
	background_w = background_w * background:GetLooseScale()
	local button_h, button_w = command_button[1]:GetSize()
	button_h = button_h * command_button[1]:GetScale().y
	button_w = button_w * command_button[1]:GetScale().x
	local xDim = 7 --columns
	local yDim = 2 --rows
	local slotPos = {}
	
	if screenw < 1820 then --1820, 80, and 70 were determined visually (magic numbers)
		margin_size_x = 80
		margin_size_y = 70
	else
		margin_size_x = 0
		margin_size_y = 0
	end
	
	--The default position of the panel which is what everything is based on
	background.homePos = GLOBAL.Vector3(
		(anchor_horiz*background_w/2)+(dir_horiz*screenw/2)+(margin_dir_horiz*margin_size_x),
		(anchor_vert*background_h/2)+(dir_vert*screenh/2)+(margin_dir_vert*margin_size_y),
		0
	)
	
	--Calculate position where panel will be sent to to hide
	background.hidePos = GLOBAL.Vector3(
		(dir_horiz*screenw*0.5) + (-1*anchor_horiz*background_w*(3/4)) + (margin_dir_horiz*margin_size_x),
		(dir_vert*screenh*0.5) + (anchor_vert*background_h*0.5) + (margin_dir_vert*margin_size_y),
		0
	)
	
	--Calculate new position for a panel that's been dragged
	local oldbgpos = background:GetPosition()
	local scaledbgpos = GLOBAL.Vector3(oldbgpos.x * resizescale.x * (oldrootscale.x/hudscale.x), oldbgpos.y * resizescale.y * (oldrootscale.y/hudscale.y), 0)
	
	--If panel hidden, set to hidden spot, otherwise set to home pos + any distance dragged
	background:SetPosition(background.isHidden and background.hidePos or background.hasMoved and scaledbgpos or background.homePos)
	
	--Generates list of positions for buttons
	for y = 0, (yDim-1) do
		for x = 0, (xDim-1) do
			--BUTTON_SPACING determined visually
			table.insert(slotPos, GLOBAL.Vector3(BUTTON_SPACING * x, BUTTON_SPACING * y, 0))
		end
	end

	for k, button in pairs(command_button) do
		button:SetPosition(slotPos[k].y - BUTTON_SPACING / 2 + 4, slotPos[k].x - BUTTON_SPACING * 3 + 3, 0)
		--these 2 lines are an attempt to keep the tooltips close to the buttons when the screen gets really small
		button:ClearHoverText()
		button:SetHoverText(command_list[k].tooltip, {offset_y = button_h--[[*0.75*hudscale.y]]})
	end
	
	local hidebuttonoffset = GLOBAL.Vector3(-1*background_w/2 + 10, 0, 0)
	hidebutton.homePos = background.homePos + hidebuttonoffset
	
	hidebutton:SetPosition(background.hasMoved and background:GetPosition() + hidebuttonoffset or hidebutton.homePos)
	local hidebutton_h, hidebutton_w = hidebutton:GetSize()
	hidebutton_h = hidebutton_h * hidebutton:GetScale().y
	hidebutton_w = hidebutton_w * hidebutton:GetScale().x
	hidebutton:ClearHoverText()
	hidebutton:SetHoverText("Hide", {offset_x = hidebutton_w--[[*.25*hudscale.x]], offset_y = 0})
end

local background = {}
local hidebutton = {}
local dragarrow = nil
local letter = {}
local command_icon = {}
local command_button = {}
local command_button_alt = {}
local command_list = {
	{
		command_string = commands.supergodmode,
		tooltip = "Super God",
		image = "reviver.tex",
		keybind = "c"
	},
	{
		command_string = commands.nextphase,
		tooltip = "Next Phase",
		image = "nextphase.tex",
		atlas = "images/customisation2.xml",
		scale = .55, --scale of the image on the button
		keybind = "v"
	},
	{
		command_string = commands.creativemode,
		tooltip = "Creative Mode",
		image = "researchlab2.tex",
		atlas = "images/customisation2.xml",
		scale = .55,
		keybind = "b"
	},
	{
		command_string = "",
		tooltip = "Toggle Rain",
		image = "rain.tex",
		atlas = "images/customisation.xml",
		scale = .55,
		rpcName = "togglerain",
		keybind = "n"
	},
	{
		command_string = commands.revealmapallplayers,
		tooltip = "Reveal Map - All Players",
		image = "world_map.tex",
		atlas = "images/customisation.xml",
		scale = .55
	},
	{
		command_string = commands.setautumn,
		tooltip = "Start Autumn",
		image = "autumn.tex",
		atlas = "images/customisation.xml",
		scale = .55,
	},
	{
		command_string = commands.resetsanity,
		tooltip = "Reset Sanity",
		image = "brain.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = commands.speedmult1,
		tooltip = "Speed 1",
		image = "blank_grassy_1.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = commands.speedmult4,
		tooltip = "Speed 4",
		image = "blank_world_4.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = commands.speedmult35,
		tooltip = "Speed 35",
		image = "blank_season_red_35.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = commands.save,
		tooltip = "Save",
		image = "blank_season_yellow_save.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = commands.reset,
		tooltip = "Reload",
		image = "world_start.tex",
		atlas = "images/customisation.xml",
		scale = .55
	},
	{
		command_string = "",
		tooltip = "Custom 1",
		image = "custom1.tex",
		atlas = "images/customisation2.xml",
		scale = .55,
		keybind = ",",
		customcommandindex = 1
	},
	{
		command_string = "",
		tooltip = "Custom 2",
		image = "custom2.tex",
		atlas = "images/customisation2.xml",
		scale = .55,
		keybind = ".",
		customcommandindex = 2
	},
}

local raw_custom_command = {"", ""}
local writeable_screen = {}
local writeable_data = {
    prompt = GLOBAL.STRINGS.SIGNS.MENU.PROMPT,
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = GLOBAL.Vector3(6, -70, 0),

    cancelbtn = { text = GLOBAL.STRINGS.SIGNS.MENU.CANCEL, cb = nil, control = GLOBAL.CONTROL_CANCEL },
    --[[middlebtn = { text = GLOBAL.STRINGS.SIGNS.MENU.RANDOM, cb = function(inst, doer, widget)
            widget:OverrideText( SignGenerator(inst, doer) )
        end, control = GLOBAL.CONTROL_MENU_MISC_2 },]]
    acceptbtn = { text = "Assign", cb = function(inst, doer, widget)
		raw_custom_command[widget.customcommandindex] = widget:GetText()-------------------------------------Add keyuphandler
		if not DISABLE_KEYS then
			local customElement
			for k, v in ipairs(command_list) do
				if v.customcommandindex == widget.customcommandindex then
					customElement = v
				end
			end
			GLOBAL.TheInput:AddKeyUpHandler(
				customElement.keybind:lower():byte(), 
				function()
					if not GLOBAL.IsPaused() and IsDefaultScreen() then
						SendModRPCToServer(MOD_RPC[modname]["receivecommand"], raw_custom_command[customElement.customcommandindex])
					end
				end
			)
		end
	end, control = GLOBAL.CONTROL_ACCEPT },

    --defaulttext = SignGenerator,
}

local dragarrow_atlas = "images/dragarrow.xml"
local dragarrow_tex = "images/dragarrow.tex"
local dragarrow_inactive_img = "dragarrow_inactive.tex"
local dragarrow_active_img = "dragarrow_active.tex"

Assets = {
	Asset("ATLAS", "images/basic_back.xml"),
	Asset("IMAGE", "images/basic_back.tex"),
	Asset("ATLAS", "images/button_large.xml"),
	Asset("IMAGE", "images/button_large.tex"),
	Asset("ATLAS", "images/ui_panel_2x8.xml"),
	Asset("IMAGE", "images/ui_panel_2x8.tex"),
	Asset("ATLAS", "images/customisation2.xml"),
	Asset("IMAGE", "images/customisation2.tex"),
	Asset("ATLAS", "images/customisation.xml"),
	Asset("IMAGE", "images/customisation.tex"),
	Asset("ATLAS", dragarrow_atlas),
	Asset("IMAGE", dragarrow_tex),
}

--[[
===========================
   Class Post-Constructs
===========================
--]]
local function InitButtons(controls)
	local isAdmin = false
	for k, v in pairs(GLOBAL.TheNet:GetClientTable()) do
		if v.userid == GLOBAL.ThePlayer.userid and v.admin then
			isAdmin = true
		end
	end
	--A custom way of adding admins to the game who can access the widget
	local adminFile = "../mods/"..workshopID.."/adminlist.txt"
	local f = io.open(adminFile, "r")
	if f ~= nil then
		io.close(f)
		for line in io.lines(adminFile) do
			if GLOBAL.ThePlayer.userid == line then
				isAdmin = true
			end
		end
	end
		
	if isAdmin or not ADMIN_ONLY then
		background = controls.top_root:AddChild(Image("images/ui_panel_2x8.xml","ui_panel_2x8.tex"))
		background:SetScale(.63)
		background:SetRotation(90)
		background:MoveToFront()
		background.isHidden = false
		background.hasMoved = false
		
		for k,cmd in ipairs(command_list) do
			-- Create square buttons
			command_button[k] = background:AddChild(ImageButton("images/hud.xml","inv_slot_spoiled.tex","inv_slot.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex"))
			command_button[k]:SetScale(1)
			command_button[k]:SetRotation(-90)
			local rpcName = cmd.rpcName or "receivecommand"
			command_button[k]:SetOnClick(function(inst) return SendModRPCToServer(MOD_RPC[modname][rpcName], cmd.command_string) end)
			-- Make the buttons bulge when hovered over
			command_button[k].ongainfocus = function(isEnabled)
				local self = command_button[k]
				if isEnabled and not self.selected then
					self:SetScale(1.2)
				end
				if dragarrow then
					dragarrow:Hide()
				end
			end
			command_button[k].onlosefocus = function(isEnabled)
				local self = command_button[k]
				if isEnabled and not self.selected then
					self:SetScale(1)
				end
				if dragarrow and background:GetDeepestFocus() == background then
					dragarrow:SetTexture(dragarrow_atlas, dragarrow_inactive_img)
					dragarrow:Show()
				end
			end
			command_button[k].clickoffset = GLOBAL.Vector3(3,0,0)
			command_button[k]:MoveToFront()
			-- Tooltip is created here
			command_button[k]:SetHoverText(cmd.tooltip)
			
			-- Create key shortcuts
			if not DISABLE_KEYS and cmd.keybind ~= nil then
				GLOBAL.TheInput:AddKeyUpHandler(
					cmd.keybind:lower():byte(), 
					function()
						if not GLOBAL.IsPaused() and IsDefaultScreen() then
							SendModRPCToServer(MOD_RPC[modname][rpcName], cmd.command_string)
						end
					end
				)
			end
			
			-- Create icons
			local atlas = cmd.atlas or "images/inventoryimages.xml"
			command_icon[k] = Image(atlas, cmd.image)
			local scale = cmd.scale or 1
			command_icon[k]:SetScale(scale)
			command_button[k]:AddChild(command_icon[k])
			
			-- Create keybind letters on buttons
			if (LETTERS and cmd.keybind ~= nil) then
				letter[k] = command_button[k]:AddChild(Button())
				letter[k]:SetText(cmd.keybind)
				letter[k]:SetFont("stint-ucr")
				letter[k]:SetTextColour(1,1,1,1)
				letter[k]:SetTextFocusColour(0.7,0.7,0.7,1)
				letter[k]:SetTextSize(50)
				letter[k]:MoveToFront()
			end
			
			-- Identify custom buttons
			command_button[k].customcommandindex = cmd.customcommandindex or 0
		end
		
		----------------------------------------------- Hide button
		hidebutton = controls.top_root:AddChild(ImageButton("images/hud.xml","inv_slot.tex","inv_slot.tex","inv_slot.tex","inv_slot.tex","inv_slot.tex"))
		hidebutton:SetScale(.5)
		
		hidebutton:SetOnClick(function()
			local background_h, background_w = background:GetSize()
			if background.isHidden then
				-- Move from hidden to home pos
				background:MoveTo(background.hidePos, background.homePos, HOME_TO_HIDDEN_MOVETIME)
				background.isHidden = not background.isHidden
			else
				if background.hasMoved then
					-- Move from current to home pos
					background:MoveTo(background:GetPosition(), background.homePos, CURRENT_TO_HOME_MOVETIME, function()
						-- Move offscreen
						background:MoveTo(background.homePos, background.hidePos, HOME_TO_HIDDEN_MOVETIME)
					end)
					hidebutton:MoveTo(hidebutton:GetPosition(), hidebutton.homePos, CURRENT_TO_HOME_MOVETIME)
					background.hasMoved = false
				else
					-- Move offscreen
					background:MoveTo(background.homePos, background.hidePos, HOME_TO_HIDDEN_MOVETIME)
				end
				background.isHidden = not background.isHidden
			end
		end)
		
		hidebutton.ongainfocus = function(isEnabled)
			if isEnabled and not hidebutton.selected then
				hidebutton:SetScale(.54)
			end
		end
		hidebutton.onlosefocus = function(isEnabled)
			if isEnabled and not hidebutton.selected then
				hidebutton:SetScale(.5)
			end
		end
		hidebutton:MoveToFront()
		hidebutton:SetHoverText("Hide")
		
		-----------------------------------------------
		--from muche's WidgetDragger demo mod
		
		oldbg_OnControl = background.OnControl
		background.OnControl = function(self, control, down)
			local res = oldbg_OnControl ~= nil and oldbg_OnControl(self, control, down) or false
			if res then
				return true
			end
			if control == GLOBAL.CONTROL_ACCEPT then
				if down and self:IsDeepestFocus() then
					self:StartDrag()
				else
					self:EndDrag()
				end
				return true
			end
			return false
		end
		
		local oldbg_OnGainFocus = background.OnGainFocus
		background.OnGainFocus = function(self)
			if oldbg_OnGainFocus ~= nil then
				oldbg_OnGainFocus(self, controller)
			end
			
			if dragarrow == nil then
				dragarrow = controls.top_root:AddChild(Image(dragarrow_atlas, dragarrow_inactive_img))
				dragarrow:SetHAnchor(GLOBAL.ANCHOR_LEFT)
				dragarrow:SetVAnchor(GLOBAL.ANCHOR_BOTTOM)
				dragarrow:SetClickable(false) -- make dragarrow to be ignored when determining focus
			end
			dragarrow:Show()
			dragarrow:FollowMouse()
			GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
		end

		local oldbg_OnLoseFocus = background.OnLoseFocus
		background.OnLoseFocus = function(self)
			if oldbg_OnLoseFocus ~= nil then
				oldbg_OnLoseFocus(self, controller)
			end
			
			dragarrow:StopFollowMouse()
			dragarrow:Hide()
			if self.followhandler ~= nil then
				-- cancel drag in progress
				-- self:EndDrag()
			end
			GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
		end
		
		background.StartDrag = function(self)
			local mousestartpos = GLOBAL.TheInput:GetScreenPosition()
			local bgstartpos = self:GetPosition()
			local hbstartpos = hidebutton:GetPosition()
			if self.followhandler == nil then
				self.followhandler = GLOBAL.TheInput:AddMoveHandler(function(x,y)
					local hudscale = controls.top_root:GetScale()
					local mouseposdelta = mousestartpos - GLOBAL.TheInput:GetScreenPosition()
					local bgposdelta = GLOBAL.Vector3(1/hudscale.x*mouseposdelta.x, 1/hudscale.y*mouseposdelta.y, 0)
					self:SetPosition(bgstartpos - bgposdelta)
					
					local hbposdelta = GLOBAL.Vector3(1/hudscale.x*mouseposdelta.x, 1/hudscale.y*mouseposdelta.y, 0)
					hidebutton:SetPosition(hbstartpos - hbposdelta)
				end)
			end
			if dragarrow then
				dragarrow:SetTexture(dragarrow_atlas, dragarrow_active_img)
			end
			background.hasMoved = true
			GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
		end

		background.EndDrag = function(self)
			if self.followhandler ~= nil then
				self.followhandler:Remove()
				self.followhandler = nil
			end
			if dragarrow then
				dragarrow:SetTexture(dragarrow_atlas, dragarrow_inactive_img)
			end
			GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
		end
		
		-----------------------------------------------
		--this next section was the key taken from squeek's minimap mod
		local screensize = {GLOBAL.TheSim:GetScreenSize()}
		local rootscale = controls.top_root:GetScale()
		PositionPanel(controls, screensize, GLOBAL.Vector3(1,1,1), GLOBAL.Vector3(1,1,1), background, command_button, hidebutton, command_list)
		
		local OnUpdate_base = controls.OnUpdate
		controls.OnUpdate = function(self, dt)
			OnUpdate_base(self, dt)
			local curscreensize = {GLOBAL.TheSim:GetScreenSize()}
			-- Use ratio (curscreensize/screensize) to translate old position of panel to new screen size
			if curscreensize[1] ~= screensize[1] or curscreensize[2] ~= screensize[2] then --if the screen has changed, then reposition the panel
				local resizescale = GLOBAL.Vector3(curscreensize[1]/screensize[1], curscreensize[2]/screensize[2], 0)
				PositionPanel(controls, curscreensize, resizescale, rootscale, background, command_button, hidebutton, command_list)
				screensize = curscreensize
				rootscale = controls.top_root:GetScale()
			end
		end
	end
end
AddClassPostConstruct("widgets/controls", InitButtons)

local function ShowWriteableWidget(index)
	writeable_screen = GLOBAL.ThePlayer.HUD:ShowWriteableWidget(GLOBAL.ThePlayer, writeable_data)
	--writeable_screen:SetPosition(0, 0, 0)
	writeable_screen.customcommandindex = index		-- so widget can write command to proper location
	writeable_screen:OverrideText(raw_custom_command[index])
end
local function CustomLeftClick(index)
	SendModRPCToServer(MOD_RPC[modname]["receivecommand"], raw_custom_command[index])
end
local function HandleLeftRightClickForCustomButtons(self)
	local old_OnControl = self.OnControl
	self.OnControl = function(self, control, down)
		if (self.customcommandindex or 0) > 0 and control == CONTROL_RIGHT_MOUSE then
			self:SetControl(CONTROL_RIGHT_MOUSE)
			self:SetOnClick(function() ShowWriteableWidget(self.customcommandindex) end)
		end
		if (self.customcommandindex or 0) > 0 and control == CONTROL_LEFT_MOUSE then
			self:SetControl(CONTROL_LEFT_MOUSE)
			self:SetOnClick(function() CustomLeftClick(self.customcommandindex) end)
		end
		old_OnControl(self, control, down)
	end
end
AddClassPostConstruct("widgets/button", HandleLeftRightClickForCustomButtons)


--[[
======================
   Global Functions
======================
--]]
--To manually set the custom command buttons
function c_bindbutton(commandString, customButton)
	if customButton >= 1 and customButton <= 2 then
		local pos = customButton + 12
		command_button[pos]:SetOnClick(function(inst) return SendModRPCToServer(MOD_RPC[modname]["receivecommand"], commandString) end)
	end
end

function IsDefaultScreen()
	if GLOBAL.TheFrontEnd:GetActiveScreen() and GLOBAL.TheFrontEnd:GetActiveScreen().name and type(GLOBAL.TheFrontEnd:GetActiveScreen().name) == "string" and GLOBAL.TheFrontEnd:GetActiveScreen().name == "HUD" then
		return true
	else
		return false
	end
end

--[[
====================
   Input Handlers
====================
--]]
--A useful button since the mod's purpose is convenience
local removekey = "r"
if not DISABLE_KEYS then
	GLOBAL.TheInput:AddKeyUpHandler(
		removekey:lower():byte(), 
		function()
			if not GLOBAL.IsPaused() and IsDefaultScreen() then
				SendModRPCToServer(MOD_RPC[modname]["receivecommand"], "c_select():Remove()")
			end
		end
	)
end

--[[
==================
   RPC Handlers (since these commands require certain conditions to be known)
==================
--]]
AddModRPCHandler(modname, "receivecommand", function(player, commandString)
	originalPlayer = GLOBAL.ThePlayer
	GLOBAL.ThePlayer = player
	GLOBAL.ExecuteConsoleCommand(commandString)
	GLOBAL.ThePlayer = originalPlayer
end)
AddModRPCHandler(modname, "togglerain", function(player)
	if GLOBAL.TheWorld.state.israining or GLOBAL.TheWorld.state.issnowing then
		GLOBAL.TheWorld:PushEvent("ms_forceprecipitation", false)
	else
		GLOBAL.TheWorld:PushEvent("ms_forceprecipitation", true)
	end
end)