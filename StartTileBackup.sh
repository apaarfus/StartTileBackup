#!/bin/bash
#
# StartTileBackup.sh
# Author:	Alex Paarfus <apaarfus@wtcox.com>
# Date:		2019-04-26
# Git:		https://github.com/apaarfus/StartTileBackup
#
# Backups/Restores TaskBar and StartMenu configurations in Windows 10
# 
# Based on
#	https://github.com/TurboLabIt/StartTileBackup
#	https://github.com/dwrolvink/StartTileBackup
#
# Requirements
#	Windows 10 1803+
#	Administrative Rights
#	GitBash for Windows (Portable)

# ##------------------------------------##
# #|		Functions		|#
# ##------------------------------------##
# Clear Memory
usv() {
	unset _path_script_profile _path_script_data _path_script_logs
	unset _path_script_data_cloud_store _path_script_data_caches
	unset _path_script_data_explorer _path_script_data_task_bar _path_script_data_registry
	unset _path_script_data_registry_start_menu _path_script_data_registry_task_bar
	unset _path_sys_appdata_roaming _path_sys_appdata_local
	unset _path_sys_cloud_store _path_sys_caches _path_sys_explorer
	unset _path_sys_task_bar _path_reg_root _path_reg_start_menu _path_reg_task_bar
	unset _cfg_include_start_menu _cfg_include_task_bar _cfg_force_prompts
	unset _cfg_cp_trim_slashes _cfg_cp_verbose _cfg_cp_reg_opts
	unset OPTS rv
}

