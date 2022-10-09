// This mission launches the ship into a low Kerbin orbit.

// Import libraries
set instruments to lex().
set maneuver to lex().
runoncepath("0:/Libraries/" + instruments.ks).
runoncepath("0:/Libraries/" + maneuver.ks).

// Launch and burn through the atmosphere
maneuver["launch"]().
maneuver["atmos_ascent"](160000, 90).

// Jettison the launcher once in space
wait until ship:altitude > 70000.
maneuver["safestage"](). wait 1.
maneuver["safestage"](). wait 1.
maneuver["safestage"](). wait 1.

// Circularise, then deploy instruments
maneuver["circularise"]().
wait 5.
lights on. bays on. wait 2.
instruments["deploy_instruments"]().