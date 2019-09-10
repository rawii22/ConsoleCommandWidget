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

local commands = {
	nextphase = "TheWorld:PushEvent(\"ms_nextphase\")",
	stoprain = "TheWorld:PushEvent(\"ms_forceprecipitation\", false)",
	startrain = "TheWorld:PushEvent(\"ms_forceprecipitation\", true)",
	supergodmode = "c_supergodmode()",
	creativemode = "GetPlayer().components.builder:GiveAllRecipes()",
	reset = "c_reset()",
	resetsanity = "AllPlayers[1].components.sanity:SetPercent(1)",
	speedmult1 = "c_speedmult(1)",
	speedmult4 = "c_speedmult(4)",
	speedmult35 = "c_speedmult(35)",
	revealmapallplayers = "for k,v in pairs(AllPlayers) do for x=-1600,1600,35 do for y=-1600,1600,35 do v.player_classified.MapExplorer:RevealArea(x,0,y) end end end",
	setautumn = "TheWorld:PushEvent(\"ms_setseason\", \"autumn\")",
}

local xDim = 8
local yDim = 2
local baseSlotPos = { x = -1450, y = 180 }
local slotPos = {}

for y = 0, (yDim-1) do
    for x = 0, (xDim-1) do
		-- size of inventory square is < 75
        table.insert(slotPos, GLOBAL.Vector3(baseSlotPos.x + 75 * x, baseSlotPos.y - 75 * y, 0))
    end
end

local command_button = {}
local command_list = {
	{
		command_string = commands.reset,
		tooltip = "Reset",
		pos = slotPos[1]
	},
	{
		command_string = commands.supergodmode,
		tooltip = "Super God-Mode",
		pos = slotPos[2]
	},
	{
		command_string = commands.nextphase,
		tooltip = "Next Day-Phase",
		pos = slotPos[3]
	},
	{
		command_string = commands.startrain,
		tooltip = "Start Rain",
		pos = slotPos[4]
	}
}

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

local weapons = {
	"musket",
	"crossbow",
	"bow",
	"cutlass",
	"nightsword",
	"ruins_bat",
	"hambat",
	"spear_obsidian",
	"tentaclespike",
	"batbat",
	"gears_mace",
	"spear_wathgrithr",
	"gears_staff",
	"sword_rock",
	"spear_poison",
	"spear",
	"peg_leg",
	"trident",
	"whip",
	"needlespear",
	"bug_swatter"
}

local axes = {
	"lucy",
	"gears_multitool",
	"multitool_axe_pickaxe",
	"goldenaxe",
	"axe"
}

local pickaxes = {
	"gears_multitool",
	"multitool_axe_pickaxe",
	"goldenpickaxe",
	"pickaxe"
}

local shovels = {
	"goldenshovel",
	"shovel"
}

local scythes = {
	"scythe_golden",
	"scythe"
}

local armors = {
	"armorruins",
	"armordragonfly",
	"armorobsidian",
	"armorsnurtleshell",
	"armormarble",
	"armorlimestone",
	"armor_sanity",
	"armor_rock",
	"armorseashell",
	"armorcactus",
	"armor_bone",
	"armor_stone",
	"armorwood",
	"armorgrass"
}

local helmets = {
	"ruinshat",
	"hivehat",
	"hat_marble",
	"slurtlehat",
	"hat_rock",
	"wathgrithrhat",
	"oxhat",
	"hat_wood",
	"footballhat"
}

local backpacks = {
	"backpack",
	"piggypack",
	"krampus_sack",
	"icepack",
	"thatchpack",
	"piratepack",
	"spicepack",
	"seasack",
	"equip_pack",
	"wool_sack"
}

local lights = {
	"gears_hat_goggles",
	"molehat",
	"bottlelantern",
	"lantern",
	"minerhat",
	"tarlamp",
	"lighter",
	"torch"
}