# Check Options
checkOpts() {
	rv="0"			# Return Value

	# Check for administrative rights
	if [ "$rv" -eq 0 ] && ! net session >/dev/null 2>&1; then printErr "admin"; rv="1"; fi
	
	# Check for Windows Version
	if [ "$rv" -eq 0 ]; then
		local verstr=""			# Version String
		if [ -f "$(win2pos "$WINDIR")/System32/wbem/WMIC.exe" ]; then verstr="$(wmic os get version | grep -E "^[0-9]" | awk -F "\." '{print $1 "." $2}')"; else
			verstr="$(cmd //c "ver 2>&1" | awk '{print $3,$4}' | sed 's/\[version //i;s/\]//' | awk -F "\." '{print $1 "." $2}')"
		fi
		case "$verstr" in
			10.0 )		echo > /dev/null;;
			* )		printErr "ver" "Wrong Windows Version"; rv="1";;
		esac
		unset verstr
	fi

	# Check for null values
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_root" ]; then printErr "null" "_path_script_root"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_profile" ]; then printErr "null" "_path_script_profile"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_data" ]; then printErr "null" "_path_script_data"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_logs" ]; then printErr "null" "_path_script_logs"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_data_cloud_store" ]; then printErr "null" "_path_script_data_cloud_store"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_data_caches" ]; then printErr "null" "_path_script_data_caches"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_data_explorer" ]; then printErr "null" "_path_script_data_explorer"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_data_task_bar" ]; then printErr "null" "_path_script_data_task_bar"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_data_registry" ]; then printErr "null" "_path_script_data_registry"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_data_registry_start_menu" ]; then printErr "null" "_path_script_data_registry_start_menu"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_script_data_registry_task_bar" ]; then printErr "null" "_path_script_data_registry_task_bar"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_sys_appdata_roaming" ]; then printErr "null" "_path_sys_appdata_roaming"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_sys_appdata_local" ]; then printErr "null" "_path_sys_appdata_local"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_sys_cloud_store" ]; then printErr "null" "_path_sys_cloud_store"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_sys_caches" ]; then printErr "null" "_path_sys_caches"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_sys_explorer" ]; then printErr "null" "_path_sys_explorer"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_sys_task_bar" ]; then printErr "null" "_path_sys_task_bar"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_reg_start_menu" ]; then printErr "null" "_path_reg_start_menu"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_path_reg_task_bar" ]; then printErr "null" "_path_reg_task_bar"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_cfg_include_start_menu" ]; then printErr "null" "_cfg_include_start_menu"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_cfg_include_task_bar" ]; then printErr "null" "_cfg_include_task_bar"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_cfg_force_prompts" ]; then printErr "null" "_cfg_force_prompts"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_cfg_cp_trim_slashes" ]; then printErr "null" "_cfg_cp_trim_slashes"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_cfg_cp_verbose" ]; then printErr "null" "_cfg_cp_verbose"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_cfg_cp_reg_opts" ]; then printErr "null" "cfg_cp_reg_opts"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ -z "$_var_job_restore" ]; then printErr "null" "_var_job_restore"; rv="1"; fi
	
	# Normalize Configuration -- if [ "$rv" -eq 0 ] && value isn't valid, reset to 0
	if [ "$rv" -eq 0 ] && [ ! "$_cfg_include_start_menu" -ge 0 -a "$_cfg_include_start_menu" -le 1 ]; then _cfg_include_start_menu="0"; fi
	if [ "$rv" -eq 0 ] && [ ! "$_cfg_include_task_bar" -ge 0 -a "$_cfg_include_task_bar" -le 1 ]; then _cfg_include_task_bar="0"; fi
	if [ "$rv" -eq 0 ] && [ ! "$_cfg_cp_trim_slashes" -ge 0 -a "$_cfg_cp_trim_slashes" -le 1 ]; then _cfg_cp_trim_slashes="0"; fi
	if [ "$rv" -eq 0 ] && [ ! "$_cfg_cp_verbose" -ge 0 -a "$_cfg_cp_verbose" -le 1 ]; then _cfg_cp_verbose="0"; fi

	# Check for Invalid Script-Related Paths; and create them if allowed
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_script_root" ]; then
		if [ "$_cfg_force_prompts" -eq 1 ]; then
			mkdir -p "$_path_script_data" "$_path_script_logs" "$_path_script_data_cloud_store" \
				"$_path_script_data_caches" "$_path_script_data_explorer" \
				"$_path_script_data_task_bar" "$_path_script_data_registry"
		else
			read -p "Create Script Directory Tree: '$_path_script_root'? (y/N): " ctc
			if [ -n "$ctc" ] && [[ "${ctc,,}" == "y" ]]; then 
				mkdir -p "$_path_script_data" "$_path_script_logs" "$_path_script_data_cloud_store" \
					"$_path_script_data_caches" "$_path_script_data_explorer" \
					"$_path_script_data_task_bar" "$_path_script_data_registry"
			else
				printErr "dir" "$_path_script_data_root"
				rv="1"
			fi
			unset ctc
		fi
	fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_script_profile" ]; then
		if [ "$_cfg_force_prompts" -eq 1 ]; then
			mkdir -p "$_path_script_data" "$_path_script_logs" "$_path_script_data_cloud_store" \
				"$_path_script_data_caches" "$_path_script_data_explorer" \
				"$_path_script_data_task_bar" "$_path_script_data_registry"
		else
			read -p "Create Script Directory Tree: '$_path_script_profile'? (y/N): " ctc
			if [ -n "$ctc" ] && [[ "${ctc,,}" == "y" ]]; then 
				mkdir -p "$_path_script_data" "$_path_script_logs" "$_path_script_data_cloud_store" \
					"$_path_script_data_caches" "$_path_script_data_explorer" \
					"$_path_script_data_task_bar" "$_path_script_data_registry"
			else
				printErr "dir" "$_path_script_data_profile"
				rv="1"
			fi
			unset ctc
		fi
	fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_script_data" ]; then
		if [ "$_cfg_force_prompts" -eq 1 ]; then
			mkdir -p "$_path_script_data" "$_path_script_data_cloud_store" \
				"$_path_script_data_caches" "$_path_script_data_explorer" \
				"$_path_script_data_task_bar" "$_path_script_data_registry"
		else
			read -p "Create Script Directory Tree: '$_path_script_data'? (y/N): " ctc
			if [ -n "$ctc" ] && [[ "${ctc,,}" == "y" ]]; then 
				mkdir -p "$_path_script_data" "$_path_script_logs" "$_path_script_data_cloud_store" \
					"$_path_script_data_caches" "$_path_script_data_explorer" \
					"$_path_script_data_task_bar" "$_path_script_data_registry"
			else
				printErr "dir" "$_path_script_data_data"
				rv="1"
			fi
			unset ctc
		fi
	fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_script_logs" ]; then
		if [ "$_cfg_force_prompts" -eq 1 ]; then mkdir -p "$_path_script_logs"; else
			read -p "Create Script Directory Tree: '$_path_script_logs" ctc
			if [ -n "$ctc" ] && [[ "${ctc,,}" == "y" ]]; then mkdir -p "$_path_script_logs"; else printErr "dir" "$_path_script_logs"; rv="1"; fi
			unset ctc
		fi
	fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_script_data_cloud_store" ]; then
		if [ "$_cfg_force_prompts" -eq 1 ]; then mkdir -p "$_path_script_data_cloud_store"; else
			read -p "Create Script Directory Tree: '$_path_script_data_cloud_store" ctc
			if [ -n "$ctc" ] && [[ "${ctc,,}" == "y" ]]; then mkdir -p "$_path_script_data_cloud_store"; else printErr "dir" "$_path_script_data_cloud_store"; rv="1"; fi
			unset ctc
		fi
	fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_script_caches" ]; then
		if [ "$_cfg_force_prompts" -eq 1 ]; then mkdir -p "$_path_script_caches"; else
			read -p "Create Script Directory Tree: '$_path_script_caches" ctc
			if [ -n "$ctc" ] && [[ "${ctc,,}" == "y" ]]; then mkdir -p "$_path_script_caches"; else printErr "dir" "$_path_script_caches"; rv="1"; fi
			unset ctc
		fi
	fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_script_explorer" ]; then
		if [ "$_cfg_force_prompts" -eq 1 ]; then mkdir -p "$_path_script_explorer"; else
			read -p "Create Script Directory Tree: '$_path_script_explorer" ctc
			if [ -n "$ctc" ] && [[ "${ctc,,}" == "y" ]]; then mkdir -p "$_path_script_explorer"; else printErr "dir" "$_path_script_explorer"; rv="1"; fi
			unset ctc
		fi
	fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_script_task_bar" ]; then
		if [ "$_cfg_force_prompts" -eq 1 ]; then mkdir -p "$_path_script_task_bar"; else
			read -p "Create Script Directory Tree: '$_path_script_task_bar" ctc
			if [ -n "$ctc" ] && [[ "${ctc,,}" == "y" ]]; then mkdir -p "$_path_script_task_bar"; else printErr "dir" "$_path_script_task_bar"; rv="1"; fi
			unset ctc
		fi
	fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_script_registry" ]; then
		if [ "$_cfg_force_prompts" -eq 1 ]; then mkdir -p "$_path_script_registry"; else
			read -p "Create Script Directory Tree: '$_path_script_registry" ctc
			if [ -n "$ctc" ] && [[ "${ctc,,}" == "y" ]]; then mkdir -p "$_path_script_registry"; else printErr "dir" "$_path_script_registry"; rv="1"; fi
			unset ctc
		fi
	fi

	# Check for Invalid System Paths
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_sys_cloud_store" ]; then printErr "dir" "$_path_sys_cloud_store"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_sys_caches" ]; then printErr "dir" "$_path_sys_caches"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_sys_explorer" ]; then printErr "dir" "$_path_sys_explorer"; rv="1"; fi
	if [ "$rv" -eq 0 ] && [ ! -d "$_path_sys_task_bar" ]; then printErr "dir" "$_path_sys_task_bar"; rv="1"; fi

	# Check for non-existent registry locations
	if [ "$rv" -eq 0 ] && reg query "$_path_reg_root" 2>&1 | grep -E "^ERROR" | grep -q "unable to find"; then printErr "reg" "$_path_reg_root"; trv="1"; fi
	if [ "$rv" -eq 0 ] && reg query "$_path_reg_start_menu" 2>&1 | grep -E "^ERROR" | grep -q "unable to find"; then printErr "reg" "$_path_reg_start_menu"; trv="1"; fi
	if [ "$rv" -eq 0 ] && reg query "$_path_reg_task_bar" 2>&1 | grep -E "^ERROR" | grep -q "unable to find"; then printErr "reg" "$_path_reg_task_bar"; trv="1"; fi

	# Return $rv
	printf "$rv"
}

