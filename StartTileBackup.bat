:: StartTileBackup.bat
:: Author:		Alex Paarfus <apaarfus@wtcox.com>
:: Date:		2019-03-22
::
:: Backups/Restores TaskBar and StartMenu configurations in Windows 10
::
:: Based on 
::		https://github.com/TurboLabIt/StartTileBackup
::		https://github.com/dwrolvink/StartTileBackup
::
:: Requirements:
::		Windows 10 1803+
::		Administrator Rights
:: ----------------------------------------------------------------------------

:: Env Opts
@echo off
setlocal enableextensions
:: ----------------------------------------------------------------------------

:: Check for Admin Rights
net session >nul 2>&1
if not %errorlevel% equ 0 (
	echo Error: ADMIN REQUIRED
	call :logMsg "ADMIN REQUIRED" "error"
	goto :eof
)
:: ----------------------------------------------------------------------------

:: Vars
set "datestamp=%date:~10,4%-%date:~4,2%-%date:~7,2%"
set "_bdir=bkup"
::set "_ldir=log"
::set "_lgf=%datestamp%.log"
set "_cloudDir=%localappdata%\Microsoft\Windows\CloudStore"
set "_cacheDir=%localappdata%\Microsoft\Windows\Caches"
set "_explorerDir=%localappdata%\Microsoft\Windows\Explorer"
set "_taskbarDir=%appdata%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
set "_smkey=HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore"
set "_tbkey=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
set "buOpt=/e /np /nfl /ndl /njh /njs /ns /nc"
set "buCmd=robocopy"
set "_SEP=++++++++++++++++++++++++++++++++++++++++++++++++++"
set "_proc=b"
set "_FAIL=0"
:: ----------------------------------------------------------------------------

:: Handle Arguments
if "%~1."=="." goto :eof
if not "%~1."=="." (
	:paLoopStart
		:: Check to exit loop
		if /i "%~1."=="." goto :paLoopEnd
		if %_FAIL% equ 1 goto :paLoopEnd
		
		:: Determine if named argument
		if not "%~2."=="." (
			cd .
			echo %~2 | findstr /b /c:"--" >nul || (
				if /i "%~1"=="--bd" set "_bdir=%~2" & shift & goto :paLoopNext
				if /i "%~1"=="--ld" set "_ldir=%~2" & shift & goto :paLoopNext
				if /i "%~1"=="--lf" set "_lgf=%~2" & shift & goto :paLoopNext
				echo Unknown Option: "%~1 %~2"
			)
		)
		
		:: Single Args
		cd .
		echo %~1 | find "--" >nul 2>&1
		if %errorlevel% neq 0 goto :paLoopNext
		if /i "%~1"=="--h" call :showHelp & set "_FAIL=1" & goto :paLoopEnd
		if /i "%~1"=="--?" call :showHelp & set "_FAIL=1" & goto :paLoopEnd
		if /i "%~1"=="--b" set "_proc=b" & goto :paLoopNext
		if /i "%~1"=="--r" set "_proc=r" & goto :paLoopNext
	:paLoopNext
	shift
	goto :paLoopStart
)
:paLoopEnd
:: ----------------------------------------------------------------------------

:: Check Arguments
call :checkOpts
:: ----------------------------------------------------------------------------

:: Path Updates
cd .
echo "%_bdir%" | find ":" >nul || set "_bdir=%~dp0.\%_bdir%"
::set "_ldir=%~dp0.\%_ldir%"
:: ----------------------------------------------------------------------------

:: Run
if %_FAIL% equ 0 (
	if /i "%_proc%"=="r" call :rstr
	if /i "%_proc%"=="b" call :bkup
)

:: Clear memory and Quit
call :usv
goto :eof
:: ----------------------------------------------------------------------------

