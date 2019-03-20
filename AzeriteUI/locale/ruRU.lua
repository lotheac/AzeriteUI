local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "ruRU") -- ruRU locale written by Demorto @ our Discord! 

-- General Stuff
--------------------------------------------
L["Enable"] = "Включить" 
L["Disable"] = "Отключить" 
L["Enabled"] = "|cff00aa00Включено|r"
L["Disabled"] = "|cffff0000Отключено|r"
L["<Left-Click>"] = "<Левая кнопка>"
L["<Middle-Click>"] = "<Средняя кнопка>"
L["<Right-Click>"] = "<Правая кнопка>"

-- Core Messages
--------------------------------------------
L["Debug Mode is active."] = "Режим отладки активирован."
L["Type /debug to toggle console visibility!"] = "Наберите /debug для переключения отображения консоли!"

-- Clock & Time Settings
--------------------------------------------
L["New Event!"] = "Новое событие!"
L["New Mail!"] = "Новая почта!"
L["%s to toggle calendar."] = "%s открытия календаря."
L["%s to use local computer time."] = "%s отображение локального времени."
L["%s to use game server time."] = "%s отображение серверного времени."
L["%s to use standard (12-hour) time."] = "%s для 12-часового формата."
L["%s to use military (24-hour) time."] = "%s для 24-часового формата."
L["Now using local computer time."] = "Сейчас отображается локальное время."
L["Now using game server time."] = "Сейчас отображается серверное время."
L["Now using standard (12-hour) time."] = "Сейчас отображается время в 12-часовом формате."
L["Now using military (24-hour) time."] = "Сейчас отображается время в 24-часовом формате."

-- Network & Performance Information
--------------------------------------------
L["Network Stats"] = "Задержка сети"
L["World latency:"] = "Глобальная задержка:"
L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."] = "Это задержка сервера, которая влияет на произношение заклинаний, создание вещей, взаимодействие с другими игроками и неигровыми персонажами. Это значение, которое определяет, насколько задержаны ваши боевые действия." 
L["Home latency:"] = "Локальная задержка:"
L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."] = "Это задержка сервера, которая влияет на такие вещи, как мировой чат, чат гильдии, аукционный дом и некоторые другие вещи, не связанные с боем."

-- XP, Honor & Artifact Bars
--------------------------------------------
L["Normal"] = "Нормальный"
L["Rested"] = "Отдохнувший"
L["Resting"] = "Отдых"
L["Current Artifact Power: "] = "Текущая сила артефакта: "
L["Current Honor Points: "] = "Текущие очки чести: "
L["Current Standing: "] = "Текущее состояние: "
L["Current XP: "] = "Текущий опыт: "
L["Rested Bonus: "] = "Бонус отдыха: "
L["%s of normal experience gained from monsters."] = "%s опыта после убийства монстров."
L["You must rest for %s additional hours to become fully rested."] = "Вы должны отдохнуть в течении %s часов, чтобы полностью отдохнуть."
L["You must rest for %s additional minutes to become fully rested."] = "Вы должны отдохнуть в течении %s минут, чтобы полностью отдохнуть."
L["You should rest at an Inn."] = "Вы должны отдохнуть в Таверне."
L["%s to toggle Artifact Window>"] = "%s для отображения окна Артефакта>"
L["%s to toggle Honor Talents Window>"] = "%s для отображения окна PVP Талантов>"
L["%s to disable sticky bars."] = "%s что бы открепить информацию."
L["%s to enable sticky bars."] = "%s что бы закрепить информацию."  
L["Sticky Minimap bars enabled."] = "Информация об опыте\репутации закреплена на миникарте."
L["Sticky Minimap bars disabled."] = "Информация об опыте\репутации откреплена от миникарты."
L["to level %s"] = "до %s уровня" 
L["to %s"] = "до %s"
L["to next trait"] = "до следующей особенности"

