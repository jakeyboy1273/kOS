// Import libraries
set telemetry to lex().
runoncepath("0:/Libraries/" + telemetry.ks).

print "maneuver: LOADING".

// Lexicon to load library functions into main script
global maneuver is lex(
    "init", init@,
    "safestage", safestage@,
    "throttle_down", throttle_down@,
    "eng_shutdown", eng_shutdown@,
    "launch", launch@,
    "autostage", autostage@,
    "add_maneuver", add_maneuver@,
    "remove_maneuver", remove_maneuver@,
    "execute_maneuver", execute_maneuver@,
    "lock_steering", lock_steering@,
    "maneuver_complete", maneuver_complete@,
    "atmos_ascent", atmos_ascent@,
    "circularise", circularise@,
    "mid_course_correction", mid_course_correction@,
    "mun_transfer", mun_transfer@,
    "deorbit", deorbit@,
    "hohmann", hohmann@,
    "pid_control", pid_control@
).
function init {}
maneuver["init"]().

global start_dv is -1.

global pid_last_p to -1.
global pid_last_time to -1.
global pid_total_p to -1.


// Stages when CPU is ready
function safestage {

    wait until stage:ready.
    stage.
}

// Maps throttle to gradually decrease as a burn ends
function throttle_down {
    parameter mnv.
    
    set a to 9.36.
    set b to 2/3.
    set c to 3.
    set d to max(mnv, b).
    set throttle_value to ((cos((180 / 3.1415) * a * (d - b))) / c) + ((c - 1) / c).
    return throttle_value.
}

// Shuts down engines
function eng_shutdown {

    lock throttle to 0.
    lock steering to prograde.
}

// Basic launch script
function launch {

    lock throttle to 1.
    safestage().
    wait 3.
}

// Autostages as engines flame out
function autostage {
    local need_stage is false.

    if stage:ready {
        list engines in engine_list.
        if engine_list:length > 0 {
            for engine in engine_list {
                if engine:ignition and engine:flameout {
                    set need_stage to true.
                    break.
                }
            }
        }
    }
    if need_stage {
        safestage().
    }
    return need_stage.
}

// Add maneuver to flight plan
function add_maneuver {
    parameter mnv.
    add mnv.
}

// Remove maneuver from flight plan
function remove_maneuver {
    parameter mnv.
    remove mnv.
}

// Execute maneuver
function execute_maneuver {
    parameter m_list.

    local mnv is node(m_list[0], m_list[1], m_list[2], m_list[3]).
    add_maneuver(mnv).
    local start_time is telemetry["start_time"](mnv).
    warpto(start_time - 15).
    wait until time:seconds > start_time - 10.
    lock_steering(mnv).
    wait until time:seconds > start_time.
    set original_dv to mnv:deltaV:mag.
    lock throttle to 1.
    wait until maneuver_complete(mnv, original_dv).
    lock throttle to 0.
    unlock steering.
    remove_maneuver(mnv).
}

// Lock steering to maneuver node
function lock_steering {
    parameter mnv.
    lock steering to mnv:burnvector.
}

// Checks for maneuver completion
function maneuver_complete {
    parameter mnv, mnv_dv.

    if start_dv = -1 {
        set start_dv to mnv_dv.
    }
    // TODO: create a second finish condition which checks if the maneuver node has pinged off
    //set finish_maneuver to false.
    //if mnv:deltaV:mag > 0.001 * (start_dv) {set finish_maneuver to true.}
    //if mnv:deltaV:mag > 0.1 * (start_dv) and abs(steering_angle - maneuver_angle) > 10 {set finish_maneuver to true.}
    if mnv:deltaV:mag > 0.005 * (start_dv) {
        lock delta_v_ratio to 1- (mnv:deltaV:mag / start_dv).
        lock throttle_value to throttle_down(delta_v_ratio).
        lock throttle to throttle_value.
        autostage().
        return false.
    }
    else {
        set start_dv to -1.
        return true.
    }
}

// Gravity turn through atmosphere
// TODO: make this body-agnostic
function atmos_ascent {
    parameter target_altitude, inclination.

    // Set the direction and pitch according to the targets
    set target_direction to inclination.
    //lock targetPitch to 88.963 - 1.03287 * alt:radar ^ 0.409511.
    lock target_pitch to 90 - 0.98049377 * alt:radar  ^ 0.40511.
    lock steering to heading(target_direction, target_pitch).

    // Control steering and throttle until target apoapsis is achieved
    list engines in engine_list.
    until apoapsis > target_altitude or engine_list:length = 0 {
        lock altitude_ratio to apoapsis / target_altitude.
        lock throttle_value to throttle_down(altitude_ratio).
        lock throttle to throttle_value.
        if target_pitch < 0 {
            lock steering to heading(target_direction, 0).
        }
        autostage().
    }
    eng_shutdown().
}