:: Functions
:: Backup Start Menu Tiles
:bkup
	:: Init Environment
	cd "%~dp0"
	
	:: Remove previous backup if necessary; then Make Directory
	if exist "%_bdir%" rd /s /q "%_bdir%"
	md "%_bdir%"
	
	:: Kill Explorer -- required to read data from system files
	call :kex
	
	:: Backup data to backup directory
	%buCmd% "%_cloudDir%" "%_bdir%\CloudStore" %buOpt%
	%buCmd% "%_cacheDir%" "%_bdir%\Caches" %buOpt%
	%buCmd% "%_explorerDir%" "%_bdir%\Explorer" %buOpt%
	%buCmd% "%_taskbarDir%" "%_bdir%\TaskBar" %buOpt%
	
	:: Extract registry data to backup directory
	reg export "%_smkey%" "%_bdir%\CloudStore.reg"
	reg export "%_tbkey%" "%_bdir%\Taskband.reg" /y
	
	:: Restart Explorer
	explorer.exe
goto :eof
:: ----------------------------------------------------------------------------

:: Restore Backup Start Menu Tiles
:rstr
	:: Initialize Environment
	cd "%~dp0"
	
	:: Check for Backup Dir
	if not exist "%_bdir%" (
		echo ERROR: BKUP DIR DOES NOT EXIST
		ping 127.0.0.1 -n 5 >nul 2>&1
		goto :eof
	)
	
	:: Kill Explorer -- required to write data to system file locations
	call :kex
	
	:: Remove system directories to make way for the soon-to-be restored data
	rd /s /q "%_cloudDir%"
	rd /s /q "%_cacheDir%"
	rd /s /q "%_explorerDir%"
	rd /s /q "%_taskbarDir%"
	
	:: Restore data to system directories
	%buCmd% "%_bdir%\CloudStore" "%_cloudDir%" %buOpt%
	%buCmd% "%_bdir%\Caches" "%_cacheDir%" %buOpt%
	%buCmd% "%_bdir%\Explorer" "%_explorerDir%" %buOpt%
	%buCmd% "%_bdir%\TaskBar" "%_taskbarDir%" %buOpt%
	
	:: Restore registry keys
	reg import "%_bdir%\CloudStore.reg"
	reg import "%_bdir%\Taskband.reg"
	
	:: Restart Explorer
	explorer.exe
goto :eof
:: ----------------------------------------------------------------------------

:: Check Options
:checkOpts
	:: If already in failed state, skip
	if %_FAIL% gtr 0 goto :eof
	
	:: Nul Value checks
	if "%datestamp%."=="." call :notifyFailure "0"
	if "%_bdir%."=="." call :notifyFailure "1"
	::if "%_ldir%."=="." call :notifyFailure "2"
	::if "%_lgf%."=="." call :notifyFailure "3"
	if "%_cloudDir%."=="." call :notifyFailure "4"
	if "%_cacheDir%."=="." call :notifyFailure "5"
	if "%_explorerDir%."=="." call :notifyFailure "6"
	if "%_taskbarDir%."=="." call :notifyFailure "7"
	if "%_smkey%."=="." call :notifyFailure "8"
	if "%_tbkey%."=="." call :notifyFailure "9"
	if "%buOpt%."=="." call :notifyFailure "10"
	if "%buCmd%."=="." call :notifyFailure "11"
	if "%_proc%."=="." call :notifyFailure" "12
	
	:: Invalid Locations
	::if not exist "%~dp0.\%_bdir%" call :notifyFailure "13"
	::if not exist "%~dp0.\%_ldir%" call :notifyFailure "14"
	if not exist "%_cloudDir%" call :notifiyFailure "15"
	if not exist "%_cacheDir%" call :notifyFailure "16"
	if not exist "%_explorerDir%" call :notifyFailure "17"
	if not exist "%_taskbarDir%" call :notifyFailure "18"
goto :eof
:: ----------------------------------------------------------------------------

