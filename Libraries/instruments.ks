print("instruments: LOADING").

// Lexicon to load library functions into main script
global instruments is lex(
    "init", init@,
    "get_deployable_antennas", get_deployable_antennas@,
    "extend_antennas", extend_antennas@,
    "deploy_instruments", deploy_instruments@,
    "get_sensor_list", get_sensor_list@,
    "get_esu_list", get_esu_list@,
    "get_all_science", get_all_science@
).
function init {}
instruments["init"]().

// Returns a list of Deployable Antennas
function get_deployable_antennas {
    Declare Local AntList to list().
    Declare Local plist to ship:parts.
    
        for item in plist {
            if item:hasmodule("ModuleDeployableAntenna") {
                AntList:add(item).
            }
        }
    return AntList.
}

// Extends all Deployable Antennas or deploy a list of antennas
function extend_antennas {
    Declare Parameter AntList is list().  //Optional paramenter - list of antennas to deploy

    if AntList:length = 0 {
        set AntList to get_deployable_antennas().
    }
    For Ant in AntList {
        if Ant:getmodule("ModuleDeployableAntenna"):hasaction("extend antenna"){
            Ant:getmodule("ModuleDeployableAntenna"):doaction("extend antenna", true).
        }
    }
}

// Deploys solar panels, and antennas
function deploy_instruments {

    panels on.
    instruments["extend_antennas"](). wait 5.
    lock steering to prograde. wait 5.
    unlock steering. sas on.
}

// Returns a list of all science parts
function get_sensor_list {
    local sensor_list is list().
    declare local p_list to ship:parts.
    
        for item in p_list {
            if item:hasmodule("ModuleScienceExperiment") {
                sensor_list:add(item).
            }
        }
    return sensor_list.
}

// Finds and returns an ESU part, or blank if there are none
function get_esu_list {
    declare Local p_list to List().
    declare Local num_in_list to 0.

    Set p_list to ship:partsnamed("ScienceBox").
    if p_list:length = 0 {
        print("No ESU on this ship").
        return p_list.
    }.
    
    //Remove any extra ESUs and only return the 1st if found
    if p_list:length > 1 {
        set num_in_list to p_list:length.
        from {Local I is num_in_list.} until I = 1 step {set I to I - 1.} do {
            p_list:remove(I-1).
        }
    }.
    return p_list.    
}

// Runs one of each available type of experiment on board
function get_all_science {
	declare parameter device_list is list().

    print("Performing science experiments.").

    // If no list of science parts sent to the function, get a list of all science parts on the ship
    if device_list:length = 0 {
        set device_list to get_sensor_list().
    }.

    declare local sensed_list is list().
    declare local counter to 0.

	for device in device_list {
        if not device:getmodule("ModuleScienceExperiment"):hasdata and sensed_list:find(device:name) = -1 {
            device:getmodule("ModuleScienceExperiment"):deploy.
            sensed_list:add(device:name).
            set counter to counter +1.
        }
    }
    return device_list.
}