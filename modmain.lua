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
local BUTTON_SPACING = 47

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
local workshopID = "ConsoleCommandWidget(git)"--"workshop-1862534310"       --------------------change to workshopID for mod releases; DON"T FORGET!!!

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

local function PositionPanel(controls, screensize, background, command_button)
	local hudscale = controls.top_root:GetScale()
	local screenw_full, screenh_full = GLOBAL.unpack(screensize)
	local screenw = screenw_full/hudscale.x
	local screenh = screenh_full/hudscale.y
	local background_h, background_w = background:GetSize()
	background_h = background_h * .63 --scaled the same as defined in InitButtons
	background_w = background_w * .63
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
	background:SetPosition(
		(anchor_horiz*background_w/2)+(dir_horiz*screenw/2)+(margin_dir_horiz*margin_size_x), 
		(anchor_vert*background_h/2)+(dir_vert*screenh/2)+(margin_dir_vert*margin_size_y), 
		0
	)
	
	--goes through each button and generates its position based on the background's position
	for y = 0, (yDim-1) do
		for x = 0, (xDim-1) do
			--47 here determines the spacing of the buttons. Also determined visually
			table.insert(slotPos, GLOBAL.Vector3(background:GetPosition().x + BUTTON_SPACING * x, background:GetPosition().y - BUTTON_SPACING * y, 0))
		end
	end

	for k, button in pairs(command_button) do
		button:SetPosition(slotPos[k].x - BUTTON_SPACING * 3 + 3, slotPos[k].y + BUTTON_SPACING / 2 - 3, 0)
	end
end

local background = {}
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
}

--[[
TheNet:GetClientTable()[playerNumber].admin
]]

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
	for line in io.lines("../mods/"..workshopID.."/adminlist.txt") do
		print(line)
		if GLOBAL.ThePlayer.userid == line then
			isAdmin = true
		end
	end
		
	if isAdmin or not ADMIN_ONLY then
		background = controls.top_root:AddChild(Image("images/ui_panel_2x8.xml","ui_panel_2x8.tex"))
		background:SetScale(.63)
		background:SetRotation(90)
		background:MoveToFront()
		
		for k,cmd in ipairs(command_list) do
			-- Create square buttons
			command_button[k] = controls.top_root:AddChild(ImageButton("images/hud.xml","inv_slot_spoiled.tex","inv_slot.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex"))
			command_button[k]:SetScale(.6)
			local rpcName = cmd.rpcName or "receivecommand"
			command_button[k]:SetOnClick(function(inst) return SendModRPCToServer(MOD_RPC[modname][rpcName], cmd.command_string) end)
			-- Make the buttons bulge when hovered over
			command_button[k].ongainfocus = function(isEnabled)
				local self = command_button[k]
				if isEnabled and not self.selected then
					self:SetScale(.8)
				end
			end
			command_button[k].onlosefocus = function(isEnabled)
				local self = command_button[k]
				if isEnabled and not self.selected then
					self:SetScale(.6)
				end
			end
			command_button[k]:MoveToFront()
			-- Tooltip is created here
			command_button[k]:SetHoverText(cmd.tooltip, {offset_y = 80})
			
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
		
		--this next section was the key taken from squeek's minimap mod
		local screensize = {GLOBAL.TheSim:GetScreenSize()}
		PositionPanel(controls, screensize, background, command_button)
		
		local OnUpdate_base = controls.OnUpdate
		controls.OnUpdate = function(self, dt)
			OnUpdate_base(self, dt)
			local curscreensize = {GLOBAL.TheSim:GetScreenSize()}
			if curscreensize[1] ~= screensize[1] or curscreensize[2] ~= screensize[2] then --if the screen has changed, then reposition the panel
				PositionPanel(controls, curscreensize, background, command_button)
				screensize = curscreensize
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