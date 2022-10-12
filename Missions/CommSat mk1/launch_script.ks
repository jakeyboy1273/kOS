// This ship transfers to a low Kerbin orbit, then positions itself at a phase angle with a target craft.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

// Launch and get to orbit
maneuver["launch"]().
maneuver["atmos_ascent"](2863334, 90).
until apoapsis > 2863334 {
    maneuver["autostage"]().
}
set mapview to true.
maneuver["circularise"]().

// Go to the correct angle.
list targets in target_list.
for targ in target_list {
    if targ:name = ship:name {
        set target to targ.
        // break.
    }
}
maneuver["orbital_angle_align"](120).
set target to body.

unlock steering. wait 1.
set mapview to false.