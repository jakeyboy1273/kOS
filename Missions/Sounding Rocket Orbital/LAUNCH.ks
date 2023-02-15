// This script only performs a basic gravity turn.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

// Launch and burn through the atmosphere
maneuver["launch"]().
maneuver["atmos_ascent"](75000, 90).