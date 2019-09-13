name = "Console Command Shortcuts"
version = "1.0"
description = "Adds buttons to the screen for common commands.\nIceGrog IceGrog IceGrog IceGrog IceGrog, WITHOUT HIM WE WOULDN'T HAVE BEEN ABLE TO MAKE THIS MOD!"
author = "rawii22 & lord_of_les_ralph"--"IceGrog"
forumthread = ""
icon = "modicon.tex"
icon_atlas = "modicon.xml"

api_version = 10

dont_starve_compatible = true
reign_of_giants_compatible = true
all_clients_require_mod = false
dst_compatible = true
client_only_mod = true


local keyslist = {}
local string = ""

local FIRST_NUMBER = 48
for i = 1, 10 do
	local ch = string.char(FIRST_NUMBER + i - 1)
	keyslist[i] = {description = ch, data = ch}
end

local FIRST_LETTER = 65
for i = 11, 36 do
	local ch = string.char(FIRST_LETTER + i - 11)
	keyslist[i] = {description = ch, data = ch}
end

keyslist[37] = {description = "DISABLED", data = false}

numbers = {}
for i = 0, 5 do
	numbers[i+1] = {description = i, data = i}
end

configuration_options = {
  {
    name = "Letters",
    label = "Letters on Buttons",
    default = false,
    options = {
		{description = "NO", data = false},
		{description = "YES", data = true}
	}
  },
  {
    name = "Disable_Keys",
    label = "Disable Keybinds",
    default = false,
    options = {
		{description = "NO", data = false},
		{description = "YES", data = true}
	}
  },
  {
    name = "Disable_Buttons",
    label = "Disable Buttons",
    default = false,
    options = {
		{description = "NO", data = false},
		{description = "YES", data = true}
	}
  }
}
