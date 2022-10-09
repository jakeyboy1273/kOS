print "rendezvous: LOADING".

// Lexicon to load library functions into main script
global rendezvous is lex(
    "init", init@,
    "lng_to_degrees", lng_to_degrees@,
    "orbitable", orbitable@,
    "target_angle", target_angle@,
    "await_closest_approach", await_closest_approach@,
    "cancel_relative_velocity", cancel_relative_velocity@,
    "approach", approach@,
    "change_period", change_period@
).
function init {}
rendezvous["init"]().


FUNCTION lng_to_degrees {
  PARAMETER lng.

  RETURN MOD(lng + 360, 360).
}

// Returns an active vessel with the given name tag
function orbitable {
    parameter name.

    list targets in vessels.
    for vs in vessels {
        if vs:name = name {
            return vessel(name).
        }
    }
}

FUNCTION target_angle {
  PARAMETER targ.

  RETURN MOD(
    LNG_TO_DEGREES(ORBITABLE(targ):LONGITUDE)
    - LNG_TO_DEGREES(SHIP:LONGITUDE) + 360,
    360
  ).
}

// Loop until our distance from the target is increasing
FUNCTION await_closest_approach {
  UNTIL FALSE {
    SET lastDistance TO TARGET:DISTANCE.
    WAIT 1.
    IF TARGET:DISTANCE > lastDistance {
      BREAK.
    }
  }
}

// Throttle against our relative velocity vector until we're increasing it
FUNCTION cancel_relative_velocity {
  LOCK STEERING TO TARGET:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT.
  WAIT 5.

  LOCK THROTTLE TO 0.5.
  UNTIL FALSE {
    SET lastDiff TO (TARGET:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT):MAG.
    WAIT 1.
    IF (TARGET:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT):MAG > lastDiff {
      LOCK THROTTLE TO 0. BREAK.
    }
  }
}

// Throttle for five seconds toward the target
FUNCTION approach {
  LOCK STEERING TO TARGET:POSITION.
  WAIT 5. LOCK THROTTLE TO 0.1. WAIT 5.
  LOCK THROTTLE TO 0.
}

// Throttle prograde or retrograde to change our orbital period
FUNCTION change_period {
  PARAMETER newPeriod.

  print "changing period...".

  SET currentPeriod TO SHIP:OBT:PERIOD.
  SET boost         TO newPeriod > currentPeriod.

  IF boost {
    LOCK STEERING TO PROGRADE.
  } ELSE {
    LOCK STEERING TO RETROGRADE.
  }

  WAIT 5.
  LOCK THROTTLE TO 0.5.

  IF boost {
    WAIT UNTIL SHIP:OBT:PERIOD > newPeriod.
  } ELSE {
    WAIT UNTIL SHIP:OBT:PERIOD < newPeriod.
  }

  LOCK THROTTLE TO 0.
}