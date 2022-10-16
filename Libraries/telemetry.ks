// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

print("telemetry: LOADING").

// Lexicon to load library functions into main script
global telemetry is lex(
    "init", init@,
    "altitude_delta", altitude_delta@,
    "start_time", start_time@,
    "burn_time", burn_time@,
    "improve", improve@,
    "improve_converge", improve_converge@,
    "ternary_search", ternary_search@,
    "protect_from_past", protect_from_past@,
    "eccentricity_score", eccentricity_score@,
    "apoapsis_periapsis_score", apoapsis_periapsis_score@,
    "period_score", period_score@,
    "transfer_score", transfer_score@,
    "distance_to_target_at_apoapsis", distance_to_target_at_apoapsis@,
    "distance_to_target_at_patch_apoapsis", distance_to_target_at_patch_apoapsis@,
    "angle_to_target", angle_to_target@,
    "altitude_at", altitude_at@,
    "calculate_phase_angle", calculate_phase_angle@,
    "select_body_target", select_body_target@,
    "distance_to_ground", distance_to_ground@,
    "stopping_distance", stopping_distance@,
    "stopping_time", stopping_time@,
    "time_to_impact", time_to_impact@,
    "ground_slope", ground_slope@,
    "orbit_binormal", orbit_binormal@,
    "relative_nodal_vector", relative_nodal_vector@,
    "angle_to_relative_node", angle_to_relative_node@,
    "relative_inclination", relative_inclination@
).
function init {}
telemetry["init"]().


// Calculate the change in altitude over a small time
function altitude_delta {
    local altitude_0 is ship:altitude.
    local time_0 is time:seconds.
    wait 0.1.
    local altitude_1 is ship:altitude.
    local time_1 is time:seconds.
    local d_altitude is altitude_1 - altitude_0.
    local d_time is time_1 - time_0.
    local delta is d_altitude / d_time.

    return delta.
}

// Calculates start time for a given maneuver.
function start_time {
    parameter mnv.

    return time:seconds + mnv:eta - burn_time(mnv) / 2.
}

// Calculates total burn time for a given maneuver.
function burn_time {
    parameter mnv.

    local dV is mnv:deltaV:mag.
    local g0 is 9.80665.
    local isp is 0.

    list engines in my_engines.
    for en in my_engines {
    if en:ignition and not en:flameout {
        set isp to isp + (en:isp * (en:availableThrust / ship:availableThrust)).
    }
    }

    local mf is ship:mass / constant():e^(dV / (isp * g0)).
    local fuelFlow is ship:availableThrust / (isp * g0).
    local t is (ship:mass - mf) / fuelFlow.

    return t.
}

// Scores data based on the result of passing it to a particular function
function improve {
    parameter data, step_size, score_function, targ.

    local score_to_beat is abs(score_function(data) - targ).
    local best_candidate is data.
    local candidates is list().
    local index is 0.
    until index >= data:length {
        local inc_candidate is data:copy().
        local dec_candidate is data:copy().
        set inc_candidate[index] to inc_candidate[index] + step_size.
        set dec_candidate[index] to dec_candidate[index] - step_size.
        candidates:add(inc_candidate).
        candidates:add(dec_candidate).
        set index to index + 1.
    }
    for candidate in candidates {
        local candidate_score is abs(score_function(candidate) - targ).
        if candidate_score < score_to_beat {
            set score_to_beat to candidate_score.
            set best_candidate to candidate.
        }
    }
    return best_candidate.
}

// Compares scores from "improve" function and converges to a maximum
function improve_converge {
    parameter data, score_function, targ.

    for step_size in list(100, 10, 1) {
        print "improve_converge: calculating step " + step_size + "...".
        until false {
            local old_score is abs(score_function(data) - targ).
            set data to improve(data, step_size, score_function, targ).
            if old_score <= abs(score_function(data) - targ) {
                break.
            }
        }
    }
    print "improve_converge: calculation complete".
    return data.
}

// Algorithm to search for an optimum value within a range via thirds
function ternary_search {
    parameter f, left, right, absolute_precision.
    until false {
        if abs(right - left) < absolute_precision {
            return (left + right) / 2.
        }
        local left_third is left + (right - left) / 3.
        local right_third is right - (right - left) / 3.
        if f(left_third) < f(right_third) {
            set left to left_third.
        } else {
            set right to right_third.
        }
    }
}

// Stops an algorithm from being replaced by a previous iteration
function protect_from_past {
    parameter original_function.
    local replacement_function is {
        parameter data.
        if data[0] < time:seconds + 15 {
            return 2^64.
        } else {
            return original_function(data).
        }
    }. 
    return replacement_function@.   
}

