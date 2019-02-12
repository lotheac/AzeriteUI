local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "enUS", true)
local isMac = IsMacClient()

-- General Stuff
--------------------------------------------
L["Enable"] = true 
L["Disable"] = true 
L["Enabled"] = "|cff00aa00Enabled|r"
L["Disabled"] = "|cffff0000Disabled|r"
L["<Left-Click>"] = true
L["<Middle-Click>"] = true
L["<Right-Click>"] = true

-- Clock & Time Settings
--------------------------------------------
L["New Event!"] = true
L["New Mail!"] = true
L["%s to toggle calendar."] = true
L["%s to use local computer time."] = true
L["%s to use game server time."] = true
L["%s to use standard (12-hour) time."] = true
L["%s to use military (24-hour) time."] = true
L["Now using local computer time."] = true
L["Now using game server time."] = true
L["Now using standard (12-hour) time."] = true
L["Now using military (24-hour) time."] = true

-- Network & Performance Information
--------------------------------------------
L["Network Stats"] = true
L["World latency:"] = true
L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."] = true 
L["Home latency:"] = true
L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."] = true

-- XP, Honor & Artifact Bars
--------------------------------------------
L["Normal"] = true
L["Rested"] = true
L["Resting"] = true
L["Current Artifact Power: "] = true 
L["Current Honor Points: "] = true
L["Current Standing: "] = true
L["Current XP: "] = true
L["Rested Bonus: "] = true
L["%s of normal experience gained from monsters."] = true
L["You must rest for %s additional hours to become fully rested."] = true
L["You must rest for %s additional minutes to become fully rested."] = true
L["You should rest at an Inn."] = true
L["%s to toggle Artifact Window>"] = true
L["%s to toggle Honor Talents Window>"] = true
L["%s to disable sticky bars."] = true 
L["%s to enable sticky bars."] = true 
L["Sticky Minimap bars enabled."] = true
L["Sticky Minimap bars disabled."] = true
L["to level %s"] = true 
L["to %s"] = true
L["to next trait"] = true

-- Config & Micro Menu
--------------------------------------------
-- Config button tooltip
-- *Doing it this way to keep the localization file generic, 
--  while making sure the end result still is personalized to the addon.
L["Main Menu"] = ADDON
L["Click here to get access to game panels."] = "Click here to get access to the various in-game windows such as the character paperdoll, spellbook, talents and similar, or to change various settings for the actionbars."
L["%s to toggle Blizzard Menu."] = "%s to toggle Blizzard Micro Menu."
L["%s to toggle Options Menu."] = "%s to toggle "..ADDON.." Options Menu."
L["%s to toggle your Bags."] = true

-- Config Menu
L["ActionBars"] = true
L["Cast on Down: %s"] = true
L["More Buttons"] = true
L["No Extra Buttons"] = true
L["+%d Buttons"] = true
L["Extra Buttons Visibility"] = true
L["MouseOver"] = true
L["MouseOver + Combat"] = true
L["Always Visible"] = true
L["Stance Bar"] = true
L["Click to enable the Stance Bar."] = true
L["Click to disable the Stance Bar."] = true
L["Pet Bar"] = true
L["Click to enable the Pet Action Bar."] = true
L["Click to disable the Pet Action Bar."] = true

L["UnitFrames"] = true
L["Party Frames: %s"] = true
L["Raid Frames: %s"] = true
L["PvP Frames: %s"] = true
L["HUD"] = true
L["Alerts: %s"] = true
L["TalkingHead: %s"] = true
L["NamePlates"] = true
L["Auras: %s"] = true
L["Explorer Mode"] = true
L["Player Fading: %s"] = true
L["Tracker Fading: %s"] = true

-- Various Button Tooltips
--------------------------------------------
L["%s to leave the vehicle."] = true
L["%s to dismount."] = true

-- Abbreviations
--------------------------------------------
L["oom"] = true -- out of mana
L["N"] = true -- compass North
L["E"] = true -- compass East
L["S"] = true -- compass South
L["W"] = true -- compass West

-- Keybind mode
L["Keybinds cannot be changed while engaged in combat."] = true
L["Keybind changes were discarded because you entered combat."] = true
L["Keybind changes were saved."] = true
L["Keybind changes were discarded."] = true
L["No keybinds were changed."] = true

-- Keybinds (visible on the actionbuttons)
L["Alt"] = "A"
L["Left Alt"] = "LA"
L["Right Alt"] = "RA"
L["Ctrl"] = "C"
L["Left Ctrl"] = "LC"
L["Right Ctrl"] = "RC"
L["Shift"] = "S"
L["Left Shift"] = "LS"
L["Right Shift"] = "RS"
L["NumPad"] = "" -- "N"
L["Backspace"] = "BS"
L["Button1"] = "B1"
L["Button2"] = "B2"
L["Button3"] = "B3"
L["Button4"] = "B4"
L["Button5"] = "B5"
L["Button6"] = "B6"
L["Button7"] = "B7"
L["Button8"] = "B8"
L["Button9"] = "B9"
L["Button10"] = "B10"
L["Button11"] = "B11"
L["Button12"] = "B12"
L["Button13"] = "B13"
L["Button14"] = "B14"
L["Button15"] = "B15"
L["Button16"] = "B16"
L["Button17"] = "B17"
L["Button18"] = "B18"
L["Button19"] = "B19"
L["Button20"] = "B20"
L["Button21"] = "B21"
L["Button22"] = "B22"
L["Button23"] = "B23"
L["Button24"] = "B24"
L["Button25"] = "B25"
L["Button26"] = "B26"
L["Button27"] = "B27"
L["Button28"] = "B28"
L["Button29"] = "B29"
L["Button30"] = "B30"
L["Button31"] = "B31"
L["Capslock"] = "Cp"
L["Clear"] = "Cl"
L["Delete"] = "Del"
L["End"] = "End"
L["Enter"] = "Ent"
L["Return"] = "Ret"
L["Home"] = "Hm"
L["Insert"] = "Ins"
L["Help"] = "Hlp"
L["Mouse Wheel Down"] = "WD"
L["Mouse Wheel Up"] = "WU"
L["Num Lock"] = "NL"
L["Page Down"] = "PD"
L["Page Up"] = "PU"
L["Print Screen"] = "Prt"
L["Scroll Lock"] = "SL"
L["Spacebar"] = "Sp"
L["Tab"] = "Tb"
L["Down Arrow"] = "Dn"
L["Left Arrow"] = "Lf"
L["Right Arrow"] = "Rt"
L["Up Arrow"] = "Up"
