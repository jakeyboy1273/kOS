# kOS
A repository containing the codebase, in kerboscript, for automatic command and control of a Kerbal Space Program career.

## 1. System Configuration
### 1.1. Configuring the kOS Environment
- Copy current Kerbal Space Program directory to the desktop, to keep it safe
- Steam Library -> Gear -> Properties -> Betas -> Select Version
- Download the old version from steam
- Copy this version to the new directory
- Put the original latest version back in the steam folder
- Go back into steam and select “none” on the Betas page, to retain the latest version
- Open ckan **as administrator** and add the new game instance to the program
- Install the mod to the instance, and LAUNCH game

### 1.2. kOS Program Initialisation
#### 1.2.1. Basic Functions
The most basic way to invoke kOS is to launch a craft with a SCS part, invoke the terminal, and type commands manually.
#### 1.2.2.	Writing Basic Scripts
Scripts can be edited in-terminal by typing `EDIT <script>.`. This editor allows you to type code, then save and exit. This code is saved to VOLUME #1, which is the volume of the current SCS part on the current vessel.
#### 1.2.3.	Saving Permanent Scripts
VOLUME #0 is the “Archive” volume. Files saved here will be saved forever and be accessible by any crafts that are in-build or launched.
These files are stored in `Ships/Scripts` in the Save game file.

| Syntax | Description |
| ----------- | ----------- |
| `RUN <file>.` | Run a named file in the current volume |
| `LIST FILES.` | List all files in the current volume |
| `SWItCH TO <#>.` | Switch to a numbered volume |
| `COPYPATH("<#>:/<file>", "").` | Copies to the current volume |

## 2. File Structure
### 2.1. Boot
- kOS comes with a default folder called “boot”. Scripts in this folder can be selected to boot on a particular SCS in the VAB, and will automatically be copied to VOLUME #1 and run when the ship is launched.
- The boot file will run every time the system is powered up, so it can’t just directly run the flight script. It needs to perform a specific set of tasks;
    - [ ] Housekeeping tasks
    - [ ] Check the current status of the craft
    - [x] Perform the appropriate script from the appropriate point depending on the current status of the craft

The PRIMARY function of the boot file is to serve as a layer of abstraction between the ship and the actual mission program. The benefit of this is that the mission program can be updated and then you can “revert to launch” and since the mission program is dynamically loaded by the boot file every time, it will refresh.

The current boot file will, by default, attempt to load an _UPDATE.ks script for the current craft (see section 3.3). If no such file exists, it could default to performing a regular/standard boot-up (to cover the eventuality that booting is simply occurring due to loss of signal/power/something else awry).

### 2.2. Libraries
The libraries are just categorised lists of helper functions that can be used across missions. The main body of a library will consist of these self-contained functions.
At the start of the library, a lexicon must be set up to allow the functions to be easily called within other programs. Each lexicon is global and consists of key/value pairs (name/name@).
A mock function must be created called “init”, included in the lexicon, and called within the library. This will prevent any warnings about the lexicon not being used.
Whenever a library is imported (including when imported for use by another library) a mock variable with the name of the library must first be created. This will prevent any warnings about the variable name possibly not existing.
- `instruments.ks`: Functions relating to the operation of onboard instruments.
- `maneuver.ks`: Functions relating to planning and executing maneuvers.
- `telemetry.ks`: Functions relating to the collection and manipulation of telemetry.

### 2.3. Missions
This folder contains subfolders pertaining to each active or planned mission. The intention is that all mission-specific programs can be segregated into their own repositories. If an update is to be applied to an in-service craft, this can be applied by writing/saving a script in the mission’s folder, then making a copy and naming it `_UPDATE.ks`.

## 3. Spacecraft
Taking inspiration from an earlier career, a good rule of thumb here is to have a booster which has about 3,500m/s of delta-v, then a selection of upper stages which have varying degrees of delta-v.

The variables for boosters are width and mass (of payload + upper stage).

The variables for upper stages are width, mass (of payload), and delta-v.

Width classes are as follows;
- Tiny (0.625m)
- Small (1.25m)
- Medium (1.875m)
- Large (2.5m)
- Extra Large (3.75m)
- Huge (5m).

This will be abbreviated to `(T, S, M, L, EL, H)`.

Weight classes and delta-v classes follow the 1/2/5 rule starting from 0.5 (t & km/s, respectively).

### 3.1. Payloads
Payloads can have any name depending on purpose, and have mk# suffixes depending on iteration or function going forward.
### 3.2. Upper Stages
These stages need to be autonomous (in order to de-orbit) and have enough delta-v to perform orbital transfers and, sometimes, partial landings. Delta-v must also include enough to complete orbital circularisation (about 250m/s).
### 3.3. Boosters
A booster must have 3,500m/s delta-v (sea-level) for its weight class. It doesn’t need power or data because it should be jettisoned just prior to achieving orbit.

## 4. To-Do Notes
- "log" data to storage.ks files in order to use variables between scripts?
- if currently running script is already on 1: (i.e. still running) don't try to downlaod again (use run_modes throughout?)
- pre-launch function
- post-mission function
- General instrument deploy function
- Screen stuff? telemetry and status
- rewatch ternary search episode and improve_converge episode
- make mun transfer functions body-agnostic
- write angular error checking feature into maneuver complete function
- in fact, write a whole function which takes two angles and checks the delta (also will be useful for when trying to wait until steering command has completed)
- Organise missions by mission types, not just by ship. No point having `_UPDATE.ks` really because the ships are too dumb and only take a update file with no knowledge of where in the flight they are, so they are "one shot". There should just be a bunch of missions
- create a second finish condition which checks if the maneuver node has pinged off e.g. `if mnv:deltaV:mag > 0.1 * (start_dv) and VANG(steering_angle - maneuver_angle) > 10 {set finish_maneuver to true.}`
- `atmos_ascent` make it somehow body agnostic, depending on atmosphere heights and stuff (just needs a lookup table of atmos ceiling for each body)
- maneuver completion - throttle scaling also should be based on burn time i.e. below a certain duration the throttle should be very low and the completion criteria should be widened
- throttle control based on acceleration of ship + desired speed change rather than just arbitrary
- docking maneuver