// Calculates a score based on minimum eccentricity achieved by a maneuver
function eccentricity_score {
    parameter data.

    local mnv is 0.
    if altitude_delta() > 0 {
        set mnv to node(time:seconds + eta:apoapsis, 0, 0, data[0]).
    } else {
        set mnv to node(time:seconds + eta:periapsis, 0, 0, data[0]).
    }
    maneuver["add_maneuver"](mnv).
    local result is mnv:orbit:eccentricity.
    maneuver["remove_maneuver"](mnv).
    return result.
}

// Calculates a score based on apoapsis/periapsis achieved by a maneuver
function apoapsis_periapsis_score {
    parameter data.

    local mnv is 0.
    local d_apo is 0.
    local d_per is 0.
    local result is 0.
    if altitude_delta() > 0 {
        set mnv to node(time:seconds + eta:apoapsis, 0, 0, data[0]).
        maneuver["add_maneuver"](mnv).
        set d_apo to abs(mnv:orbit:apoapsis - ship:apoapsis).
        set d_per to abs(mnv:orbit:periapsis - ship:apoapsis).
        if d_apo > d_per {
            set result to mnv:orbit:apoapsis.
        } else {
            set result to mnv:orbit:periapsis.
        }
        maneuver["remove_maneuver"](mnv).
    } else {
        set mnv to node(time:seconds + eta:periapsis, 0, 0, data[0]).
        maneuver["add_maneuver"](mnv).
        set d_apo to abs(mnv:orbit:apoapsis - ship:periapsis).
        set d_per to abs(mnv:orbit:periapsis - ship:periapsis).
        if d_apo > d_per {
            set result to mnv:orbit:apoapsis.
        } else {
            set result to mnv:orbit:periapsis.
        }
        maneuver["remove_maneuver"](mnv).
    }
    return result.
}

// Calculates a score based on minimum eccentricity achieved by a maneuver
function period_score {
    parameter data.

    local mnv is 0.
    if altitude_delta() > 0 {
        set mnv to node(time:seconds + eta:apoapsis, 0, 0, data[0]).
    } else {
        set mnv to node(time:seconds + eta:periapsis, 0, 0, data[0]).
    }
    maneuver["add_maneuver"](mnv).
    local result is mnv:orbit:period.
    maneuver["remove_maneuver"](mnv).
    return result.
}

// Calculates a score based on periapsis of next patch, or distance at apoapsis of current patch if not
function transfer_score {
    parameter data.
    parameter targ is target.

    local mnv is node(data[0], data[1], data[2], data[3]).
    maneuver["add_maneuver"](mnv).
    local result is 0.

    if mnv:orbit:hasnextpatch {
        local next_patch_orbit is mnv:orbit:nextpatch.
        local no_next_patch is false.
        until no_next_patch {
            if next_patch_orbit:body = targ {
                set result to next_patch_orbit:periapsis.
                set no_next_patch to true.
            } else {
                if next_patch_orbit:hasnextpatch = false {
                    set no_next_patch to true.
                    set result to distance_to_target_at_patch_apoapsis(next_patch_orbit, targ).
                } else {
                    set next_patch_orbit to next_patch_orbit:nextpatch.
                }
            }
        }
    } else {
        set result to distance_to_target_at_apoapsis(mnv, targ).
    }
    maneuver["remove_maneuver"](mnv).
    return result.
}

// Calculates the distance to a target body at the maneuver's apoapsis
function distance_to_target_at_apoapsis {
    parameter mnv.
    parameter targ is target.
    local apoapsis_time is ternary_search(
        altitude_at@,
        time:seconds + mnv:eta,
        time:seconds + mnv:eta + (mnv:orbit:period / 2),
        1
    ).
    return (positionAt(ship, apoapsis_time) - positionAt(targ, apoapsis_time)):mag.
}

// Calculates the distance to a target body at an orbit patch's apoapsis
function distance_to_target_at_patch_apoapsis {
    parameter patch.
    parameter targ is target.

    local apoapsis_time is time:seconds + patch:eta:apoapsis.
    return (positionAt(ship, apoapsis_time) - positionAt(targ, apoapsis_time)):mag.
}

// Calculate the current angle to the target body
function angle_to_target {
    parameter t.
    return vectorAngle(
        body:position - positionAt(ship, t),
        body:position - positionAt(target, t)
    ).
}

// Calculate the altitude of the ship
function altitude_at {
    parameter t.
    return body:altitudeOf(positionAt(ship, t)).
}

