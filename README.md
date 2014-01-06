Frota
=====

An addon for Dota 2, I intend for it to contain several sub game modes such as Legends of Dota and Random OMG

###Current Status###
 - One option voting works, it still needs more work to look nice though
 - A basic gamemode system is in place
  - It has seperate categories for picking / gameplay based gamemodes
  - Not much feature wise just yet
  - If a gamemode supports scores, they will be shown
 - "Version control" is now in place -- clients will be notified if they have an outdated version of Frota

###Gamemode Status###
 - **All Pick**
  - You can select your hero from the picking screen
 - **Legends of Dota**
  - It has a fully working drag and drop gui
  - A ready system is in place, and a time limit for picking exists (2 mins by default)
  - There are GUI indicators to show what skills / hero each player has selected
  - There is a fully working drag and drop, hero selector
 - **Pudge Wars**
  - Players will spawn as pudge if this gamemode is selected
  - First team to 10 wins
 - **Tiny Wars**
  - Players will spawn as tiny if this gamemode is selected
  - First team to 10 wins
 - **PvP Arena**
  - A PvP arena game mode, first team to 10 wins
 - **Random OMG**
  - Seems to work, you get a random hero, 3 skills and an ult
 - **sunstrikewars**
  - Added header + language files for it
  - Lots of hooks need to be added before this game mode can be made
 - **pureskill**
  - An unoffical gamemode: Play as mirana with skewer, arrow, meat hook and ice shards.

###How do I use this?###
 - Keep in mind it is still in development, and may be buggy
 - **IMPORTANT** Dota will only load the first plugin in your addons folder, to prevent this, move all other addons out of your addons folder. (I moved mine into an addons_disabled folder) - ONLY the host has to do this. This is not required if you use d2fixups
 - Download the zip (or clone if you are good enough)
 - Stick the files into "Steam\steamapps\common\dota 2 beta\dota\addons\Frota"
 - If done correctly, the following folder should exist "Steam\steamapps\common\dota 2 beta\dota\addons\Frota\HudSRC"
 - Reopen dota after each install / update (hud might not update)
 - Run the following command
  - dota_local_custom_enable 1;dota_local_custom_game Frota;dota_local_custom_map Frota;dota_force_gamemode 15;update_addon_paths;dota_wait_for_players_to_load 0;dota_wait_for_players_to_load_timeout 10;map riverofsouls;
 - **NOTE** If you reach the hero selection screen, it means Frota didn't load correctly! Frota should override / skip the hero selection screen, and  take you directly to a vote screen! Please ensure you removed Frostivus (and any other addons) and then restart your client.

###Translations###
 - Please make a pull request if you want to update translations
 - English by Ash47
 - Russian by lokkdokk
 - French by Canardlaquay
 - Hungarian by Easimer
 - German by DarkMio_mainframe
 - Turkish by ozen
 - Spanish by JosDW

###Maps###
 - riverofsouls by Z-Machine

###Up next###
 - More work on the game mode system
  - Which team actually won needs to be added (you can see via the scores, but an announcment would be nice)
  - Lots of hooks (init, heroSpawn, heroDie) need to be added
 - Improved picking
  - Filters
  - Build picking / generation
 - More stuff :P