:: Notify user of Failure State -- Args: %1 = State
:notifyFailure
	if "%~1."=="." goto :eof
	set "nulstr=ERROR: Var not defined:"
	set "badstr=ERROR: Directory does not exist:"
	
	:: Reports
	if %~1 equ 0 echo %nulstr% datestamp & set "_FAIL=1" & goto :qnfs
	if %~1 equ 1 echo %nulstr% backup directory & set "_FAIL=1" & goto :qnfs
	if %~1 equ 2 echo %nulstr% logging directory & set "_FAIL=1" & goto :qnfs
	if %~1 equ 3 echo %nulstr% Log File & set "_FAIL=1" & goto :qnfs
	if %~1 equ 4 echo %nulstr% Cloud Store directory & set "_FAIL=1" & goto :qnfs
	if %~1 equ 5 echo %nulstr% Caches directory & set "_FAIL=1" & goto :qnfs
	if %~1 equ 6 echo %nulstr% Explorer directory & set "_FAIL=1" & goto :qnfs
	if %~1 equ 7 echo %nulstr% Task Bar directory & set "_FAIL=1" & goto :qnfs
	if %~1 equ 8 echo %nulstr% Start Menu registry location & set "_FAIL=1" & goto :qnfs
	if %~1 equ 9 echo %nulstr% Task Bar registry location & set "_FAIL=1" & goto :qnfs
	if %~1 equ 10 echo %nulstr% Backup Command Options & set "_FAIL=1" & goto :qnfs
	if %~1 equ 11 echo %nulstr% Backup Command & set "_FAIL=1" & goto :qnfs
	if %~1 equ 12 echo %nulstr% Process Selection & set "_FAIL=1" & goto :qnfs
	if %~1 equ 13 echo %badstr% "%_bdir%" & set "_FAIL=1" & goto :qnfs
	if %~1 equ 14 echo %badstr% "%_ldir%" & set "_FAIL=1" & goto :qnfs
	if %~1 equ 15 echo %badstr% "%_cloudDir%" & set "_FAIL=1" & goto :qnfs
	if %~1 equ 16 echo %badstr% "%_cacheDir%" & set "_FAIL=1" & goto :qnfs
	if %~1 equ 17 echo %badstr% "%_explorerDir%" & set "_FAIL=1" & goto :qnfs
	if %~1 equ 18 echo %badstr% "%_taskbarDir%" & set "_FAIL=1" & goto :qnfs
	
	:qnfs
	set "nulstr="
	set "dirstr="
goto :eof
:: ----------------------------------------------------------------------------

:: Kill Explorer
:kex
	taskkill /f /im explorer.exe
goto :eof

:: Logging -- %1 = Msg, %2 = State
:logMsg
	set "_msg=[%datestamp%@%time:~0,8%]"
	set "_ftl=%_ldir%\%_lgf%"
	set "_isErr="
	
	:: Check for log directory
	if not exist "%_ldir%" md "%_ldir%"
	
	:: State/Type
	if "%~2."=="." goto :eof
	if /i "%~2"=="error" set "_msg=%_msg% ERROR: " & goto :getMsg
	if /i "%~2"=="crit" set "_msg=%_msg% CRIT: " & goto :getMsg
	if /i "%~2"=="info" goto :getMsg
	if /i "%~2"=="none" goto :getMsg
	goto :eof
	
	:: Message
	if "%~1."=="." goto :eof
	if "%~1"=="sep" set "_msg=%_msg% %_SEP%" & goto :mkLog
	if "%~1"=="nl" goto :mkLog
	
	:: Log
	:mkLog
	echo %_gwbMsg% %~1 >> "%_ftl%"
goto :eof
:: ----------------------------------------------------------------------------

:: Show Help
:showHelp
	echo StartTileBackup.bat ^[Options^]
	echo Please note that all options must be encapsulated in double-quotes
	echo For example:
	echo     "--x"
	echo     "--y" "name"
	echo.
	echo Options:
	echo     --h, --?                Show this help message
	echo     --b                    Run in Backup Mode ^(default^)
	echo     --r                    Run in Restoration Mode
	echo     --bd ^<path^>          Specify path to backup directory location
	echo     --ld ^<path^>          Specify path to log directory
	echo     --lf ^<file^>          Specify the file name and extension to use in logging
	echo.
goto :eof
:: ----------------------------------------------------------------------------

:: Clear Memory
:usv
	set "datestamp="
	set "_bdir="
	set "_ldir="
	set "_lgf="
	set "_cloudDir="
	set "_cacheDir="
	set "_explorerDir="
	set "_taskbarDir="
	set "_smkey="
	set "_tbkey="
	set "buOpt="
	set "buCmd="
	set "_SEP="
	set "_proc="
	set "_FAIL="
	set "opt="
goto :eof
:: ----------------------------------------------------------------------------