Assets = {
	Asset("ATLAS", "images/basic_back.xml"),
	Asset("IMAGE", "images/basic_back.tex"),
	Asset("ATLAS", "images/button_large.xml"),
	Asset("IMAGE", "images/button_large.tex"),
	Asset("ATLAS", "images/ui_panel_2x8.xml"),
	Asset("IMAGE", "images/ui_panel_2x8.tex")
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

local function ClearInfoTable()
	info_stack = {last=0}
	info_names = {last=0}
	
	if (info_back_button) then
		info_back_button:Kill()
	end
		
	if (info_actual_button) then
		info_actual_button:Kill()
	end
	
	info_back_button = nil
	info_actual_button = nil
	
	for i,v in pairs(info_buttons) do
		v:Kill()
	end
	info_buttons = {}
end

local function InfoTable(inst, info, last_info, init)
	local info_root = inst.HUD.controls.top_root
	col = 0
	row = 0
	
	if (init) then
		info_stack = {last=0}
		info_names = {last=0}
	end
	
	if (info_back_button) then
		info_back_button:Kill()
	end
		
	if (info_actual_button) then
		info_actual_button:Kill()
	end
	
	if (last_info) then
		info_stack.last = info_stack.last + 1
		info_stack[info_stack.last] = last_info
	end
	
	info_back_button = info_root:AddChild(ImageButton())
	info_back_button:SetText("<-")
	info_back_button:UpdatePosition(base_position.x+(col*offset_x),base_position.y-(row*offset_y),0)
	info_back_button:SetScale(0.7,0.7,0.7)
	info_back_button:Disable()
	col = 1
	
	info_actual_button = info_root:AddChild(ImageButton("images/button_large.xml","normal.tex","focus.tex","disabled.tex"))
	local dir = ""
	for i=1, info_names.last do
		dir = dir.."/"..info_names[i]
	end
	info_actual_button:SetText(dir)
	info_actual_button:UpdatePosition(base_position.x+(3*offset_x),base_position.y-(row*offset_y),0)
	info_actual_button:SetScale(0.5,0.5,0.5)
	info_actual_button:Disable()
	row = row + 1
	col = 0
	
	if (info_stack.last ~= 0) then
		info_back_button:Enable()
		local back_info = info_stack[info_stack.last]
		info_back_button:SetOnClick(function()
			info_stack.last = info_stack.last - 1
			info_names.last = info_names.last - 1
			InfoTable(inst, back_info, nil, false)
		end)
	end
	
	for i,v in pairs(info_buttons) do
		v:Kill()
	end
	info_buttons = {}
	for i,v in pairs(info) do
		info_buttons[i] = info_root:AddChild(ImageButton())
		info_buttons[i]:UpdatePosition(base_position.x+(col*offset_x),base_position.y-(row*offset_y),0)
		info_buttons[i]:SetScale(0.7,0.7,0.7)
		info_buttons[i]:SetTextFocusColour(1,0,0,1)
		if (type(v) == "table") then
			info_buttons[i].image:SetTint(0,0.8,0.8,1)
			info_buttons[i]:SetText(tostring(i))
			info_buttons[i]:SetOnClick(function() 
				info_names.last = info_names.last + 1
				info_names[info_names.last] = tostring(i)
				InfoTable(inst, v, info, false) 
			end)
		else
			info_buttons[i]:SetText("["..tostring(i).."]\n"..tostring(v))
		end
		col = col + 1
		if (col == 8) then
			row = row + 1
			col = 0
		end
	end
end

local function IsInItemGroup(item,group)
	for i,v in pairs(group) do
		if (item and v == item) then
			return true
		end
	end
	return false
end

local function EquipItem(index)
	if (actual_item[index]) then
		local equiped_item
		if (index == 7) then
			equiped_item = Player.replica.inventory:GetEquippedItem("hands")
			if (equiped_item == nil or equiped_item.prefab ~= actual_item[index].prefab) then
				equiped_item = Player.replica.inventory:GetEquippedItem("head")
			end
		elseif (index == 8) then
			equiped_item = Player.replica.inventory:GetEquippedItem("body")
		elseif (index == 9) then
			equiped_item = Player.replica.inventory:GetEquippedItem("head")
		else
			equiped_item = Player.replica.inventory:GetEquippedItem("hands")
		end
		if (equiped_item == nil or actual_item[index].prefab ~= equiped_item.prefab) then
			Player.replica.inventory:UseItemFromInvTile(actual_item[index])
			--Player.replica.inventory:Equip(actual_item[index],nil)
		elseif (actual_item[index].prefab == equiped_item.prefab) then
			local active_item = Player.replica.inventory:GetActiveItem()
			if (not(index == 8 and active_item and active_item.prefab == "torch")) then
				Player.replica.inventory:UseItemFromInvTile(equiped_item)
			end
		end
	end
end

local function IsInGroup(item,group)
	if (item) then
		for i,v in pairs(group) do
			if (v == item.prefab) then
				return true
			end
		end
	end
	return false
end

local function IsItemEquipped(item)
	return IsInItemGroup(item, Player.replica.inventory:GetEquips())
end

local function CompareItems(item1,item2)
	if (not item1 and item2) then
		return item2
	elseif (not item2 and item1) then
		return item1
	elseif (not item1 and not item2) then
		return nil
	end
	
	local uses1, uses2
	if (item1.replica.inventoryitem.classified.percentused) then
		uses1 = item1.replica.inventoryitem.classified.percentused:value()
	end
	if (item2.replica.inventoryitem.classified.percentused) then
		uses2 = item2.replica.inventoryitem.classified.percentused:value()
	end
	
	if (not uses1 and uses2) then
		return item2
	elseif (not uses2 and uses1) then
		return item1
	elseif (not uses1 and not uses2) then
		return nil
	end
		
	--GLOBAL.TheNet:Say("compare uses 1: "..uses1..", 2: "..uses2,true)
	
	if (uses1 > uses2) then
		return item2
	elseif (uses2 > uses1) then
		return item1
	else
		return nil
	end
end

local function GetBestItem(item1,item2,group)
	if (not item1 and item2) then
		return item2
	elseif (not item2 and item1) then
		return item1
	elseif (not item1 and not item2) then
		return nil
	else
		local prefitem1, prefitem2
		for i,v in pairs(group) do
			if (v == item1.prefab) then
				prefitem1 = i
			end
			if (v == item2.prefab) then
				prefitem2 = i
			end
		end
		if (prefitem1 < prefitem2) then
			return item1
		elseif (prefitem1 > prefitem2) then
			return item2
		else
			local winner_item = CompareItems(item1,item2)
			if (winner_item) then
				return winner_item
			else
				return item1
			end
		end
	end
end

local function GetBestItemNoGroup(item1,item2)
	if (not item1 and item2) then
		return item2
	elseif (not item2 and item1) then
		return item1
	elseif (not item1 and not item2) then
		return nil
	else
		local winner_item = CompareItems(item1,item2)
		if (winner_item) then
			return winner_item
		else
			return item1
		end
	end
end

local function ChangeButtonIcon(index,item)
	if (item) then
		if (icon_button[index] and button[index]) then 
			button[index]:RemoveChild(icon_button[index])
			icon_button[index]:Kill()

			icon_button[index] = Image(item.replica.inventoryitem:GetAtlas(),item.replica.inventoryitem:GetImage())
			icon_button[index]:SetScale(0.8,0.8,0.8)
			button[index]:AddChild(icon_button[index])
			
			if (DISABLE_BUTTONS) then
				button[index]:Hide()
				icon_button[index]:Hide()
			end
		end
		if (letter[index]) then
			letter[index]:MoveToFront()
			
			if (DISABLE_BUTTONS) then
				letter[index]:Hide()
			end
		end
	end
end

local function CheckButtonItem(item)
	if (item.prefab == "multitool_axe_pickaxe" or item.prefab == "gears_multitool") then
		actual_item[2] = GetBestItem(actual_item[2],item,axes)
		ChangeButtonIcon(2,actual_item[2])
		actual_item[3] = GetBestItem(actual_item[3],item,pickaxes)
		ChangeButtonIcon(3,actual_item[3])
	elseif (IsInGroup(item,axes)) then
		actual_item[2] = GetBestItem(actual_item[2],item,axes)
		ChangeButtonIcon(2,actual_item[2])
	elseif (IsInGroup(item,scythes)) then
		actual_item[11] = GetBestItem(actual_item[11],item,scythes)
		ChangeButtonIcon(11,actual_item[11])
	elseif (IsInGroup(item,pickaxes)) then
		actual_item[3] = GetBestItem(actual_item[3],item,pickaxes)
		ChangeButtonIcon(3,actual_item[3])
	elseif (IsInGroup(item,shovels)) then
		actual_item[4] = GetBestItem(actual_item[4],item,shovels)
		ChangeButtonIcon(4,actual_item[4])
	elseif (item.prefab == "hammer") then
		actual_item[5] = GetBestItemNoGroup(actual_item[5],item)
		ChangeButtonIcon(5,actual_item[5])
	elseif (item.prefab == "pitchfork") then
		actual_item[6] = GetBestItemNoGroup(actual_item[6],item)
		ChangeButtonIcon(6,actual_item[6])
	elseif (IsInGroup(item,lights)) then
		actual_item[7] = GetBestItem(actual_item[7],item,lights)
		ChangeButtonIcon(7,actual_item[7])
	elseif (item.prefab == "cane") then
		actual_item[10] = GetBestItemNoGroup(actual_item[10],item)
		ChangeButtonIcon(10,actual_item[10])
	elseif (IsInGroup(item,weapons)) then
		actual_item[1] = GetBestItem(actual_item[1],item,weapons)
		ChangeButtonIcon(1,actual_item[1])
	elseif (IsInGroup(item,armors)) then
		actual_item[8] = GetBestItem(actual_item[8],item,armors)
		ChangeButtonIcon(8,actual_item[8])
	elseif (IsInGroup(item,helmets)) then
		actual_item[9] = GetBestItem(actual_item[9],item,helmets)
		ChangeButtonIcon(9,actual_item[9])
	end
end

local function ClearButtonItem(index)
	actual_item[index] = nil
	if (icon_button[index] and button[index]) then 
		button[index]:RemoveChild(icon_button[index])
		icon_button[index]:Kill()
		
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
		letter[index]:MoveToFront()
		
		if (DISABLE_BUTTONS) then
			button[index]:Hide()
			icon_button[index]:Hide()
			letter[index]:Hide()
		end
	end
end

local function ClearAllButtonItem()
	for i=1, cantButtons do
		ClearButtonItem(i)
	end
end

local containers_visited = {}

local function ContainerEvents(self)
	if (not IsInItemGroup(self,containers_visited)) then
		--CONTAINER ITEM GET EVENT--
		self.inst:ListenForEvent("itemget", function(inst, data)
			--GLOBAL.TheNet:Say("container itemget",true)
			if (finish_init and self:IsOpenedBy(Player)) then
				if (self.type == "pack") then
					if (not IsInGroup(data.item,backpacks)) then
						CheckButtonItem(data.item)
					end
				end
			end
		end)
		--CONTAINER ITEM LOSE EVENT--
		self.inst:ListenForEvent("itemlose", function(inst, data)
			--GLOBAL.TheNet:Say("container itemlose",true)
			if (finish_init and self:IsOpenedBy(Player)) then
				if (self.type == "pack") then
					ClearAllButtonItem()
					for i,v in pairs(Player.replica.inventory:GetItems()) do
						CheckButtonItem(v)
					end
					for i,v in pairs(Player.replica.inventory:GetEquips()) do
						CheckButtonItem(v)
					end
					if (Player.replica.inventory:GetActiveItem()) then
						CheckButtonItem(Player.replica.inventory:GetActiveItem())
					end
					local backpack = Player.replica.inventory:GetOverflowContainer()
					--GLOBAL.TheNet:Say("backpack: "..tostring(backpack),true)
					if (backpack) then				
						local items = backpack.inst.replica.container:GetItems()
						for i,v in pairs(items) do
							CheckButtonItem(v)
						end
					end
				end
			end
		end)
		table.insert(containers_visited, self)
	end
end

local function CheckAllButtonItem()
	if (finish_init) then
		ClearAllButtonItem()
		for i,v in pairs(Player.replica.inventory:GetItems()) do
			CheckButtonItem(v)
		end
		for i,v in pairs(Player.replica.inventory:GetEquips()) do
			CheckButtonItem(v)
		end
		if (Player.replica.inventory:GetActiveItem()) then
			CheckButtonItem(Player.replica.inventory:GetActiveItem())
		end
		local backpack = Player.replica.inventory:GetOverflowContainer()
		
		if (backpack) then
			ContainerEvents(backpack.inst.replica.container)
			local items = backpack.inst.replica.container:GetItems()
			for i,v in pairs(items) do
				CheckButtonItem(v)
			end
		end
	end
end

local function InventoryEvents(inst)
	--NEW ACTIVE ITEM EVENT--
	inst:ListenForEvent("newactiveitem", function(inst, data)
		--GLOBAL.TheNet:Say("newactiveitem, "..tostring(data.item),true)
		CheckAllButtonItem()
	end)
	--ITEM GET EVENT--
	inst:ListenForEvent("itemget", function(inst, data)
		--GLOBAL.TheNet:Say("itemget, "..tostring(data.item),true)
		if (finish_init) then
			if (not IsInGroup(data.item,backpacks)) then
				CheckButtonItem(data.item)
			end
		end
	end)
	--EQUIP EVENT--
	inst:ListenForEvent("equip", function(inst, data)
		--GLOBAL.TheNet:Say("equip, "..tostring(data.item),true)
		CheckAllButtonItem()
	end)
	--UNEQUIP EVENT--
	inst:ListenForEvent("unequip", function(inst, data) 
		--GLOBAL.TheNet:Say("unequip",true)
		CheckAllButtonItem()
	end)
	--ITEM LOSE EVENT--
	inst:ListenForEvent("itemlose", function(inst, data)
		--GLOBAL.TheNet:Say("itemlose",true)
		CheckAllButtonItem()
	end)
	--GOT NEW ITEM EVENT--
	inst:ListenForEvent("gotnewitem", function(inst, data)
		--GLOBAL.TheNet:Say("gotnewitem",true)
		if (finish_init) then
			if (not IsInGroup(data.item,backpacks)) then
				CheckButtonItem(data.item)
			end
		end
	end)
	--OTHER EVENTS--
	--inst:ListenForEvent("dropitem", function(inst, data) GLOBAL.TheNet:Say("dropitem",true) end)
	--inst:ListenForEvent("setowner", function(inst, data) GLOBAL.TheNet:Say("setowner",true) end)
	--inst:ListenForEvent("picksomething", function(inst, data) GLOBAL.TheNet:Say("picksomething",true) end)
	--inst:ListenForEvent("onremove", function(inst, data) GLOBAL.TheNet:Say("onremove",true) end)
end

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
	button[index]:SetOnClick(function(inst) return EquipItem(index) end)
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
	
	
	supergodmode_button = self:AddChild(ImageButton("images/hud.xml","inv_slot_spoiled.tex","inv_slot.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex"))
	supergodmode_button:SetPosition(-1420,80,0)
	supergodmode_button:SetOnClick(function(inst) return SendModRPCToServer(MOD_RPC[modname]["receivecommand"], commands.nextphase) end)
	supergodmode_button:MoveToFront()
	
	testButton = self:AddChild(ImageButton("images/hud.xml","inv_slot_spoiled.tex","inv_slot.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex"))
	testButton:SetPosition(-1340,80,0)
	testButton:SetOnClick(function(inst) return GLOBAL.ExecuteConsoleCommand(commands.startrain) end)
	testButton:MoveToFront()
	
	fun_button = self:AddChild(ImageButton("images/hud.xml","inv_slot_spoiled.tex","inv_slot.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex"))
	fun_button:SetPosition(-1260,80,0)
	fun_button:SetOnClick(function(inst) return SendModRPCToServer(MOD_RPC[modname]["receivecommand"], "c_give(\"honey\")") end)
	fun_button:MoveToFront()
	
	creativemode_button = self:AddChild(ImageButton("images/hud.xml","inv_slot_spoiled.tex","inv_slot.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex"))
	creativemode_button:SetPosition(-1180,80,0)
	creativemode_button:SetOnClick(function(inst) return SendModRPCToServer(MOD_RPC[modname]["receivecommand"], commands.creativemode) end)
	creativemode_button:MoveToFront()
	
	
	for k,cmd in ipairs(command_list) do
		command_button[k] = self:AddChild(ImageButton("images/hud.xml","inv_slot_spoiled.tex","inv_slot.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex","inv_slot_spoiled.tex"))
		command_button[k]:SetPosition(cmd.pos.x, cmd.pos.y, cmd.pos.z)
		command_button[k]:SetOnClick(function(inst) return SendModRPCToServer(MOD_RPC[modname]["receivecommand"], cmd.command_string) end)
		command_button[k]:MoveToFront()
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

local function Init(inst)
	inst:DoTaskInTime(1,function()
		Player = GLOBAL.ThePlayer
		
		InventoryEvents(inst)
		
		CheckAllButtonItem()
	end)
end
AddPlayerPostInit(Init)

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
local info_flag = false
GLOBAL.TheInput:AddKeyUpHandler(
	289, 
	function()
		if not GLOBAL.IsPaused() and IsDefaultScreen() then
			if (not info_flag) then
				InfoTable(Player,Player,nil,true)
				info_flag = true
			else
				ClearInfoTable()
				info_flag = false
			end
		end
	end
)
]]--

AddModRPCHandler(modname, "receivecommand", function(player, commandString) GLOBAL.ExecuteConsoleCommand(commandString) end)