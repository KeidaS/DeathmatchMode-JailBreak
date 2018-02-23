# DeathmatchMode-JailBreak
Enables deathmatch for players in a specific zone.

Cmd !enabledm-> Open a menu that allows you to select the game mode:
  – Headshot
  – Normal
  
Once selected the game mode you have to select the weapon with which you want the Terrorist to kill themselfes (currently there is only USP, Desert Eagle, AWP, Scout and Knife). At the moment you select the weapon, all the terrorists who are in the area will be given that weapon (if they already had one, will be removed) and the knife will be removed (not if the weapon is Knife).

Cmd !disabledm -> Disables the Deathmatch Mode. The terrorists who remain in the area will lose the weapon and the knife will be returned.

Aclarations:
 - The !disabledm command will be applied automatically at the end of the round.
 - The Terrorists within the area can not hurt CTs outside the area, and Terrorists who are outside can not harm Terrorists inside and vice versa. CTs can not damage each other either.
 - The CTs do not lose the weapon if they are inside the zone when activating the game mode.
 - If a Terrorist leaves the area during the game he will lose the weapon and get a knife.
 

Need to include this plugin for the zones: https://github.com/Franc1sco/DevZones