-- Config & Micro Menu
--------------------------------------------
-- Config button tooltip
-- *Doing it this way to keep the localization file generic, 
--  while making sure the end result still is personalized to the addon.
L["Main Menu"] = ADDON
L["Click here to get access to game panels."] = "Нажмите сюда, чтобы получить доступ к различным игровым окнам, таким как персонаж, книга заклинаний, таланты или изменить различные настройки панелей команд."
L["%s to toggle Blizzard Menu."] = "%s для отображения Основного Меню."
L["%s to toggle Options Menu."] = "%s для отображения настроек "..ADDON.."."
L["%s to toggle your Bags."] = "%s для отображения ваших Сумок."

-- Config Menu
L["Debug Mode"] = "Режим отладки" 
L["Debug Console: %s"] = "Консоль отладки: %s" 
L["Load Console"] = "Загрузить консоль"
L["Unload Console"] = "Выгрузить консоль"
L["Reload UI"] = "Перезагрузить интерфейс"

L["ActionBars"] = "Панели команд"
L["Bind Mode: %s"] = "Режим назначения клавиш: %s"
L["Cast on Down: %s"] = "Срабатывать при нажатии: %s"
L["Button Lock: %s"] = "Блокировка кнопок: %s"
L["More Buttons"] = "Больше кнопок"
L["No Extra Buttons"] = "Нет доп. кнопок"
L["+%d Buttons"] = "+%d кнопок"
L["Extra Buttons Visibility"] = "Отображение доп. кнопок"
L["MouseOver"] = "По наведению"
L["MouseOver + Combat"] = "По наведению"
L["Always Visible"] = "Отображать всегда"
L["Stance Bar"] = "Панель стоек"
L["Click to enable the Stance Bar."] = "Нажмите для включения панели стоек."
L["Click to disable the Stance Bar."] = "Нажмите для выключения панели стоек."
L["Pet Bar"] = "Панель питомца"
L["Click to enable the Pet Action Bar."] = "Нажмите для включения панели питомца."
L["Click to disable the Pet Action Bar."] = "Нажмите для выключения панели питомца."

L["UnitFrames"] = "Фреймы"
L["Party Frames: %s"] = "Фреймы группы: %s"
L["Raid Frames: %s"] = "Фреймы рейда: %s"
L["PvP Frames: %s"] = "Фреймы PVP: %s"

L["HUD"] = "HUD"
L["Alerts: %s"] = "Оповещения: %s"
L["TalkingHead: %s"] = "Говорящие головы: %s"

L["NamePlates"] = "Индикаторы здоровья"
L["Auras: %s"] = "Ауры: %s"

L["Explorer Mode"] = "Режим исследователя"
L["Player Fading: %s"] = "Скрывать игрока: %s"
L["Tracker Fading: %s"] = "Скрывать трекер: %s"

L["Healer Mode: %s"] = "Режим лекаря: %s" 

-- Various Button Tooltips
--------------------------------------------
L["%s to leave the vehicle."] = "%s что бы покинуть транспорт."
L["%s to dismount."] = "%s что бы спешиться."

-- Abbreviations
--------------------------------------------
L["oom"] = "oom" -- out of mana
L["N"] = "С" -- compass North
L["E"] = "В" -- compass East
L["S"] = "Ю" -- compass South
L["W"] = "З" -- compass West

-- Keybind mode
L["Keybinds cannot be changed while engaged in combat."] = "Назначение клавиш не работает в бою."
L["Keybind changes were discarded because you entered combat."] = "Изменения клавиш были отменены, так как вы вступили в бой."
L["Keybind changes were saved."] = "Назначение клавиш были сохранены."
L["Keybind changes were discarded."] = "Назначение клавиш были отменены."
L["No keybinds were changed."] = "Назначение клавиш не были изменены."
L["No keybinds set."] = "Клавишы не назначены."
L["%s is now unbound."] = "%s не назначены."
L["%s is now bound to %s"] = "%s назначены для %s"

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