# Print Errors
printErr() {
	case "${1,,}" in
		admin )		printf "%s\n" "Error: Requires Admin Rights for successful run";;
		null )		printf "%s\n" "Error: Variable is not defined: '$2'";;
		dir )		printf "%s\n" "Error: Directory does not exist: '$2'";;
		file )		printf "%s\n" "Error: File does not exist: '$2'";;
		reg )		printf "%s\n" "Error: Registry Key cannot be found: '$2'";;
		bkup )		
			if [[ "${3,,}" == "/dev/stdout" ]]; then ofile="/dev/null"; else ofile="$3"; fi
			printf "%s\n" "Error: Unable to backup $2" | tee --append "$3"
			unset ofile
			;;
		rstr )		
			if [[ "${3,,}" == "/dev/stdout" ]]; then ofile="/dev/null"; else ofile="$3"; fi
			printf "%s\n" "Error: Unable to restore $2" | tee --append "$3"
			unset ofile
			;;
		* ) 		printf "%s\n" "Error: Unknown Error Occurred: '$@'";;
	esac
}

# Show Help
show_help() {
	printf "%s\n" "StartTileBackup.sh [Options]"
	printf "%s\n" "\nNote: Requires Admin Rights\n\nOptions:"
	printf "%s\n" "\t-h, --help\t\t\tShow this help message"
	printf "%s\n" "\t-f, --force\t\t\tSkip confirmation dialogues"
	printf "%s\n" "\t-b, --backup\t\t\tPerform a Backup (default)"
	printf "%s\n" "\t-r, --restore\t\t\tPerform a Restoration"
	printf "%s\n" "\t-l, --links\t\t\tDo not follow links outside of scope"
	printf "%s\n" "\t-v, --verbose\t\t\tEnable verbose logging"
	printf "%s\n" "\t-t. --trim\t\t\tTrim trailing slashes"
	printf "%s\n" "\t-p, --profile\t<name>\t\tProfile Name to use for Backup/Restoration"
	printf "%s\n" "\t--start-menu\t\t\tInclude Start Menu"
	printf "%s\n" "\t--task-bar\t\t\tInclude Task Bar"
	printf "%s\n" "\t--both\t\t\tInclude both Start Menu & Task Bar (Overrides --task-bar and --start-menu)"
	printf "%s\n" "\t--root-dir\t<path>\t\tPath to root of storage location"
	printf "%s\n" "\t--data-dir\t<path>\t\tPath to Data storage location"
	printf "%s\n" "\t--log-dir\t<path>\t\tPath to Log storage location"
	printf "%s\n"
}

