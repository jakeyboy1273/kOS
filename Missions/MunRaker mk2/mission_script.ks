// This ship transfers to a low Munar orbit, performing science experiments along the way, then returns safely to Kerbin.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

set instruments to lex().
runoncepath("0:/Libraries/" + instruments.ks).

// Launch and get to orbit
maneuver["launch"]().
maneuver["atmos_ascent"](180000, 90).
until apoapsis > 180000 {
    maneuver["autostage"]().
}
set mapview to true.
maneuver["circularise"]().

print("transfering to Munar orbit").
// Transfer to the Mun, then collect science
maneuver["target_transfer"](mun, 45000). wait 5.
instruments["get_all_science"]().

// Collect more science once in a lower orbit
wait until ship:altitude < 60000.
instruments["get_all_science"]().

// Wait until the new Kerbian periapsis, then deorbit
warpto(time:seconds + orbit:nextPatchEta - 5).
wait until body = Kerbin. wait 1.
lock steering to retrograde. wait 5.
lock throttle to 1.
wait until periapsis < 200000. lock throttle to 0.5.
wait until periapsis < 40000. lock throttle to 0.1.
wait until periapsis < 1000. lock throttle to 0.

// Wait until entering the atmosphere, then stage
wait until ship:altitude < 70000.
stage.

// Deploy the parachutes when the altitude is low enough
wait until alt:radar < 2500.
chutessafe on. unlock steering.
wait 10.
stage.