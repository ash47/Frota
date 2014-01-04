Frota
=====

An addon for Dota 2, I intend for it to contain several sub game modes such as Legends of Dota and Random OMG

###Currnet Status###
 - One option voting works, it still needs more work to look nice though
 - A basic gamemode system is in place
  - It has seperate categories for picking / gameplay based gamemodes
  - Not much feature wise just yet
  - Still needs a restart feasture and a endGame / gg feature

###Gamemode Status###
 - **Legends of Dota**
  - It has a fully working drag and drop gui
  - A ready system is in place (game wont start until all players are ready -- A timelimit needs to be added)
  - There are GUI indicators to show what skills / hero each player has selected
 - **Pudge Wars**
  - Players will spawn as pudge if this gamemode is selected
 - **Arena**
  - Added header file for it

###How do I use this?###
 - Keep in mind it is still in development, and may be buggy
 - Download the zip (or clone if you are good enough)
 - Stick the files into "Steam\steamapps\common\dota 2 beta\dota\addons\Frota"
 - If done correctly, the following folder should exist "Steam\steamapps\common\dota 2 beta\dota\addons\Frota\HudSRC"
 - Reopen dota after each install / update (hud might not update)
 - Run the following command
  - dota_local_custom_enable 1;dota_local_custom_game Frota;dota_local_custom_map Frota;dota_force_gamemode 15;update_addon_paths;dota_wait_for_players_to_load 0;dota_wait_for_players_to_load_timeout 10;map riverofsouls;

###Up next###
 - More work on the game mode system
 - Improved picking
  - Hero picking
  - Filters
  - Build picking / generation