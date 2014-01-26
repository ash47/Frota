Frota
=====

An addon for Dota 2, It is a framework for sub game modes. Players connect to a server, then vote on what they would like to play, the most popular choice is loaded, people play it, then voting happens again.

###Picking Gamemodes###
 - **All Pick**
  - You can select your hero from the picking screen
 - **Legends of Dota**
  - It has a fully working drag and drop gui
  - A ready system is in place, and a time limit for picking exists (2 mins by default)
  - There are GUI indicators to show what skills / hero each player has selected
  - There is a fully working drag and drop, hero selector
 - **Random OMG**
  - Seems to work, you get a random hero, 3 skills and an ult
 - **Pure Skill**
  - Play as pudge with meat hook, sacred arrow, skewer and ice shards, each spell has no mana cost!
  - Custom hook related stuff is slowly being added, as well as upgrades
 - **Invoker Wars**
  - You get 4 spells with no mana cost to wreck havok.
 - **Puck Wars**
  - Play as Puck, most of Puck's spells have no mana cost.
 - **Tiny Wars**
  - Players spawn as tiny, all of his spells have no mana cost.

###Gameplay Gamemodes###
 - **PvP Arena**
  - A PvP arena game mode
 -** King of the Hill**
  - Fight to get more players on top of the point than the enemy team.

###Picking + Gameplay Gamemodes###
 - **Rabbits vs. Sheep**
  - What does the Rabbit say?
 - **Warlocks**
  - Play as a novice warlock, haphazardly blinking around the map and play hot potato with an unstable spell.

###Addons###
 - **WTF Mode**
  - Players have the option to turn WTF Mode on, making all spells and items have no mana cost and no cooldown.
 - **Free Blink Dagger**
  - Everyone will spawn with a free blink dagger.
 - **No Buying**
  - Items can't be bought from the shop.
 - **DM Mode**
  - Every time you die, you respawn as a new hero!
 - **Fat-o-Meter**
  - Every time a hero kills creep or another hero, he grows a little bit.
 - **Unlimited Mana**
  - Players have max mana regen.
 
###How do I use this?###
 - Keep in mind it is still in development, and may be buggy
 - **IMPORTANT** Dota will only load the first plugin in your addons folder, to prevent this, move all other addons out of your addons folder. (I moved mine into an addons_disabled folder) - ONLY the host has to do this. This is not required if you use d2fixups
 - There is another guide here: http://www.reddit.com/r/Dota2Modding/comments/1ueg70/custom_gamemodes_how_to_play_frota_host_your_own/
 - Download the zip (or clone if you are good enough)
 - Stick the files into "Steam\steamapps\common\dota 2 beta\dota\addons\Frota"
 - If done correctly, the following folder should exist "Steam\steamapps\common\dota 2 beta\dota\addons\Frota\HudSRC"
 - Reopen dota after each install / update (hud might not update)
 - Run the following command
  - dota_local_custom_enable 1;dota_local_custom_game Frota;dota_local_custom_map Frota;dota_force_gamemode 15;update_addon_paths;dota_wait_for_players_to_load 0;dota_wait_for_players_to_load_timeout 10;map riverofsouls;
 - **NOTE** If you reach the hero selection screen, it means Frota didn't load correctly! Frota should override / skip the hero selection screen, and  take you directly to a vote screen! Please ensure you removed Frostivus (and any other addons) and then restart your client.

###How do I play with friend?###
 - You need to setup a dedicated server, and port forward (or, you can use hamachi, but port forward is easier)
 - Follow the guide here: https://forums.alliedmods.net/showpost.php?p=1911667&postcount=64
 - Your addons folder should look like this (note: No DLL files are pictured) http://i.imgur.com/sUtBFki.jpg
 - Google how to port forward, it is different for every router!

###Is there a way I can spawn test heroes?###
 - Try the console command 'fake', it will fill the server with fake clients, and give each a hero (it requires sv_cheats 1)

###Hooks & Mod Events###
 - There are many hooks and mod events to make making gamemodes easier.
 - See the top of gamemodes.lua for the latest list of hooks and mod events.

###Translations###
 - Please make a pull request if you want to update translations
 - English by [Ash47][1]
 - Russian by [lokkdokk][2], [Shuker][3]
 - French by Canardlaquay
 - Hungarian by [Easimer][4]
 - German by [DarkMio_mainframe][5]
 - Turkish by ozen
 - Spanish by JosDW
 - Portuguese by [Kobb][8]
 - Finnish by [SQL][9]
 - Chinese by [cs-italy][10]

###Maps###
 - riverofsouls by [Z-Machine][11]
 - deadlock by [Z-Machine][11]
 - runehill by Azarak908

###Issues that need help###
 - When a player leaves the game, their slot isn't removed, and hence, someone else can't connect and take their place, this is caused by the limit of 5 players per team, someone solve this :P

###Up next###
 - More work on the game mode system
  - Which team actually won needs to be added (you can see via the scores, but an announcment would be nice)
 - Improved picking
  - Filters
  - Build picking / generation
 - Adding more addons + gamemodes
 - The hud needs to be rewritten, once we know how to stop the hud from freezing (causes it to miss events), this rewrite will happen.

[1]: https://github.com/ash47
[2]: https://github.com/lokkdokk
[3]: https://github.com/theShuker
[4]: https://github.com/Easimer
[5]: https://github.com/DarkMio
[8]: https://github.com/KobbDota
[9]: https://github.com/justSQL
[10]: https://github.com/cs-italy
[11]: https://github.com/Z-Machine
