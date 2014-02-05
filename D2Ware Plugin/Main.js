// The unique ID on d2ware for this plugin
var pluginID = 'Frota';

// Allow our the map to change
console.findConVar('sv_hibernate_when_empty').setBool(false);

// A map of game modes that need custom maps
var maps = {
        "Dota": "dota",
        "Arena of the Dark Rift": "arenaotdr",
        "Evergreen Crossing": "evergreen_crossing",
        "Frostivus": "frostivus",
        "Keeper of the Kotol": "keeperofthekotol",
        "Labyrinth": "labyrinth0",
        "River Of Souls": "riverofsouls",
        "Runehill": "runehill"
}

// Have we changed the map?
var changedMap = false;

// The Map required for this gamemode
var requiredMap = 'dota_winter';

// Load in the lobby settings
plugin.get('LobbyManager', function(obj){
        // Attempt to grab options, make sure it exists
        var options = obj.getOptionsForPlugin(pluginID);
        if(!options) return;

        // Grab the name of the map they want
        var mapID = options['Map'];

        // Check if we need a custom map for this game mode
        var newMapID = maps[mapID];
        if(newMapID != null) {
            // Change the name of the map we want to play
            requiredMap = newMapID + ".bsp";
        }
});

// Change the map if required
game.hook('OnGameFrame',function() {
    // If we've already changed the map, don't change it again
    if(changedMap) return;

    // Change to the correct map
    server.command("dota_force_gamemode 15")
    server.command("dota_local_custom_enable 1")
    server.command("dota_local_custom_game Frota")
    server.command("dota_local_custom_map Frota")
    server.command("update_addon_paths")
    server.command("map " + requiredMap)

    // We've changed the map
    changedMap = true;
});