// Calculate the phase angle between two vessels
function calculate_phase_angle {
    local angle_ship is obt:lan + obt:argumentofperiapsis + obt:trueanomaly.
    local angle_target is target:obt:lan + target:obt:argumentofperiapsis + target:obt:trueanomaly.
    local angle_phase is angle_target - angle_ship.
    set angle_phase to angle_phase - 360 * floor(angle_phase/360).

    return angle_phase.
}

// Prompts the user to select a target from all other ships orbiting the current body
function select_body_target {
    set target to body.
    
    list targets in all_target_list.
    local target_list is list().
    local target_name_list is list().

    // Generate a list of all vessels orbiting the current body
    print("Selecting a new target...").
    for targ in all_target_list {
        if targ:body = body {
            target_list:add(targ).
            target_name_list:add(targ:name).
        }
    }

    // Generate a user-readable list to select from
    local i is 0.
    for targ in target_name_list {
        print(i + ": " + targ).
        set i to i + 1.
    }

    // Prompt the user to select a target
    print "Select target from list: ".
    set target to target_list[terminal:input:getchar():toscalar].
    return target.
}

// Calculate the distance to the ground directly below the spacecraft
// TODO: Get rid of the "5" magic number which is just a guess for ship height
function distance_to_ground {
    local height is altitude - body:geopositionOf(ship:position):terrainHeight - 5.
    local pitch_angle is -arctan(ship:groundspeed / ship:verticalspeed).
    local distance is height / cos(pitch_angle).
    return distance.
}

// Calculate how far the ship would travel if it tried to stop
function stopping_distance {
    local grav is constant():g * (body:mass / body:radius^2).
    local thrust is ship:availableThrust / ship:mass.
    local max_deceleration is facing:vector*thrust - v(grav, 0, 0).
    return ship:velocity:orbit:mag^2 / (2 * max_deceleration:mag).
}

function stopping_time {
    local grav is constant():g * (body:mass / body:radius^2).
    local thrust is ship:availableThrust / ship:mass.
    local max_deceleration is facing:vector*thrust - v(grav, 0, 0).

    local a is max_deceleration:mag.
    local u is ship:velocity:orbit:mag.
    return u/a.
}

function time_to_impact { 
    local error is 1000.
    local previous_time is Time:Seconds.
    local time_step is 1.
    
    until error < 100 {
        set vessel_position to positionAt(ship, (previous_time + time_step)).
        local terrain_level to max((body:geoPositionOf(ship:position):terrainHeight), body:geoPositionOf(vessel_position):terrainHeight).
        set error to ((vessel_position - body:position):mag - body:radius - terrain_level).
        set previous_time to previous_time + time_step.
    }.
    return (previous_time + time_step) - time:seconds.
}

// Calculate the angle of the slope of the ground below
function ground_slope {
    local east is vectorCrossProduct(north:vector, up:vector).

    local center is ship:position.

    local a is body:geopositionOf(center + 5 * north:vector).
    local b is body:geopositionOf(center - 3 * north:vector + 4 * east).
    local c is body:geopositionOf(center - 3 * north:vector - 4 * east).

    local a_vec is a:altitudePosition(a:terrainHeight).
    local b_vec is a:altitudePosition(b:terrainHeight).
    local c_vec is a:altitudePosition(c:terrainHeight).

    return vectorCrossProduct(c_vec - a_vec, b_vec - a_vec):normalized.
}

// In the direction of orbital angular momentum of ves
function orbit_binormal {
    parameter ves is ship.

    return vcrs((ves:position - ves:body:position):normalized, ves:velocity:orbit:normalized):normalized.
}

// Vector directed from the relative descending node to the ascending node
function relative_nodal_vector {
    parameter ves is ship.
    parameter tar is target.

    local orbit_birnormal is orbit_binormal(ves).
    local target_binormal is orbit_binormal(tar).
    return vcrs(orbit_birnormal, target_binormal):normalized.
}

// Angle to relative node determined from args
function angle_to_relative_node {
    parameter is_ascending is true.
    parameter ves is ship.
    parameter tar is target.

    local join_vector is relative_nodal_vector(ves, tar).
    if is_ascending = false {
        set join_vector to -join_vector.
    }
    local angle is vang(-body:position:normalized, join_vector).
    local sign_vector is vcrs(-body:position, join_vector).
    local sign is vdot(orbit_binormal(ves), sign_vector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}

function relative_inclination {
  parameter targ is target.
  parameter u_time is time:seconds.

  return vang(vcrs(velocityAt(ship,u_time):orbit,positionAt(ship,u_time)), vcrs(velocityAt(targ,u_time):orbit,positionAt(targ,u_time))).
}