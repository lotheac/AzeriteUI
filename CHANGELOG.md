# AzeriteUI Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.20] 2018-07-30
### Added
- Added red coloring and a spiked shield border to nameplate castbars when the cast is uninterruptable.

### Fixed
- Fixed a bug preventing you from canceling your own buffs, even when out of combat.

## [1.0.19] 2018-07-29
### Added 
- Added a custom vehicle exit button. A flight stop button is in the works!
- Added a North tag to the minimap.

### Changed
- Attempting an experimental change where the hidden action bar row is split into two sections, each reacting separately to mouseovers. The purpose is to limit number of fade-ins for those with a lesser number of total buttons used.  
- Friendly players will now get their nameplates colored as civilians, and not their class color which would make them appear as enemy players. 
- Relocated mirror- and start timer backdrop textures to the bar frame, not the timer frame, in an attempt to avoid the "hovering empty bar" bug.
- Rewrote the frame library's scale handling. All sizes are now relative to a virtual screen height of 1080, regardless or resolution or display size. Ratio will be the same as your window or monitor, except when the width is equal to or above three times a 16:10 monitor whereas it will be treated as a triple monitor setup and center the user interface on the middle monitor. 

### Fixed
- Vehicle unit frames should now be working. 

### Removed
- Removed the Blizzard vehicle exit and flight stop buttons.

## [1.0.18] 2018-07-28
### Added
- Added styling to Blizzard popup windows.
- Added styling to Blizzard mirror timers.
- Added styling to Blizzard start timers.
- Added a toned down dead and empty skull for the level display of dead units.

### Changed
- Upgraded the high level skull texture for bosses or very high level units.
- Modified boss unit frames to match target of target- and pet- unitframes in size and look. 
- Modified arena enemy unit frames to match target of target- and pet- unitframes in size and look. 
- Modified the player cast bar to match the previously listed frames in size and style.
- Increased XP- and ArtifactPower percentage text font sizes.

## [1.0.17] 2018-07-25
### Added
- Added some button textures to the various chat frame buttons.
- Added library to handle widget containers and element plugins. This is now used as a template for all unitframes. 

### Changed
- Updated the experience- and artifact power bar textures.
- Updated the target unit frame's unit classification- and targeting icons.
- The main chat window icons are now only visible when the editbox of the main frame is visible. 
- Moved aura filter methods to a single file to better be able to streamline the experience in upcoming updates. 

### Removed 
- Removed some redundant or outdated image files. 

## [1.0.16] 2018-07-24
### Changed
- Actionbutton grids will now be hidden for empty buttons, unless you've currently got a spell or item on the cursor.
- Now hiding the whole interface until 1.5 seconds after you've entered the world, to avoid seeing "flickering" from the textures and elements not created before this point.

## [1.0.15] 2018-07-24
### Changed
- Actionbuttons will now remain visible when a spell flyout is open or when spells are currently dragged using the mouse cursor.
- Actionbuttons that contain flyoutbars will now have a yellow arrow indicating that. 

## [1.0.14] 2018-07-24
### Fixed
- Fixed an bug causing an error when you tried to drop a spell onto your actionbars.

## [1.0.13] 2018-07-23
### Changed
- Shortened the delay after you leave the minimap xp toggle button until the xp/ap frame fades out, and made the actual fading a bit faster too. 

### Fixed
- Added a fallback for finding the window size when logging in with non-fullscreen windowed mode. Will rework the entire system to work better with more window sizes and larger or ultra wide screens, but this hotfix will do for now. 

## [1.0.12] 2018-07-23
### Changed
- Added a parent frame to the party frames handling hiding in raids, leaving the party frames own visibility drivers untouched.
- Made a larger part of the player energy crystal / mana orb area right-clickable in addition to the player health bar.
- Made the actionbutton mask texture far more perfect in shape to make it work better with actionbutton fade-outs.  

### Fixed 
- Fixed an issue that caused the Artifact Power bar to not properly be displayed on the first login. 

## [1.0.11] 2018-07-23
### Fixed
- Fixed an issue that caused action buttons containing spell flyouts to become tainted and prevent casting. 

## [1.0.10] 2018-07-23
### Added
- Added Player Pet unit frame.
- Added Target of Target (ToT) unit frame.
- Added missing spark maps to party- and bossframe cast-, absorb- and health bars.

### Changed
- Slightly increased the size of the floating player cast bar.

## [1.0.9] 2018-07-23
### Fixed
- Another party- and bossframe visibility driver update. It's an alpha. 

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
