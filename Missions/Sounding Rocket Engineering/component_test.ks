// This script controls the ship to a designated speed/altitude, in order to perform in-flight tests.

// Import libraries
set maneuver to lex().
runoncepath("0:/Libraries/" + maneuver.ks).

// Launch the ship
lock steering to heading(0, 90).
maneuver["launch"]().

// Reach and maintain the desired speed with throttle control
set target_speed to 460.
set target_altitude_0 to 3000.
set target_altitude_1 to 10000.

until ship:verticalspeed > target_speed {
  maneuver["autostage"]().
}

set auto_throttle to 0.
lock throttle to auto_throttle.

// Perform the PID control loop to maintain the speed until the target altitude is reached
until ship:altitude > target_altitude_0 {
  set auto_throttle to maneuver["pid_control"](list(0.015, 0.0005, 0.008), target_speed, ship:verticalspeed).
  set auto_throttle to max(0, min(auto_throttle, 1)).
  wait 0.001.
  maneuver["autostage"]().
}
print("Target speed & altitude has been reached, now perform the required test.").
until ship:altitude > target_altitude_1 {
  set auto_throttle to maneuver["pid_control"](list(0.015, 0.0005, 0.008), target_speed, ship:verticalspeed).
  set auto_throttle to max(0, min(auto_throttle, 1)).
  wait 0.001.
  maneuver["autostage"]().
}
print("Test window complete.").