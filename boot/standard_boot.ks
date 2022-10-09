// Wait until the ship has fully loaded
wait until ship:unpacked.

// Open the terminal, by default
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

print "Booting system...".

// Ensure the throttle is down before doing anything.
set ship:control:pilotmainthrottle to 0.

// Check if the script is available in the archive
set update_script to "Missions/" + ship:name + "/_UPDATE.ks".

if exists("0:" + update_script) {
    // Load the script to the processor's volume
    copypath("0:" + update_script, "1:" + update_script).
    // Run the update script
    runpath(update_script).
    // Option to delete the script, once completed.
    print "Delete update script? (y/n): ".

    if terminal:input:getchar() = "y" {
        print "Deleted! Program completed.".
        deletepath("0:" + update_script).
    }
    else if terminal:input:getchar() = "n" {
        print "Program completed.".
    }
    
}
else {
    print "No update available, booting into NORMAL mode.".
    // Run any "normal" operating mode code, here
}
