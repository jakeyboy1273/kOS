// This script performs a suborbital burn then lands safely.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

// Launch and burn through the atmosphere
maneuver["launch"]().
maneuver["atmos_ascent"](120000, 270).

// Wait until the ship is descending
wait until ship:verticalspeed < 0.
lock steering to ship:retrograde.

// Deploy the parachutes when the altitude is low enough
wait until alt:radar < 2500.
chutessafe on.