# AzeriteUI Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.40] 2018-08-15
### Added
- A Group Finder Eye is now available on the minimap when queued using the group finder.

## [1.0.39] 2018-08-15
### Changed
- Parented the Blizzard ObjectivesTracker to our own master frame, to prevent it from covering the Blizzard Micro Menu.
- Continued the work on code restructuring towards the new single file layout system. 
- Changed how various textures are attached to unit frame aura buttons to attempt to fix the "misplaced border" issues that I so far have been unable to reproduce. 
- Added some bonus bars to the actionbutton page switcher for all classes, also added an action icon update regardless of whether or not the actual page was changed. 
- The target of target unit frame is now hidden when your current target is a harmless level 1 critter, or if the target of the target is yourself as this is already indicated by the red eye on the target portrait.

### Fixed
- Fixed bad positioning of the player frame combat indicator after recent code restructuring. 
- Fixed the missing minimap zone- and latency texts. 
- Fixed a lingering "ExtraPower" bug after the code restructuring.

## [1.0.38] 2018-08-14
### Changed
- Moved Blizzard ObjectivesTracker modifications to its own file. Remember to restart game for the file to be discovered!

### Fixed
- Fixed more bugs related to the Blizzard ObjectivesTracker.

## [1.0.37] 2018-08-14
### Fixed
- Fixed bugs related to the Blizzard ObjectivesTracker.

## [1.0.36] 2018-08-14
### Fixed
- User interface works for non-mana classes again now. Sorry! 

## [1.0.35] 2018-08-13
### Added
- Added back the Blizzard ObjectivesTracker. Finished or not, you'll be needing it now! 

### Changed
- Let's call it a beta. 

## [1.0.34] 2018-08-12
### Added
- Added a minor welcome message to point new users towards the cogwheel settings button.

### Changed
- Started splitting layout data and modules applying that data into separate folders and files.
- Complimentary bar buttons will now always be displayed as 2 rows of buttons when the layout allows for it. This means that when the primary bar has 7 or 12 buttons, the complimentary bar will show always be displayed as 2 rows, either with 3 buttons in each row or 12. It makes sense when you see it. 
- Update actionbutton hover areas to match where the buttons are actually placed with the various layouts now. Goal is to minimize screen usage, and keep the hovereffect to the actual button areas.

### Fixed
- The minimap zone text should now properly update when moving through outdoor zones. 

## [1.0.33] 2018-08-11
### Added
- Added an options menu available from right-clicking the cogwheel found in the bottom right corner of the screen. Current options are all related to visibility, button counts and fading settings of the actionbuttons, but more will come! The menu is fully usable even during combat, as it's written mainly using the restricted environment and not regular lua. So you don't have to wait until you're dead to make that bar with your life saving ability visible. 

### Changed
- Started restructuring the code for easier UI mass production later on. 

### Fixed
- Fixed an issue that would sometimes cause custom tooltips to be drawn in a lower FrameStrata. All tooltips are always put in the TOOLTIP FrameStrata when shown now.
- Fixed a bug in the module library that would prevent it from ever returning existing modules. 
- Fixed a bug in the chat command library that would prevent chat commands from receiving a proper argument list. Lucky for us we're not using any chat commands so far, so technically it was a non issue. 

## [1.0.32] 2018-08-09
### Changed
- Workaround for Auctionator's dumb coding style and `EnumerateFrames()` usage.

## [1.0.31] 2018-08-08
### Fixed
- Having more than 3 friendly auras on the target unit frame should no longer produce a nil bug.

## [1.0.30] 2018-08-07
### Changed
- Player and target unit frame aura icons have had their border slightly slimmed down, and their icons slightly fattened up. 
- Personal Resource Display (personal nameplate) is now always fully opaque when shown, it does not follow the opacity rules applied to the rest of the nameplates. 

### Fixed 
- Fixed an issue where auras wouldn't probably be hidden when their timer ran out. 

