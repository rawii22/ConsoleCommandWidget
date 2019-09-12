local KEY_WEAPON = GetModConfigData("Key_Weapon")
local KEY_AXE = GetModConfigData("Key_Axe")
local KEY_PICKAXE = GetModConfigData("Key_Pickaxe")
local KEY_SHOVEL = GetModConfigData("Key_Shovel")
local KEY_HAMMER = GetModConfigData("Key_Hammer")
local KEY_PITCHFORK = GetModConfigData("Key_Pitchfork")
local KEY_LIGHT = GetModConfigData("Key_Light")
local KEY_ARMOR = GetModConfigData("Key_Armor")
local KEY_HELMET = GetModConfigData("Key_Helmet")
local KEY_CANE = GetModConfigData("Key_Cane")
local LETTERS = GetModConfigData("Letters")
local DISABLE_KEYS = GetModConfigData("Disable_Keys")
local DISABLE_BUTTONS = GetModConfigData("Disable_Buttons")
local SUPPORT_ARCHERY = GetModConfigData("Support_Archery")
local SUPPORT_SCYTHES = GetModConfigData("Support_Scythes")
local KEY_SCYTHE = GetModConfigData("Key_Scythe")
local VERTICAL_OFFSET = GetModConfigData("Vertical_Offset")
local KEY_REFRESH = GetModConfigData("Key_Refresh")

local KEYS = {
	KEY_WEAPON,
	KEY_AXE,
	KEY_PICKAXE,
	KEY_SHOVEL,
	KEY_HAMMER,
	KEY_PITCHFORK,
	KEY_LIGHT,
	KEY_ARMOR,
	KEY_HELMET,
	KEY_CANE,
	KEY_SCYTHE
}

local Player
local Widget = GLOBAL.require("widgets/widget")
local Image = GLOBAL.require("widgets/image")
local ImageButton = GLOBAL.require("widgets/imagebutton")
local Button = GLOBAL.require("widgets/button")
local TEMPLATES = GLOBAL.require("widgets/templates")

local modname = "ConsoleCommandWidget";
local cantButtons = 11

local button = {}
local icon_button = {}
local actual_item = {}
local letter = {}

local button_order = {2,1,2,3,4,5,6,3,4,1}
local button_order_scythe = {2,1,3,4,5,6,7,3,4,1,2}
local button_side = {1,0,0,0,0,0,0,1,1,1}
local button_side_scythe = {1,0,0,0,0,0,0,1,1,1,0}

local tools_back
local equip_back

local finish_init = false

local offset_archery = 0
if (SUPPORT_ARCHERY) then
	offset_archery = -128
end

local default_icon = {
	"spear",
	"axe",
	"pickaxe",
	"shovel",
	"hammer",
	"pitchfork",
	"torch",
	"armorwood",
	"footballhat",
	"cane",
	"scythe"
}

local commands = {
	nextphase = "TheWorld:PushEvent(\"ms_nextphase\")",
	--stoprain = "TheWorld:PushEvent(\"ms_forceprecipitation\", false)",
	--startrain = "TheWorld:PushEvent(\"ms_forceprecipitation\", true)", refer to bottom of file
	supergodmode = "c_supergodmode()",
	creativemode = "GetPlayer().components.builder:GiveAllRecipes()",
	reset = "c_reset()",
	resetsanity = "AllPlayers[1].components.sanity:SetPercent(1)",
	speedmult1 = "c_speedmult(1)",
	speedmult4 = "c_speedmult(4)",
	speedmult35 = "c_speedmult(35)",
	revealmapallplayers = "for k,v in pairs(AllPlayers) do for x=-1600,1600,35 do for y=-1600,1600,35 do v.player_classified.MapExplorer:RevealArea(x,0,y) end end end",
	setautumn = "TheWorld:PushEvent(\"ms_setseason\", \"autumn\")",
	save = "c_save()",
}

local xDim = 7
local yDim = 2
local baseSlotPos = { x = -1450, y = 180 }
local slotPos = {}

for y = 0, (yDim-1) do
    for x = 0, (xDim-1) do
		-- size of inventory square is < 75
        table.insert(slotPos, GLOBAL.Vector3(baseSlotPos.x + 75 * x, baseSlotPos.y - 75 * y, 0))
    end
end

