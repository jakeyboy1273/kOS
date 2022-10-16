// This script takes tourists on a suborbital flight.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

// Launch and burn through the atmosphere
lock steering to heading(0, 90).
maneuver["launch"]().
until ship:verticalspeed < 0 {
    maneuver["autostage"]().
}.
lock steering to srfretrograde.

// Deploy the parachutes when the altitude is low enough
wait until alt:radar < 2500.
chutessafe on.