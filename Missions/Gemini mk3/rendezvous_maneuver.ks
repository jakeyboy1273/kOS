// This mission attempts to rendezvous the craft ewith another.

// Import libraries
set rendezvous to lex().
runoncepath("0:/Libraries/" + rendezvous.ks).

set victim to "Gemini mk1".
set target to rendezvous["orbitable"](victim).

print "Beginning rendezvous procedure...".

// Start our rendezvous adjustment at periapsis
set go_time to time:seconds + eta:periapsis -10.
warpto(go_time - 5).
wait until go_time.
set target_angle to rendezvous["target_angle"](victim).
print target_angle. wait 1.
set desired_period to target:obt:period * (1 + ((360 - target_angle) / 360)).
print desired_period. wait 1.

// Boost our orbit, and circle around
rendezvous["change_period"](desired_period).
set go_time to time:seconds + eta:periapsis -10.
warpto(go_time - 5).
wait until go_time.

// Bring us in closer by steps
until target:distance < 1000 {
  rendezvous["await_closest_approach"]().
  rendezvous["cancel_relative_velocity"]().
  rendezvous["approach"]().
}

// Kill remaining relative velocity
rendezvous["cancel_relative_velocity"]().
print "Rendezvous complete!".