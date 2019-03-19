:: StartTileBackup.bat
:: Author:		Alex Paarfus <apaarfus@wtcox.com>
:: Date:		2019-03-19
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
if not errorlevel 0 (
	echo Error: ADMIN REQUIRED
	call :logMsg "ADMIN REQUIRED" "error"
	goto :eof
)
:: ----------------------------------------------------------------------------

:: Vars
set "datestamp=%date:~10,4%-%date:~4,2%-%date:~7,2%"
set "_bdir=%~dp0.\bkup"
set "_ldir=%~dp0.\log"
set "_lgf=%datestamp%.log"
set "_cloudDir=%localappdata%\Microsoft\Windows\CloudStore"
set "_cacheDir=%localappdata%\Microsoft\Windows\Caches"
set "_explorerDir=%localappdata%\Microsoft\Windows\Explorer"
set "_taskbarDir=%appdata%\Microsoft\Internet Explorer\User Pinned\TaskBar"
set "_smkey=HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore"
set "_tbkey=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
set "buOpt=/e /x /mt /xo /fft /r:1 /w:5 /xjd /xjf"
set "buCmd=robocopy %buOpt%"
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
		echo "%~1" | find ":" >nul
		if errorlevel 0 goto :namedArg
		cd .
		
		:: Single Args
		if /i "%~1"=="/h" call :showHelp & goto :paLoopEnd
		if /i "%~1"=="/?" call :showHelp & goto :paLoopEnd
		if /i "%~1"=="/b" set "_proc=b" & goto :paLoopNext
		if /i "%~1"=="/r" set "_proc=r" & goto :paLoopNext
		goto :paLoopNext
		
		:: Named Args
		:namedArg
		for /f "tokens=1,2* delims=:" %%a in ("%~1") do call :paNamedArgs "%%~a" "%%~b"
	:paLoopNext
	shift
	goto :paLoopStart
)
:paLoopEnd
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
	"%~d0"
	
	:: Remove previous backup if necessary; then Make Directory
	if exist "%_bdir%" rmdir /sq "%_bdir%"
	mkdir "%_bdir%"
	
	:: Kill Explorer -- required to read data from system files
	call :kex
	
	:: Backup data to backup directory
	%buCmd% "%_cloudDir%" "%_bdir%\CloudStore"
	%buCmd% "%_cacheDir%" "%_bdir%\Caches"
	%buCmd% "%_explorerDir%" "%_bdir%\Explorer"
	%buCmd% "%_taskbarDir%" "%_bdir%\TaskBar"
	
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
	"%~d0"
	
	:: Check for Backup Dir
	if not exist "%_bdir%" (
		echo ERROR: BKUP DIR DOES NOT EXIST
		ping 127.0.0.1 -n 5 >nul 2>&1
		goto :eof
	)
	
	:: Kill Explorer -- required to write data to system file locations
	call :kex
	
	:: Remove system directories to make way for the soon-to-be restored data
	rmdir /sq "%_cloudDir%"
	rmdir /sq "%_cacheDir%"
	rmdir /sq "%_explorerDir%"
	rmdir /sq "%_taskbarDir%"
	
	:: Restore data to system directories
	%buCmd% "%_bdir%\CloudStore" "%_cloudDir%"
	%buCmd% "%_bdir%\Caches" "%_cacheDir%"
	%buCmd% "%_bdir%\Explorer" "%_explorerDir%"
	%buCmd% "%_bdir%\TaskBar" "%_taskbarDir%"
	
	:: Restore registry keys
	reg import "%_smkey%"
	reg import "%_tbkey%" 
	
	:: Restart Explorer
	explorer.exe
goto :eof
:: ----------------------------------------------------------------------------

:: Parse Named Arguments -- %1 = switch, %2 = param
:paNamedArgs
	if "%~1." goto :eof
	if "%~2." goto :eof
	
	:: Parse
	:: Backup Directory
	if /i "%~1"=="/bd" (
		set "_bdir=%~2"
		if not exist "%~2" (
			echo "Error, Backup directory does not exist"
			call :logMsg "Backup directory does not exist: %~2" "error"
			set /p "mdc=Create directory? (y/N): "
			if /i "%mdc%"=="y" mkdir "%~2"
			set "mdc="
			set "_FAIL=1"
		)
		goto :eof
	)
	:: Log Directory
	if /i "%~1"=="/ld" (
		set "_ldir=%~2"
		if not exist "%~2" mkdir "%~2"
		goto :eof
	)
	:: Log File
	if /i "%~1"=="/lf" set "_lgf=%~2" & goto :eof
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
	if not exist "%_ldir%" mkdir "%_ldir%"
	
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
	echo     "/x"
	echo     "/y:name"
	echo.
	echo Options:
	echo     /h, /?                Show this help message
	echo     /b                    Run in Backup Mode ^(default^)
	echo     /r                    Run in Restoration Mode
	echo     /bd:^<path^>          Specify path to backup directory location
	echo     /ld:^<path^>          Specify path to log directory
	echo     /lf:^<file^>          Specify the file name and extension to use in logging
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
