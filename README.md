spleef
======
(https://forum.minetest.net/viewtopic.php?f=9&t=10612)

A spleef mini game for Minetest

This mod allows you to generate spleef arenas with to-the-top teleporters and a water/lava  pool.
You can set the number of levels, the space between them and their width.
The teleporter moves the players to the top of the active spleef on right click.
You can either make rectangular(default) or circular levels.

The mod is now usable with spleef_arena wich adds :
- dirt
- sand
- desert (desert sand)
- glass
- gravel
- leaves

as usable blocs for the arena if installed.
Those blocs can only be destroyed with the spleef stick.

Hope you'll enjoy this mod :D

HOWTO :
-------
```/spleef undo | do <nodename> <size> <nlevels> <space> [square|circle] [water|lava]```
- undo : restore the nodes changed by the latest arena (clean up after game or revert accidental griefing)
- do : generate arena with following parameters (in front right of you)
- nodename : snow (from this mod) or one from spleef_arena
- size : set the area width (min 3)
- nlevels : set the number of levels
- space : set the space between two levels
- [square|circle] : make rectangular or circular levels (optional)
- [water|lava] : create a water/lava pool (optional, [square|circle] must then be set)

/!\ The mod does not check for area protections. Be careful were you spawn the areas to avoid griefing !

Privs :
-------
spleef
Depends :
---------
default (spleef_arena)
Licence :
---------
lgpl 2.1
Installation:
-------------
Unzip the file and rename it to "spleef". Then move it to the mod directory.