# Convert Windows to POSIX path -- Args: $1 = path
win2pos() { if [ -n "$1" ]; then printf "$1" | sed 's/://;s/\\/\//g'; fi; }

# Convert POSIX to Windows path -- Args: $1 = path
pos2win() { if [ -n "$1" ]; then printf "$1" | sed 's/^\///;s/\//\\/g;s/^./0:/'; fi; }

# Backup Process
tileBackup() {
	local cmdOpts=("$_cfg_cp_reg_opts")	# Default arguments
	local logFile="/dev/stdout"		# Log File
	local trv="0"				# This Return Value

	# Build cmdOpts
	if [ "$_cfg_force_prompts" -eq 1 ]; then cmdOpts+=("--force"); fi
	if [ "$_cfg_cp_trim_slashes" -eq 1 ]; then cmdOpts+=("--strip-trailing-slashes"); fi
	if [ "$_cfg_cp_verbose" -eq 1 ]; then cmdOpts+=("--verbose"); fi

	# Update Logfile
	logFile="$_path_script_logs/$(date +%Y-%m-%d_%H-%M-%S).bkup"

	# Ensure Start Menu || Taskbar is enabled
	if [ "$_cfg_include_start_menu" -eq 1 ] || [ "$_cfg_include_task_bar" -eq 1 ]; then
		# Check to see if profile exists -- if so, remove if allowed
		if [ -d "$_path_script_profile" ]; then
			if [ "$_cfg_force_prompts" -eq 1 ]; then 
				rm -rf "$_path_script_profile"
			else
				printf "%s\n" "Error: Profile already exists"
				read -p "Overwrite Profile? (y/N): " owc
				if [ -n "$owc" ] && [[ "${owc,,}" == "y" ]]; then rm -rf "$_cfg_force_prompts"; else trv="1"; fi
				unset owc
			fi
		fi

		# Check to see if profile doesn't exist; or trv is set
		if [ "$trv" -eq 1 ] && [ ! -d "$_path_script_profile" ]; then
			mkdir -p "$_path_script_profile"
			mkdir -p "$_path_script_data_cloud_store" \
				"$_path_script_data_caches" \
				"$_path_script_data_explorer" \
				"$_path_script_data_taskbar" \
				"$_path_script_data_registry" 
		else
			printErr "bkup" "Backup Location: Unable to Overwrite" "$logFile"
		fi

		# Run Backup if trv isn't set
		if [ "$trv" -eq 0 ]; then
			# Kill Explorer process
			taskkill //im "explorer.exe" //f

			# Backup Start Menu
			if [ "$_cfg_include_start_menu" -eq 1 ]; then
				# Backup Data files, reporting any errors that occur
				cp "${cmdOpts[@]}" "$_path_sys_cloud_store" "$_path_script_data_cloud_store" 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "bkup" "Data: Cloud Store" "$logFile"; fi
				cp "${cmdOpts[@]}" "$_path_sys_caches" "$_path_script_data_caches" 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "bkup" "Data: Caches" "$logFile"; fi
				cp "${cmdOpts[@]}" "$_path_sys_explorer" "$_path_script_data_explorer" 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "bkup" "Data: Explorer" "$logFile"; fi
				
				# Backup Registry Key
				reg export "$_path_reg_start_menu" "$_path_script_data_registry_start_menu" //y 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "bkup" "Registry: Start Menu" "$logFile"; fi
			fi

			# Backup Taskbar
			if [ "$_cfg_include_task_bar" -eq 1 ]; then
				# Backup Data files, reporting any errors that occur
				cp "${cmdOpts[@]}" "$_path_sys_task_bar" "$_path_script_data_task_bar" 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "bkup" "Data: Task Bar" "$logFile"; fi

				# Backup Registry Key
				reg export "$_path_reg_task_bar" "$_path_script_data_registry_task_bar" //y 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "bkup" "Registry: Task Bar" "$logFile"; fi
			fi

			# Restart Explorer Process
			explorer.exe
		fi
	fi
	
	# Clear Memory
	unset cmdOpts logFile trv
}

