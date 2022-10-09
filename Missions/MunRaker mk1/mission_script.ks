// This script transfers to Munar orbit, then returns safely to Kerbin.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

//Launch and get to orbit
maneuver["launch"]().
maneuver["atmos_ascent"](125000, 90).
until apoapsis > 125000 {
    maneuver["autostage"]().
}
//doShutdown().
set mapview to true.
maneuver["circularise"]().

print("transfering to Munar orbit").
//Transfer to the Mun
maneuver["mun_transfer"](20000).

//Circularise into Mun orbit
maneuver["circularise"]().
wait 5.

//Burn back out of Mun orbit
lock steering to prograde. wait 5.
lock throttle to 1.
wait until ship:orbit:hasNextPatch. lock throttle to 0.

//wait until the new Kerbian periapsis, then deorbit
warpto(time:seconds + orbit:nextPatchEta - 5).
wait until body = Kerbin. wait 1.
lock steering to retrograde. wait 5.
lock throttle to 1.
wait until periapsis < 200000. lock throttle to 0.5.
wait until periapsis < 40000. lock throttle to 0.1.
wait until periapsis < 1000. lock throttle to 0.

// Deploy the parachutes when the altitude is low enough
wait until alt:radar < 2500.
chutessafe on. unlock steering.