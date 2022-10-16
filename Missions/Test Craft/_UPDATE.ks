// This script transfers to Munar orbit, then returns safely to Kerbin.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

maneuver["target_transfer"](minmus, 5000).