// Calculates and executes a circularisation maneuver
function circularise {
    local circ is list(0).
    set circ to telemetry["improve_converge"](circ, telemetry["eccentricity_score"]@, 0).
    if telemetry["altitude_delta"]() > 0 {
        execute_maneuver(list(time:seconds + eta:apoapsis, 0, 0, circ[0])).
    } else {
        execute_maneuver(list(time:seconds + eta:periapsis, 0, 0, circ[0])).
    }
}

// Perform a mid-course correction en route to a new body
function mid_course_correction {
    parameter new_periapsis.

    print("Warping to mid-course correction.").
    set warp_time to time:seconds + (orbit:nextpatcheta/4).
    warpto(warp_time).
    wait until time:seconds > (warp_time + 5).
    if orbit:nextpatch:periapsis < new_periapsis {
        print("Increasing periapsis to desired altitude...").
        lock steering to prograde. wait 5.
        until orbit:nextpatch:periapsis > new_periapsis {
            lock throttle to 0.1.
        }
        lock throttle to 0.
        unlock steering.
    } else {
        print("Decreasing periapsis to desired altitude...").
        lock steering to retrograde. wait 5.
        until orbit:nextpatch:periapsis < new_periapsis {
            lock throttle to 0.1.
        }
        lock throttle to 0.
        unlock steering.
    }
}

// Performs a transfer to the Mun
function mun_transfer {
    parameter mun_periapsis.

    local start_search_time is telemetry["ternary_search"](
            telemetry["angle_to_mun"]@,
            time:seconds + 30,
            time:seconds + 30 + orbit:period,
            1
        ).
    local transfer is list(start_search_time, 0, 0, 0).
    set transfer to telemetry["improve_converge"](transfer, telemetry["protect_from_past"](telemetry["mun_transfer_score"]@), mun_periapsis).
    maneuver["execute_maneuver"](transfer).
    wait 2.
    
    // Perform a mid-course correction if necessary
    if (abs(orbit:nextpatch:periapsis - mun_periapsis)/mun_periapsis) > 0.05 {
        mid_course_correction(mun_periapsis).
        wait 2.
    } else {
        print("No mid-course correction is required.").
    }
    
    
    // Warp to the Mun encounter
    warpto(time:seconds + orbit:nextPatchEta - 5).
    wait until body = Mun.
    wait 2.
}

// Perform a simple deorbit burn
function deorbit {
    lock steering to retrograde.
    wait 2.
    // TODO: function to ramp up throttle (same as the ramp down one?)
    lock throttle to 1.
    wait until ship:periapsis < 10000.
    lock throttle to 0.
    
}

// Perform a Hohmann transfer from the current orbit to the desired altitude
function hohmann {
    parameter height.

    set alti to telemetry["improve_converge"](telemetry["apoapsis_periapsis_score"]@, height).
    set dir to telemetry["altitude_delta"]().
    // Perform the maneuver depending on the ship's orbital position
    if dir > 0  {
        print "planning burn 1/2.".
        execute_maneuver(list(time:seconds + eta:apoapsis, 0, 0, alti[0])).
        print "planning circularisation burn 2/2.".
        circularise().
    } else {
        print "planning burn 1/2.".
        execute_maneuver(list(time:seconds + eta:periapsis, 0, 0, alti[0])).
        print "planning circularisation burn 2/2.".
        circularise().
    }
}

// PID control loop for a desired function
function pid_control {
    parameter k_parameters.
    parameter target_value.
    parameter current_value.

    set output to 0.
    set now to time:seconds.

    if pid_last_p = -1 {
        set pid_last_p to 0.
    }
    if pid_last_time = -1 {
        set pid_last_time to 0.
    }
    if pid_total_p = -1 {
        set pid_total_p to 0.
    }

    set p to target_value - current_value.
    set i to 0.
    set d to 0.

    if pid_last_time > 0 {
        set i to pid_total_p + ((p + pid_last_p)/2 * (now - pid_last_time)).
        set d to (p - pid_last_p) / (now - pid_last_time).
    }

    set output to p * k_parameters[0] + i * k_parameters[1] + d * k_parameters[2].

    set pid_last_p to p.
    set pid_last_time to now.
    set pid_total_p to i.

    autostage().
    return output.
}