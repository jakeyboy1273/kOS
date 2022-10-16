// This script transfers to Munar orbit, then returns safely to Kerbin.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).
set instruments to lex().
runoncepath("0:/Libraries/" + instruments.ks).

// Launch and get to orbit
maneuver["launch"]().
maneuver["atmos_ascent"](125000, 90).

set mapview to true.
maneuver["circularise"]().

// Transfer to the Mun
print("Transfering to Munar orbit").
maneuver["target_transfer"](mun, 20000).

// Circularise into Mun orbit
print("Performing Munar capture burn").
maneuver["circularise"]().
wait 5.

// Deorbit out of Munar orbit
print("Deorbiting from Munar orbit").
maneuver["deorbit"]().

// Land on the Mun
set mapview to false.
print("Performing hoverslam").
maneuver["hoverslam"]().

// Perform and transmit science
wait 10.
instruments["get_all_science"]().
instruments["transmit_all_science"]().