## [1.0.29] 2018-08-06
### Changed
- Added a slightly fuzzier edge to the XP- and ArtifactPower ring bars to smoothe them out a bit, as the pixelation from Blizzard's cropping and rotation was a bit much. 

### Fixed
- Minimap should properly hide minimap icons from other addons now. A custom buttonbag and/or MBB integration is in the works, though not fully ready yet.

### Removed
- Removed the rested bonus XP bar. Will be adding a new indicator soon. 

## [1.0.28] 2018-08-03
### Added
- Added health percentage on the target unit frame for bosses.
- Added item tooltips for actionbuttons containing items and not actions or spells.

### Changed
- The small boss only unit frames now display a health number when at full health, but a percentage value only once the fight has begun and their health started dropping. Gotta see when they hit those magic percentages linked to their abilities! 

## [1.0.27] 2018-08-02
### Changed
- Threat coloring is now only visible in grouped instances.
- Class resources are now only visible when the target can be attacked.
- Chat frames, breath timers and Azerite styled tooltips should now follow the rest of the non-Blizzard parts in scaling.

### Fixed
- Fixed an issue where sometimes after a major lagspike the minimap post update could attempt to resize it in combat and cause a taint. 

## [1.0.26] 2018-08-01
### Changed
- Moved nameplates to the BACKGROUND strata, to avoid them overlapping the unitframes and other elements.
- Minimap northtag is now hidden while the XP- and Artifact Power bars are visible.
- Adjusted positions of minimap texts like the time, zone name, latency and so on. Also adjusted the overlay ring bar texts. 
- Moved the new mail icon slightly down and closer to the minimap texts.
- Slightly increased the font size of the unit name in the target unit frame, and moved it slightly up and right towards the portrait.
- Slighlty increased the font size of the unit level in the target unit frame. 

### Fixed
- Found and fixed the wrongly named texture path that was causing a big black box instead of a threat texture around the target frame health bar of enemies with a level capped border texture. No more black box!

### Removed
- Removed a redundant file that was re-applying the faulty taint fix that created taints instead of removing them. We got two bugs for the price of one, when we actually wanted none. Fixed. 

## [1.0.25] 2018-08-01
### Changed
- Changed the Shaman class color to a non-Mana blue. 
- Made the neutral reaction color more yellow.
- Unitframe tooltips from battle pets should now have their unit names and health bars colored according to the battle pet's rarity.  

### Fixed
- Removed a taint fix related to chat frames and overlay glows that created taints instead of fixing them. 

## [1.0.24] 2018-07-31
### Fixed
- Fixed a nil bug occurring when opening to some addon menus.

## [1.0.23] 2018-07-31
### Added
- Added threat textures for player power crystal, player mana orb and target portrait frame. The display should be much more balanced and consistent now. 

### Changed
- The chat emote / language button now has a different texture. 
- Reduced the chat button size with 20% of their previous size - or 25% the current size, all depending on which size you wish to relate that number to. 
- Players that have manually disabled experience gains will now get the level capped version of the player frame. This also applies to the target frame when they are targeting themselves. Idea is to make twinks feel more epic. It is currently not decided whether or not we're going to apply this to all players with experience gains removed while inside a twinked battleground. 

### Fixed
- Rewrote the health coloring plugin to accomodate for the rare cases where the class of a player isn't available.

## [1.0.22] 2018-07-30
### Added
- Added threat textures for player- and target unit frame health bars. Power/Mana- and portrait coloring coming!

### Changed
- Slightly reduced the size of the spell activation highlights as they were completely covering the button border texture.

### Fixed
- Added missing events to properly update spell activation overlay glows on the actionbuttons.

## [1.0.21] 2018-07-29
### Changed
- Corrected changelog date for the previous entry, as it was in the actual future. 
- Changed the size and alignment of the protected nameplate cast border to fit the health bar better.
- Removed some more redundant statusbar library callbacks, as they could potentially cause endless loops and stack overflows.

## [1.0.20] 2018-07-29
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