# Restore Process
tileRestore() {
	local cmdOpts=("$_cfg_cp_reg_opts")	# Default arguments
	local logFile="/dev/stdout"		# Log File
	local trv="0"				# This Return Value

	# Build cmdOpts
	if [ "$_cfg_force_prompts" -eq 1 ]; then cmdOpts+=("--force"); fi
	if [ "$_cfg_cp_trim_slashes" -eq 1 ]; then cmdOpts+=("--strip-trailing-slashes"); fi
	if [ "$_cfg_cp_verbose" -eq 1 ]; then cmdOpts+=("--verbose"); fi

	# Update Logfile
	logFile="$_path_script_logs/$(date +%Y-%m-%d_%H-%M-%S).bkup"

	# Ensure Start Menu || Taskbar is enabled
	if [ "$_cfg_include_start_menu" -eq 1 ] || [ "$_cfg_include_task_bar" -eq 1 ]; then
		# Check to see if profile exists -- if not then report error
		if [ ! -d "$_path_script_profile" ]; then printErr "rstr" "Profile: Path not Found '$_path_script_profile'" "$logFile"; trv="1"; fi

		# Run Restor if trv isn't set
		if [ "$trv" -eq 0 ]; then
			# Kill Explorer process
			taskkill //im "explorer.exe" //f

			# Restore Start Menu
			if [ "$_cfg_include_start_menu" -eq 1 ]; then
				# Restore Data files, reporting any errors that occur
				rm -rf "$_path_sys_cloud_store/*"
				cp "${cmdOpts[@]}" "$_path_script_data_cloud_store" "$_path_sys_cloud_store"2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "rstr" "Data: Cloud Store" "$logFile"; fi
				rm -rf "$_path_sys_caches/*"
				cp "${cmdOpts[@]}" "$_path_script_data_caches" "$_path_sys_caches" 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "rstr" "Data: Caches" "$logFile"; fi
				rm -rf "$_path_sys_explorer/*"
				cp "${cmdOpts[@]}" "$_path_script_data_explorer" "$_path_sys_explorer" 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "rstr" "Data: Explorer" "$logFile"; fi
				
				# Restore Registry Key
				reg import "$_path_script_data_registry_start_menu" 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "rstr" "Registry: Start Menu" "$logFile"; fi
			fi

			# Restore Taskbar
			if [ "$_cfg_include_task_bar" -eq 1 ]; then
				# Restore Data files, reporting any errors that occur
				rm -rf "$_path_sys_task_bar/*"
				cp "${cmdOpts[@]}" "$_path_script_data_task_bar" "$_path_sys_task_bar" 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "rstr" "Data: Task Bar" "$logFile"; fi

				# Backup Registry Key
				reg import "$_path_script_data_registry_task_bar" 2>&1 >> "$logFile"
				if [ "$?" -ne 0 ]; then printErr "rstr" "Registry: Task Bar" "$logFile"; fi
			fi

			# Restart Explorer Process
			explorer.exe
		fi
	fi
	
	# Clear Memory
	unset cmdOpts logFile trv
}

