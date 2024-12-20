// This mission performs a high flyby of the Mun, then returns safely to Kerbin.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).
set instruments to lex().
runoncepath("0:/Libraries/" + instruments.ks).

//Launch and get to orbit
maneuver["launch"]().
maneuver["atmos_ascent"](120000, 90).
until apoapsis > 120000 {
    maneuver["autostage"]().
}
set mapview to true.
maneuver["circularise"]().
instruments["get_all_science"]().


print("transfering to Munar orbit").
//Transfer to the Mun
maneuver["target_transfer"](mun, 200000). wait 5.
instruments["get_all_science"]().

//wait until the new Kerbian periapsis, then deorbit
warpto(time:seconds + orbit:nextPatchEta - 5).
wait until body = Kerbin. wait 1.
lock steering to retrograde. wait 5.
lock throttle to 1.
wait until periapsis < 200000. lock throttle to 0.5.
wait until periapsis < 40000. lock throttle to 0.

// Jettison the engine after entering the atmosphere
wait until ship:altitude < 70000.
set mapview to false. wait 1.
stage.

// Deploy the parachutes when the altitude is low enough
wait until alt:radar < 2500.
chutessafe on. wait 1.
unlock steering. wait 1.
wait 10.
stage.