Frota
=====

An addon for Dota 2, It is a framework for sub game modes. Players connect to a server, then vote on what they would like to play, the most popular choice is loaded, people play it, then voting happens again.

###Current Status###
 - One option voting works, it still needs more work to look nice though
 - A basic gamemode system is in place
  - It has seperate categories for picking / gameplay based gamemodes
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
  - Custom hook related stuff is slowly being added, as well as upgrades
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

###Hooks###
 - **onPickingStart(frota)**: When the picking stage is loaded
 - **onGameStart(frota)**: When the game actually starts
 - **assignHero(frota, ply)**: A player needs a hero to be assigned
 - **onHeroKilled(frota, killedUnit, killerEntity)**: A player was killed by something (note: killerEntity could be null)
 - **onThink(frota, dt)**: Runs ~every 0.1 seconds, dt is the time since the last think, should be around 0.1 of a second
 - **onGameEnd(frota)**: Runs when the game mode finishes, you can do cleanup here

###Mod Events###
Mod events are all in the form of (frota, keys), you can find the arguments below via keys: keys.PlayerID

 - dota_player_used_ability
  - "PlayerID"        "short"
  - "abilityname"     "string"
 - dota_player_learned_ability
  - "PlayerID"        "short"
  - "abilityname"     "string"
 - dota_player_gained_level
  - "PlayerID"        "short"
  - "level"           "short"
 - dota_item_purchased
  - "PlayerID"        "short"
  - "itemname"        "string"
  - "itemcost"        "short"
 - dota_item_used
  - "PlayerID"        "short"
  - "itemname"        "string"
 - last_hit
  - PlayerID"         "short"
  - "EntKilled"       "short"
  - "FirstBlood"      "bool"
  - "HeroKill"        "bool"
  - "TowerKill"       "bool"
 - dota_item_picked_up
  - "itemname"        "string"
  - "PlayerID"        "short"
 - dota_super_creep
  - "teamnumber"      "short"
 - dota_glyph_used
  - "teamnumber"      "short"
 - dota_courier_respawned
  - "teamnumber"      "short"
 - dota_courier_lost
  - "teamnumber"      "short"
 - entity_killed
  - "entindex_killed"         "long"
  - "entindex_attacker"       "long"
  - "entindex_inflictor"      "long"
  - "damagebits"              "long"

###Translations###
 - Please make a pull request if you want to update translations
 - English by Ash47
 - Russian by lokkdokk
 - French by Canardlaquay
 - Hungarian by Easimer
 - German by DarkMio_mainframe
 - Turkish by ozen
 - Spanish by JosDW
 - Portuguese by Kobb
 - Finnish by SQL

###Maps###
 - riverofsouls by Z-Machine

###Up next###
 - More work on the game mode system
  - Which team actually won needs to be added (you can see via the scores, but an announcment would be nice)
 - Improved picking
  - Filters
  - Build picking / generation
 - More stuff :P
