// This script transfers to Munar orbit, then returns safely to Kerbin.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).
set instruments to lex().
runoncepath("0:/Libraries/" + instruments.ks).

// stage.

// // Deorbit out of Munar orbit
// print("Deorbiting from Munar orbit").
// maneuver["deorbit"]().

// Land on the Mun
set mapview to false.
print("Performing hoverslam").
maneuver["hoverslam"]().

// Perform and transmit science
wait 10.
instruments["get_all_science"]().
instruments["transmit_all_science"]().