local command_icon = {}
local command_button = {}
local command_list = {
	{
		command_string = commands.supergodmode,
		tooltip = "Super God Mode",
		pos = slotPos[1],
		image = "reviver.tex"
	},
	{
		command_string = commands.nextphase,
		tooltip = "Next Phase",
		pos = slotPos[2],
		image = "nextphase.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = commands.creativemode,
		tooltip = "Creative Mode",
		pos = slotPos[3],
		image = "researchlab2.tex"
	},
	{
		command_string = "",
		tooltip = "Toggle Rain",
		pos = slotPos[4],
		image = "rain.tex",
		atlas = "images/customisation.xml",
		scale = .55,
		rpcName = "togglerain"
	},
	{
		command_string = commands.revealmapallplayers,
		tooltip = "Reveal Map - All Players",
		pos = slotPos[5],
		image = "world_map.tex",
		atlas = "images/customisation.xml",
		scale = .55
	},
	{
		command_string = commands.setautumn,
		tooltip = "Start Autumn",
		pos = slotPos[6],
		image = "autumn.tex",
		atlas = "images/customisation.xml",
		scale = .55,
	},
	{
		command_string = commands.resetsanity,
		tooltip = "Reset Sanity",
		pos = slotPos[7],
		image = "nightmarefuel.tex"
	},
	{
		command_string = commands.speedmult1,
		tooltip = "Speed 1",
		pos = slotPos[8],
		image = "blank_grassy_1.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = commands.speedmult4,
		tooltip = "Speed 4",
		pos = slotPos[9],
		image = "blank_world_4.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = commands.speedmult35,
		tooltip = "Speed 35",
		pos = slotPos[10],
		image = "blank_season_red_35.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = commands.save,
		tooltip = "Save",
		pos = slotPos[11],
		image = "blank_season_yellow_save.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = commands.reset,
		tooltip = "Reset",
		pos = slotPos[12],
		image = "world_start.tex",
		atlas = "images/customisation.xml",
		scale = .55
	},
	{
		command_string = "",
		tooltip = "Custom 1",
		pos = slotPos[13],
		image = "custom1.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
	{
		command_string = "",
		tooltip = "Custom 2",
		pos = slotPos[14],
		image = "custom2.tex",
		atlas = "images/customisation2.xml",
		scale = .55
	},
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

local info_buttons = {}
local info_stack = {last=0}
local info_names = {last=0}
local info_back_button
local info_actual_button
local base_position = { x = -600, y = -50}
local col = 0
local row = 0
local offset_x = 160
local offset_y = 55


local function AddKeybindButton(self,index)
	button[index] = self:AddChild(ImageButton("images/hud.xml","inv_slot_spoiled.tex","inv_slot.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex"))
	
	local x
	if (SUPPORT_SCYTHES) then
		if (button_side_scythe[index] == 0) then
			x = 68*(button_order_scythe[index]-5)+offset_archery
		elseif (button_side_scythe[index] == 1) then
			x = 68*button_order_scythe[index]+425-(12*(4-button_order_scythe[index]))+offset_archery
		end
	else
		if (button_side[index] == 0) then
			x = 68*(button_order[index]-4)+offset_archery
		elseif (button_side[index] == 1) then
			x = 68*button_order[index]+425-(12*(4-button_order[index]))+offset_archery
		end
	end

	button[index]:SetPosition(x,160+(67*VERTICAL_OFFSET),0)
	button[index]:SetOnClick(function(inst) return 0 end)
	button[index]:MoveToFront()
	
	if (default_icon[index]) then
		if (index == 11) then
			icon_button[index] = Image("images/inventoryimages/scythe.xml",default_icon[index]..".tex")
		else
			icon_button[index] = Image("images/inventoryimages.xml",default_icon[index]..".tex")
		end
	else
		icon_button[index] = Image("images/inventoryimages.xml","spear.tex")
	end
	icon_button[index]:SetScale(0.8,0.8,0.8)
	icon_button[index]:SetTint(0,0,0,0.7)
	button[index]:AddChild(icon_button[index])
	
	letter[index] = button[index]:AddChild(Button())
	if (LETTERS and KEYS[index] ~= false) then
		letter[index]:SetText(KEYS[index])
	end
	letter[index]:SetPosition(5,0,0)
	letter[index]:SetFont("stint-ucr")
	letter[index]:SetTextColour(1,1,1,1)
	letter[index]:SetTextFocusColour(1,1,1,1)
	letter[index]:SetTextSize(50)
	--letter[index]:Disable()
	letter[index]:MoveToFront()
	
	if (DISABLE_BUTTONS) then
		button[index]:Hide()
		icon_button[index]:Hide()
		letter[index]:Hide()
	end
end

--[[
TheNet:GetClientTable()[playerNumber].admin
]]

--[[
===========================
   Class Post-Constructs
===========================
--]]
local function InitKeybindButtons(self)

	if (SUPPORT_SCYTHES) then
		tools_back = self:AddChild(Image("images/basic_back.xml","tools_back_ship.tex"))
		tools_back:SetPosition(-67+offset_archery,170+(67*VERTICAL_OFFSET),0)
	else
		tools_back = self:AddChild(Image("images/basic_back.xml","tools_back.tex"))
		tools_back:SetPosition(-34+offset_archery,170+(67*VERTICAL_OFFSET),0)
	end
	tools_back:MoveToBack()
	
	equip_back = self:AddChild(Image("images/ui_panel_2x8.xml","ui_panel_2x8.tex"))
	equip_back:SetPosition(-1230,145,0)	--equip_back:SetPosition(460+158-42+offset_archery,170+(67*VERTICAL_OFFSET),0)
	equip_back:SetRotation(90)
	equip_back:MoveToFront()
	
	
	for k,cmd in ipairs(command_list) do
		-- Create square buttons
		command_button[k] = self:AddChild(ImageButton("images/hud.xml","inv_slot_spoiled.tex","inv_slot.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex"))
		command_button[k]:SetPosition(cmd.pos.x, cmd.pos.y, cmd.pos.z)
		local rpcName = cmd.rpcName or "receivecommand"
		command_button[k]:SetOnClick(function(inst) return SendModRPCToServer(MOD_RPC[modname][rpcName], cmd.command_string) end)
		command_button[k]:MoveToFront()
		command_button[k]:SetHoverText(cmd.tooltip, {offset_y = 80})
		
		-- Create icons
		local atlas = cmd.atlas or "images/inventoryimages.xml"
		command_icon[k] = Image(atlas, cmd.image)
		local scale = cmd.scale or 1
		command_icon[k]:SetScale(scale)
		command_button[k]:AddChild(command_icon[k])
	end
	
	
	if (DISABLE_BUTTONS) then
		tools_back:Hide()
		equip_back:Hide()
	end
	
	for i=1, cantButtons do
		icon_button[i] = nil
		actual_item[i] = nil
	end
	AddKeybindButton(self,1)
	AddKeybindButton(self,2)
	AddKeybindButton(self,3)
	AddKeybindButton(self,4)
	AddKeybindButton(self,5)
	AddKeybindButton(self,6)
	AddKeybindButton(self,7)
	AddKeybindButton(self,8)
	AddKeybindButton(self,9)
	AddKeybindButton(self,10)
	if (SUPPORT_SCYTHES) then
		AddKeybindButton(self,11)
	end
	
	finish_init = true
end
AddClassPostConstruct("widgets/inventorybar", InitKeybindButtons)


--[[
======================
   Global Functions
======================
--]]
GLOBAL.c_bindbutton = function(commandString, customButton)
	if customButton >= 1 and customButton <= 2 then
		local pos = customButton + 12
		command_button[pos]:SetOnClick(function(inst) return SendModRPCToServer(MOD_RPC[modname]["receivecommand"], commandString) end)
	end
end


--[[
====================
   Input Handlers
====================
--]]
local function IsDefaultScreen()
	if GLOBAL.TheFrontEnd:GetActiveScreen() and GLOBAL.TheFrontEnd:GetActiveScreen().name and type(GLOBAL.TheFrontEnd:GetActiveScreen().name) == "string" and GLOBAL.TheFrontEnd:GetActiveScreen().name == "HUD" then
		return true
	else
		return false
	end
end

if (not DISABLE_KEYS) then
	for i,key in pairs(KEYS) do
		if (key ~= false) then
			GLOBAL.TheInput:AddKeyUpHandler(
				key:lower():byte(), 
				function()
					if not GLOBAL.IsPaused() and IsDefaultScreen() then
						EquipItem(i)
					end
				end
			)
		end
	end
end

if (KEY_REFRESH ~= false) then
	GLOBAL.TheInput:AddKeyUpHandler(
		KEY_REFRESH:lower():byte(), 
		function()
			if not GLOBAL.IsPaused() and IsDefaultScreen() then
				CheckAllButtonItem()
			end
		end
	)
end


--[[
==================
   RPC Handlers
==================
--]]
AddModRPCHandler(modname, "receivecommand", function(player, commandString) GLOBAL.ExecuteConsoleCommand(commandString) end)
AddModRPCHandler(modname, "togglerain", function(player)
	if GLOBAL.TheWorld.state.israining or GLOBAL.TheWorld.state.issnowing then
		GLOBAL.TheWorld:PushEvent("ms_forceprecipitation", false)
	else
		GLOBAL.TheWorld:PushEvent("ms_forceprecipitation", true)
	end
end)