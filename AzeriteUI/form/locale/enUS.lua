local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "enUS", true)


-- General Stuff
--------------------------------------------
L["Enable"] = true 
L["Disable"] = true 
L["<Left-Click>"] = true
L["<Middle-Click>"] = true
L["<Right-Click>"] = true
L["CTRL+C"] = true

-- Welcome messages
--------------------------------------------
L["Welcome to the UI!"] = "|cffccccccWelcome to |r" .. GetAddOnMetadata(ADDON, "Title") .. "|cffcccccc!|r" 
L["Menu button location."] = "|cffe5b226<Left-Click>|r |cffcccccccog for game windows.|r|n"
						  .. "|cffe5b226<Right-Click>|r |cffcccccccog for actionbar options.|r"


-- Clock & Time Settings
--------------------------------------------
L["New Event!"] = true
L["New Mail!"] = true

L["%s to toggle calendar."] = true
L["%s to use local time."] = true
L["%s to use realm time."] = true
L["%s to use standard (12-hour) time."] = true
L["%s to use military (24-hour) time."] = true

L["Now using standard local time."] = true
L["Now using standard realm time."] = true
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


-- World Map Settings
--------------------------------------------
L["Reveal"] = true
L["Reveal Hidden Areas"] = true
L["Hide Undiscovered Areas"] = true
L["Disable to hide areas|nyou have not yet discovered."] = true
L["Enable to show hidden areas|nyou have not yet discovered."] = true
L["Press %s to copy."] = true


-- Config & Micro Menu
--------------------------------------------
-- Config button tooltip
-- *Doing it this way to keep the localization file generic, 
--  while making sure the end result still is personalized to the addon.
L["Main Menu"] = ADDON
L["Click here to get access to game panels."] = "Click here to get access to the various in-game windows such as the character paperdoll, spellbook, talents and similar, or to change various settings for the actionbars."
L["%s to toggle Blizzard Menu."] = "%s to toggle Blizzard Micro Menu."
L["%s to toggle Options Menu."] = "%s to toggle "..ADDON.." Options Menu."

-- Config Menu
L["Primary Bar"] = true
L["Button Count"] = true
L["%d Buttons"] = true
L["Button Visibility"] = true
L["MouseOver"] = true
L["MouseOver + Combat"] = true
L["Always Visible"] = true
L["Complimentary Bar"] = true
L["The Complimentary Action bar can have 6 or 12 buttons, and is the equivalent to the \"BottomLeft MultiActionBar\" in the Blizzard keybinding interface."] = true
L["Click to enable the Complimentary Action Bar."] = true
L["Click to disable the Complimentary Action Bar."] = true
L["Stance Bar"] = true
L["Click to enable the Stance Bar."] = true
L["Click to disable the Stance Bar."] = true
L["Pet Bar"] = true
L["Click to enable the Pet Action Bar."] = true
L["Click to disable the Pet Action Bar."] = true



-- Various Button Tooltips
--------------------------------------------
L["%s to leave the vehicle."] = true
L["%s to dismount."] = true

-- Minimap Compass Abbreviations
--------------------------------------------
L["N"] = true -- abbreviation for "North"
L["E"] = true -- abbreviation for "East"
L["S"] = true -- abbreviation for "South"
L["W"] = true -- abbreviation for "West"


-- Keybind Abbreviations
--------------------------------------------
L["Alt"] = "A"
L["Ctrl"] = "C"
L["Shift"] = "S"
L["NumPad"] = "N"
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
L["End"] = "En"
L["Home"] = "HM"
L["Insert"] = "Ins"
L["Mouse Wheel Down"] = "WD"
L["Mouse Wheel Up"] = "WU"
L["Num Lock"] = "NL"
L["Page Down"] = "PD"
L["Page Up"] = "PU"
L["Scroll Lock"] = "SL"
L["Spacebar"] = "Sp"
L["Tab"] = "Tb"
L["Down Arrow"] = "Dn"
L["Left Arrow"] = "Lf"
L["Right Arrow"] = "Rt"
L["Up Arrow"] = "Up"
