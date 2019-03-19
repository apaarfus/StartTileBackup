# StartTileBackup
This project is a [fork](https://github.com/dwrolvink/StartTileBackup) of [StartTileBackup](https://github.com/TurboLabIt/StartTileBackup).  This is somewhat of a rewrite, as I've merged both functionality of the original backup and restoration scripts into a single batch script, with additional added functionality:

**NOTE**: I've yet to verify the continued function of this script since rewriting it.  Though, I'll update the repo with any changes wtihin the next few days of forking.  So like, if you use it before then, have fun?

## Changes
Below states a list of all changes to the previous fork

### Combined Functionality
The original project and fork split the backup/restoration functionality into seperate scripts; both of which were hardcoded.  In this rewrite, I've combined the functionality of both scripts into a single file; whilst also making some other, functionally useful changes.  It may be over complicated, sure; but it'll help me in the future when refurbing machines.

### "*Enhancements*"
* Slight Configuration (vars)
  * Backup Directory
  * Logging Directory
  * Log File
  * CloudStore directory (win)
  * Caches directory (win)
  * Explorer directory (win)
  * TaskBar directory (win)
  * Start Menu registry key
  * Task Bar registry key
  * Robocopy options
  * Robocopy command
* Added Logging
  * Stores logs in `script_dir\log`
  * Log files named by current datestamp
  * Each log line is time-stamped with `[YYYY-MM-DD@HH:MM:SS]`
  * Seperator
* Command-Line Arguments, albeit basic
  * `/h, /?` Show a help text
  * `/b` Run in Backup mode
  * `/r` Run in Restoration mode
  * `/bd:<path>` Set backup directory location
  * `/ld:<path>` Set logging directory location
  * `/lf:<file>` Set log file name (and extension)
* Checks for critical errors prior to running -- aborts if found
* Added comments for some added readability.  Sort of, anyway.
* Split functionality into, well, functions
* Clears memory prior to quitting

## Planned "*Enhancements*"
I'd like to get to these at some point, but we'll see.
* Split backups into date/name-specified groups
  * To allow for multiple backup/restoration jobs to be store in one location -- portability?
* Backup and Restorage of Windows 7 StartMenu pins
  * Not too difficult, but maybe a little over the top
* General clean-up -- at least for what's doable with batch
* Maybe a port to PowerShell?  Hmm...I need to learn PS first though
  * Alternative, maybe a GitBash/Cygwin64 port would be less awful
