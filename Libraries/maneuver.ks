// Import libraries
set telemetry to lex().
runoncepath("0:/Libraries/" + telemetry.ks).

print "maneuver: LOADING".

// Lexicon to load library functions into main script
global maneuver is lex(
    "init", init@,
    "safestage", safestage@,
    "throttle_control", throttle_control@,
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
    "orbital_angle_align", orbital_angle_align@,
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
function throttle_control {
    parameter mnv, down_only is false.
   
    set a to 9.36.
    set b to 2/3.
    set c1 to 2.5.
    set c2 to 3.

    if mnv < 1/3 and down_only = false {
        set throttle_value to -((cos((180 / 3.1415) * a * (mnv - b))) / c1) + ((c1 - 1) / c1).
    } else if mnv > 2/3 {
        set throttle_value to ((cos((180 / 3.1415) * a * (mnv - b))) / c2) + ((c2 - 1) / c2).
    } else {
        set throttle_value to 1.
    }
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
    warpto(start_time - 16).
    wait until time:seconds > start_time - 15.
    lock_steering(mnv).
    wait until time:seconds > start_time.
    local original_dv is mnv:deltaV:mag.
    local burn_time is telemetry["burn_time"](mnv).
    if burn_time < 5 {
        until mnv:deltaV:mag < 0.01 * (original_dv) {
            lock throttle to (1/3) * (burn_time / 5).
            autostage().
        }
    } else {
       wait until maneuver_complete(mnv, original_dv).
    }
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
    
    if mnv:deltaV:mag > 0.005 * (start_dv) {
        lock delta_v_ratio to 1- (mnv:deltaV:mag / start_dv).
        lock throttle_value to throttle_control(delta_v_ratio).
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
function atmos_ascent {
    parameter target_altitude, inclination.

    // Set the direction and pitch according to the targets
    set target_direction to inclination.
    lock target_pitch to 90 - 0.98049377 * alt:radar  ^ 0.40511.
    lock steering to heading(target_direction, target_pitch).

    // Control steering and throttle until target apoapsis is achieved
    list engines in engine_list.
    until apoapsis > target_altitude or engine_list:length = 0 {
        lock altitude_ratio to apoapsis / target_altitude.
        lock throttle_value to throttle_control(altitude_ratio, true).
        lock throttle to throttle_value.
        if target_pitch < 0 {
            lock steering to heading(target_direction, 0).
        }
        autostage().
    }
    eng_shutdown().
    until altitude > 70000 {
        set kuniverse:timewarp:mode to "PHYSICS".
        set kuniverse:timewarp:rate to 4.
        set kuniverse:timewarp:mode to "RAILS".
    }
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

    local start_search_time is time:seconds + (orbit:nextpatcheta/4).
    local transfer is list(start_search_time, 0, 0, 0).
    set transfer to telemetry["improve_converge"](transfer, telemetry["protect_from_past"](telemetry["mun_transfer_score"]@), new_periapsis).
    execute_maneuver(transfer).
    wait 2.
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
    execute_maneuver(transfer).
    wait 2.
    
    // Perform a mid-course correction if necessary
    if (abs(orbit:nextpatch:periapsis - mun_periapsis)/mun_periapsis) < 0.1 {
        print("No mid-course correction is required.").
        return 0.
    }
    mid_course_correction(mun_periapsis).
    wait 2.

    // Warp to the Mun encounter
    warpto(time:seconds + orbit:nextPatchEta - 5).
    wait until body = Mun.
    wait 2.
}

// Perform a simple deorbit burn
function deorbit {
    lock steering to retrograde.
    wait 2.
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

// Perform a burn and counter burn to align orbits with another vessel
function orbital_angle_align {
    parameter angle_desired.

    // User selects target ship, and initial phase angle is calculated
    set target to telemetry["select_body_target"]().
    local angle_phase is telemetry["calculate_phase_angle"]().
    print("phase_angle_0 is " + angle_phase).
    
    // Transfer orbit is calculated for desired phase separation
    local angle_delta is angle_phase - angle_desired.
    set angle_delta to angle_delta - 360 * floor(angle_delta/360).
    if angle_delta < 180 {
        set new_period to (1 - angle_delta/360) * target:orbit:period.
    } else {
        set new_period to (2 - angle_delta/360) * target:orbit:period.
    }

    // Transfer maneuver is calculated and executed
    local transfer is list(0).
    set transfer to telemetry["improve_converge"](transfer, telemetry["period_score"]@, new_period).
    if telemetry["altitude_delta"]() > 0 {
        execute_maneuver(list(time:seconds + eta:apoapsis, 0, 0, transfer[0])).
    } else {
        execute_maneuver(list(time:seconds + eta:periapsis, 0, 0, transfer[0])).
    }

    // Warp one full orbit, then re-circularise
    wait 1.
    set warp_time to time:seconds + orbit:period - 60.
    warpto(warp_time).
    wait until time:seconds > warp_time.
    circularise().

    // Calculate and print new phase angle
    set angle_phase to telemetry["calculate_phase_angle"]().
    print("phase_angle_1 is " + angle_phase).
    return angle_phase.
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