# ##------------------------------------##
# #|		Variables		|#
# ##------------------------------------##
# Paths: Script-Related
_path_script_root="Desktop/STB"								# Script: RootDir
_path_script_profile="Default"								# Script: ProfileDir
_path_script_data="Data"								# Script: DataDir
_path_script_logs="log"									# Script: LogDir
_path_script_data_cloud_store="CloudStore"						# Script: Data/CloudStore
_path_script_data_caches="Caches"							# Script: Data/Caches
_path_script_data_explorer="Explorer"							# Script: Data/Explorer
_path_script_data_task_bar="Taskbar"							# Script: Data/Taskbar
_path_script_data_registry="Registry"							# Script: Data/Registry
_path_script_data_registry_start_menu="CloudStore.reg"					# Script: Data/Registry/Startmenu registry key
_path_script_data_registry_task_bar="Taskband.reg"					# Script: Data/Registry/Taskbar registry key

# Paths: System-Drive related
_path_sys_appdata_roaming=""								# System: AppData/Roaming
_path_sys_appdata_local=""								# System: AppData/Local
_path_sys_cloud_store="Microsoft/Windows/CloudStore"					# System: CloudStore
_path_sys_caches="Microsoft/Windows/Caches"						# System: Caches
_path_sys_explorer="Microsoft/Windows/Explorer"						# System: Explorer
_path_sys_task_bar="Microsoft/Internet Explorer/Quick Launch/User Pinned/TaskBar"	# System: Taskbar

# Registry Values
_path_reg_root="HKCU\\Software\\Microsoft\\CurrentVersion"				# Registry: Keys Root
_path_reg_start_menu="CloudStore"							# Registry: Start Menu
_path_reg_task_bar="Explorer\\Taskband"							# Registry: Taskbar

# Configuration
_cfg_include_start_menu="0"								# Include: Start Menu
_cfg_include_task_bar="0"								# Include: Taskbar
_cfg_force_prompts="0"									# Confirm: Skip

# CP Configuration
_cfg_cp_trim_slashes="0"								# cp: Trim trailing slashes
_cfg_cp_verbose="0"									# cp: Verbose Logging
_cfg_cp_reg_opts="-Rdux"								# cp: default options

# Runtime Job
_var_job_restore="0"									# Job: Backup(0)/Restore(1)

# ##--------------------------------------------##
# #|		Update Variables		|#
# ##--------------------------------------------##
# Paths
if ! printf "$_path_script_root" | grep -q "$HOME"; then _path_script_root="$HOME/$_path_script_root"; fi
if ! printf "$_path_script_profile" | grep -q "$_path_script_root"; then _path_script_profile="$_path_script_root/$_path_script_profile"; fi
if ! printf "$_path_script_data" | grep -q "$_path_script_profile"; then _path_script_data="$_path_script_profile/$_path_script_data"; fi
if ! printf "$_path_script_logs" | grep -q "$_path_script_profile"; then _path_script_logs="$_path_script_profile/$_path_script_logs"; fi
if ! printf "$_path_script_data_cloud_store" | grep -q "$_path_script_data"; then _path_script_data_cloud_store="$_path_script_data/$_path_script_data_cloud_store"; fi
if ! printf "$_path_script_data_caches" | grep -q "$_path_script_data"; then _path_script_data_caches="$_path_script_data/$_path_script_data_caches"; fi
if ! printf "$_path_script_data_explorer" | grep -q "$_path_script_data"; then _path_script_data_explorer="$_path_script_data/$_path_script_data_explorer"; fi
if ! printf "$_path_script_data_task_bar" | grep -q "$_path_script_data"; then _path_script_data_task_bar="$_path_script_data/$_path_script_data_task_bar"; fi
if ! printf "$_path_script_data_registry" | grep -q "$_path_script_data"; then _path_script_data_registry="$_path_script_data/$_path_script_data_registry"; fi
if ! printf "$_path_script_data_registry_start_menu" | grep -q "$_path_script_data_registry"; then _path_script_data_registry_start_menu="$_path_script_data_registry/$_path_script_data_registry_start_menu"; fi
if ! printf "$_path_script_data_registry_task_bar" | grep -q "$_path_script_data_registry"; then _path_script_data_registry_task_bar="$_path_script_data_registry/$_path_script_data_registry_task_bar"; fi
if [ -z "$_path_sys_appdata_roaming" ]; then _path_sys_appdata_roaming="$APPDATA"; fi
if [ -z "$_path_sys_appdata_local" ]; then _path_sys_appdata_local="$LOCALAPPDATA"; fi
if ! printf "$_path_sys_cloud_store" | grep -q "$_path_sys_appdata_local"; then _path_sys_cloud_store="$_path_sys_appdata_local/$_path_sys_cloud_store"; fi
if ! printf "$_path_sys_caches" | grep -q "$_path_sys_appdata_local"; then _path_sys_caches="$_path_sys_appdata_local/$_path_sys_caches"; fi
if ! printf "$_path_sys_explorer" | grep -q "$_path_sys_appdata_local"; then _path_sys_explorer="$_path_sys_appdata_local/$_path_sys_explorer"; fi
if ! printf "$_path_sys_task_bar" | grep -q "$_path_sys_appdata_roaming"; then _path_sys_task_bar="$_path_sys_appdata_roaming/$_path_sys_task_bar"; fi

