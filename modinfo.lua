name = "Console Command Shortcuts"
author = "rawii22 & lord_of_les_ralph"--"IceGrog"
description = "Adds buttons to the screen for some common commands.\n\n"
.."The following are the only bound commands:\n"
.."   C : Super God Mode\n"
.."   V : Next Phase\n"
.."   B : Creative Mode\n"
.."   N : Toggle Precipitation\n\n"
.."Right-click custom buttons 1 & 2 (bound to ',' and '.') to type in whatever command your heart desires. Then hit Enter or Accept to bind the command.\n\n"
.."IceGrog & squeek IceGrog & squeek, WITHOUT THEM WE WOULDN'T HAVE BEEN ABLE TO MAKE THIS MOD!"
version = "1.2"
version_compatible = "1.1"
icon = "modicon.tex"
icon_atlas = "modicon.xml"
forumthread = ""

api_version = 10
api_version_dst = 10
--priority = 5

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true
all_clients_require_mod = true
client_only_mod = false

server_filter_tags = {
	"console",
    "commands",
    "console commands",
    "console widget",
    "command widget",
	"console shortcuts",
	"command shortcuts",
}

configuration_options = {
  {
    name = "LETTERS",
    label = "Letters on Buttons",
    default = false,
    options = {
		{description = "NO", data = false},
		{description = "YES", data = true}
	}
  },
  {
    name = "DISABLE_KEYS",
    label = "Disable Keybinds",
    default = false,
    options = {
		{description = "NO", data = false},
		{description = "YES", data = true}
	}
  }
}
