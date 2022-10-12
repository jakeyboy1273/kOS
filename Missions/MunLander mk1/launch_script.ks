// This script transfers to Munar orbit, then returns safely to Kerbin.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

// Launch and get to orbit
maneuver["launch"]().
maneuver["atmos_ascent"](125000, 90).
until apoapsis > 125000 {
    maneuver["autostage"]().
}
set mapview to true.
maneuver["circularise"]().

// Transfer to the Mun
print("transfering to Munar orbit").
maneuver["mun_transfer"](20000).

// Circularise into Mun orbit
print("Performing Munar capture burn").
maneuver["circularise"]().
wait 5.

// Deorbit out of Munar orbit
print("Deorbiting from Munar orbit").
maneuver["deorbit"]().

// Land on the Mun
print("Performing hoverslam").
maneuver["hoverslam"]().