# Convert vars to POSIX-compliant paths
_path_script_root="$(win2pos "$_path_script_root")"
_path_script_profile="$(win2pos "$_path_script_profile")"
_path_script_data="$(win2pos "$_path_script_data")"
_path_script_logs="$(win2pos "$_path_script_logs")"
_path_script_data_cloud_store="$(win2pos "$_path_script_data_cloud_store")"
_path_script_data_caches="$(win2pos "$_path_script_data_caches")"
_path_script_data_explorer="$(win2pos "$_path_script_data_explorer")"
_path_script_data_task_bar="$(win2pos "$_path_script_data_task_bar")"
_path_script_data_registry="$(win2pos "$_path_script_data_registry")"
_path_script_data_registry_start_menu="$(win2pos "$_path_script_data_registry_start_menu")"
_path_script_data_registry_task_bar="$(win2pos "$_path_script_data_registry_task_bar")"
_path_sys_appdata_roaming="$(win2pos "$_path_sys_appdata_roaming")"
_path_sys_appdata_local="$(win2pos "$_path_sys_appdata_local")"
_path_sys_cloud_store="$(win2pos "$_path_sys_cloud_store")"
_path_sys_caches="$(win2pos "$_path_sys_caches")"
_path_sys_explorer="$(win2pos "$_path_sys_explorer")"
_path_sys_task_bar="$(win2pos "$_path_sys_task_bar")"

# ##--------------------------------------------##
# #|		Handle Arguments		|#
# ##--------------------------------------------##
OPTS=$(getopt \
	-o hfbrvtp: \
	--long help,force,start-menu,task-bar,both,backup,restore,trim,verbose,profile:,root-dir: \
	-n 'StartTileBackup_Args' -- "$@")
eval set -- "$OPTS"
while true; do
	case "$1" in
		-h | --help )		show_help; usv; return 0;;
		-f | --force )		_cfg_force_prompts="1"; shift;;
		-b | --backup )		_var_job_restore="0"; shift;;
		-r | --restore )	_var_job_restore="1"; shift;;
		-v | --verbose )	_cfg_cp_verbose="1"; shift;;
		-t | --trim )		_cfg_cp_trim_slashes="1"; shift;;
		-p | --profile )	_path_script_profile="$2"; shift 2;;
		--start-menu )		_cfg_include_start_menu="1"; shift;;
		--task-bar )		_cfg_include_task_bar="1"; shift;;
		--both )		_cfg_include_start_menu="1"; _cfg_include_task_bar="1"; shift;;
		--root-dir )		_path_script_root="$2"; shift 2;;
		-- )			shift; break;;
		* )			break;;
	esac
done

# ##------------------------------------##
# #|		Pre-Run Checks		|#
# ##------------------------------------##
# Options Check
if [ "$(checkOpts)" -ne 0 ]; then usv; return 1; fi

# ##----------------------------##
# #|		Run		|#
# ##----------------------------##
# Run Backup or Restore
if [ "$_var_job_restore" -eq 1 ]; then tileRestore; elif [ "$_var_job_restore" -eq 0 ]; then tileBackup; fi

# Clean up memory
usv
