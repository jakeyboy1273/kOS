// This script gets into orbit then rescues a strander Kerbal.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

// Launch and get to orbit
maneuver["launch"]().
maneuver["atmos_ascent"](180000, 90).

// set mapview to true.
maneuver["circularise"]().

// Rendezvous with the stranded Kerbal
maneuver["match_inclination"]().
maneuver["orbital_angle_align"]().
maneuver["rendezvous"]().