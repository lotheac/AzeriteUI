# AzeriteUI Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.8] 2018-07-22
### Fixed
- Updated the party unitframe visibility drivers so that party frames should be shown while in groups of 2-5 players. 

## [1.0.7] 2018-07-22
### Added
- Added the "Happy Feet" auras to the unitframe aura whitelist. 

### Changed
- Reduced patch 8.0.1 build number requirement to 27101, since some clients still can log in using that build. 

## [1.0.6] 2018-07-22
### Fixed
- The micro menu's toggle button's tooltip now properly disappears when you move the cursor away from the config button.
- Fixed a localization typo preventing mouse wheel keybinds from being abbreviated like other long keybind names are.

## [1.0.5] 2018-07-22
### Fixed
- Fixed a bad event registration in the unitframe library's aura element causing classpower to not properly toggle on target changes.

## [1.0.4] 2018-07-22
### Changed
- Increased the size of the target unit frame's hit rectangle so that the target portrait also can be clicked to access right-click menus and similar.
- Increased party unit frame size by roughly eight percent.
- Increased the font size of the mana orb value text.
- Increased font size of actionbutton keybinds and spell charges.
- Made the wood texture coloring slightly brighter across the entire interface.
- Aligned the actionbuttons slightly better with the player unit frame.
- Move tooltip unit levels to the top right side of the unit tooltips, instead of embedding it in the name. We should be able to see the names without clutter.

### Fixed
- Keybinds are now properly assigned to pet battle buttons while enganged in a pet battle. 
- Blizzard Microbuttons will no longer become and remain visible during and after pet battles.
- Mana orb transitions should once more be smooth and properly updated. 
- Fixed a bug in the tooltip libraries that could cause bugs in some locales while hovering over NPC unitframes. 

## [1.0.3] 2018-07-21
### Changed
- Limited amounts of full ActionButton updates to address a severe performance issue experienced from the ActionBar module while using abilities.

## [1.0.2] 2018-07-21
### Added
- Added boss unit frames with health, cast bars, and a few auras. 
- Added arena enemy / battleground flag carrier unit frames with health, cast bars, and a few auras. 

## [1.0.1] 2018-07-21
### Fixed
- Actionbutton cooldown counts should hopefully no longer be stuck at "0.0".
- Actionbutton cooldowns should now update when you lose control of your character.
- Actionbutton icon now properly changes when you pick up or put down spells on the bars.
- XP bar description telling what level we'll gain next now actually shows the next level instead of the current. 

## [1.0.0] 2018-07-20
- Initial commit.
