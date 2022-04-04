param($target)
if (-not $target) {
    $target = Join-Path $Env:ProgramFiles 'platform-tools'
}
$thisrepofiles = 'https://raw.githubusercontent.com/Luiz-Monad/Latest-adb-fastboot-installer-for-windows/master/files/'

# Initial message
Write-Host '===================================================='
Write-Host 'All Praises be to God , who have Created All Things,'
Write-Host 'While He Himself is Uncreated'
Write-Host '===================================================='
Write-Host 'Latest ADB Fastboot and USB Driver Installer tool'
Write-Host 'By fawazahmed0 @ xda-developers'
Write-Host '===================================================='
Write-Host

# For debugging this script just use Powershell ISE.
# Start powershell as admin, and run this script as nameofscript.bat > mylog.txt 2>myerror.txt


# Source: https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file
# Source: https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights
# batch code to request admin previleges, if no admin previleges
net session > $null 2>&1
if (-not $LASTEXITCODE -eq 0) {
    powershell -executionpolicy bypass start -verb runas "$PSCommandPath" am_admin 
    exit
}

Write-Host 'Please connect your phone in USB Debugging Mode with MTP or File Transfer'
Write-Host 'Option selected, for Proper USB drivers installation, you can do this now,'
Write-Host 'while the installation is running [Optional Step, Highly Recommended]'

# Adding timout
# Source: http://blog.bitcollectors.com/adam/2015/06/waiting-in-a-batch-file/
# Source: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/start-sleep?view=powershell-6
Start-Sleep -Seconds 10

Write-Host
Write-Host 'Starting Installation'

# Going back to script directory
# get-help about_Scripts
Push-Location $PSScriptRoot

# Source: https://serverfault.com/questions/132963/windows-redirect-stdout-and-stderror-to-nothing
# Null stdout redirection
# Creating temporary directory and using it
Write-Host 'Creating temp folder'
Remove-Item -Force -EA Ignore temporarydir
New-Item -ItemType Directory temporarydir

# Similar to cd command
Push-Location temporarydir

# Source: https://stackoverflow.com/questions/4619088/windows-batch-file-file-download-from-a-url
# Downloading the latest platform tools from google
Write-Host 'Downloading the latest adb and fastboot tools'
Invoke-WebRequest 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile 'adbinstallerpackage.zip'

Write-Host 'Downloading latest usb drivers'
Invoke-WebRequest 'https://dl.google.com/android/repository/latest_usb_driver_windows.zip' -OutFile 'google_usb_driver.zip'
Invoke-WebRequest "$thisrepofiles/google64inf" -OutFile 'google64inf'
Invoke-WebRequest "$thisrepofiles/google86inf" -OutFile 'google86inf'
Invoke-WebRequest "$thisrepofiles/Stringsvals" -OutFile 'Stringsvals'
Invoke-WebRequest "$thisrepofiles/kmdf" -OutFile 'kmdf'
Invoke-WebRequest "$thisrepofiles/Latest-ADB-Launcherps1" -OutFile 'Latest-ADB-Launcher.ps1'

#Fetching devcon.exe and powershell script
Invoke-WebRequest "$thisrepofiles/fetch_hwidps1" -OutFile 'fetch_hwid.ps1'
Invoke-WebRequest "$thisrepofiles/devconexe" -OutFile 'devcon.exe'

# Source: https://pureinfotech.com/list-environment-variables-windows-10/
# Using Environment varaibles for programe files
# Uninstalling/removing the platform tools older version, if they exists and  killing instances of adb if they are running
Write-Host 'Uninstalling older version'
Invoke-Command { adb kill-server } > $null 2>&1
Invoke-Command { Get-Process -Name adb | Stop-Process -Force } > $null 2>&1
Remove-Item -Recurse -Force -EA Ignore $target
New-Item -ItemType Directory $target

# Source: https://stackoverflow.com/questions/37814037/how-to-unzip-a-zip-file-with-powershell-version-2-0
# Source: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-6
# Extracting the .zip file to installation location
function extract($filename, $target) {
    $shell_app = new-object -com shell.application
    $zip_file = $shell_app.namespace((Get-Item $filename).Fullname)
    $destination = $shell_app.namespace((Get-Item $target).FullName)
    $destination.Copyhere($zip_file.items())
}

Write-Host 'Installing the files'
extract -filename 'adbinstallerpackage.zip' -target $target
Move-Item "$target/platform-tools/*" $target
Remove-Item "$target/platform-tools"

Write-Host 'Installing USB drivers'
extract -filename 'google_usb_driver.zip' -target (Get-Location)

# Calling powershell script to fetch the unknown usb driver hwids and inserting that in inf file
./fetch_hwid.ps1

# Source: https://github.com/koush/UniversalAdbDriver
# Source: https://forum.xda-developers.com/google-nexus-5/development/adb-fb-apx-driver-universal-naked-t2513339
# Source: https://stackoverflow.com/questions/60034/how-can-you-find-and-replace-text-in-a-file-using-the-windows-command-line-envir
# Source: https://stackoverflow.com/questions/51060976/search-multiline-text-in-a-file-using-powershell
# Source: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/add-content?view=powershell-6
# Combining multiple inf Files to support all the devices
Get-Content Stringsvals | Add-Content usb_driver\android_winusb.inf
(Get-Content usb_driver\android_winusb.inf | Out-String) -replace '\[Google.NTamd64\]', (Get-Content google64inf | Out-String) | Out-File usb_driver\android_winusb.inf
(Get-Content usb_driver\android_winusb.inf | Out-String) -replace '\[Google.NTx86\]', (Get-Content google86inf | Out-String) | Out-File usb_driver\android_winusb.inf
(Get-Content usb_driver\android_winusb.inf | Out-String) -replace '\[Strings\]', (Get-Content kmdf | Out-String) | Out-File usb_driver\android_winusb.inf

# Fetching unsigned driver installer tool
Write-Host 'Downloading unsigned driver installer tool'
Invoke-WebRequest "$thisrepofiles/unsigned_driver_installerps1" -OutFile 'usb_driver\unsigned_driver_installer.ps1'

# Running unsigned_driver_installer tool
Push-Location usb_driver
Write-Host
./unsigned_driver_installer.ps1 -nopause
Pop-Location

# # Doing fastboot drivers installation
# # Source: https://support.microsoft.com/en-us/help/110930/redirecting-error-messages-from-command-prompt-stderr-stdout
# # Source: https://stackoverflow.com/questions/7005951/batch-file-find-if-substring-is-in-string-not-in-a-file
# # Checking if usb debugging authorization is required
# "%PROGRAMFILES%\platform-tools\adb.exe" reboot bootloader > nul 2> temp.txt
# set rbtval=%errorLevel%
# # Source: https://stackoverflow.com/questions/3068929/how-to-read-file-contents-into-a-variable-in-a-batch-file
# # Source: http://batcheero.blogspot.com/2007/06/how-to-enabledelayedexpansion.html
# # Source: https://stackoverflow.com/questions/4367930/errorlevel-inside-if
# # Batch works different that any other programming language
# type temp.txt | findstr /i /C:"unauthorized" 1> NUL

# if %errorLevel% == 0 (
# Write-Host
# Write-Host 'Beginning Fastboot drivers Installation'
# Write-Host
# Write-Host 'Please Press OK on confirmation dialog shown in your phone,'
# Write-Host 'to allow USB debugging authorization'
# Write-Host 'And then press Enter key to continue'
# Start-Sleep -s 3 > $null 2>&1
# pause > NUL
# "%PROGRAMFILES%\platform-tools\adb.exe" reboot bootloader > $null 2>&1

# )
# # Dont give space after %errorLevel%, value will be then assigned with space to rbtval
# if NOT "%rbtval%" == "0" set rbtval=%errorLevel%


# if "%rbtval%" == "0" (
# Write-Host
# Write-Host 'Installing fastboot drivers, Now the device will reboot to fastboot mode'

# # Adding timout , waiting for fastboot mode to boot
# # Source: http://blog.bitcollectors.com/adam/2015/06/waiting-in-a-batch-file/
# # Source: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/start-sleep?view=powershell-6
# Write-Host 'Waiting for fastboot mode to load'
# Start-Sleep -s 7 > $null 2>&1

# # Source: https://stackoverflow.com/questions/50370658/bypass-vs-unrestricted-execution-policies
# # Executing ps1 to fetch the hwid of fastboot device
# powershell -executionpolicy bypass .\fetch_hwid.ps1

# # Call driver installer
# pushd usb_driver
# Write-Host
# Write-Host '| call unsigned_driver_installer.bat'
# popd

# # Source: https://stackoverflow.com/questions/52060842/check-for-empty-string-in-batch-file
# # Checking for fastboot device before doing a fastboot reboot
# "%PROGRAMFILES%\platform-tools\fastboot.exe" devices > temp.txt
# set /p fbdev=<temp.txt
# if defined fbdev ( "%PROGRAMFILES%\platform-tools\fastboot.exe" reboot > $null 2>&1  )
# )
# # killing adb server
# "%PROGRAMFILES%\platform-tools\adb.exe" kill-server > $null 2>&1


# # Source: https://stackoverflow.com/questions/51636175/using-batch-file-to-add-to-path-environment-variable-windows-10
# # Source: https://stackoverflow.com/questions/141344/how-to-check-if-directory-exists-in-path/8046515
# # Source: https://stackoverflow.com/questions/9546324/adding-directory-to-path-environment-variable-in-windows
# # Setting the path Environment Variable
# Write-Host
# Write-Host 'Setting the Environment Path'
# SET Key="HKCU\Environment"
# FOR /F "usebackq tokens=2*" %%A IN (`REG QUERY %Key% /v PATH`) DO Set CurrPath=%%B
# Write-Host ';%CurrPath%; | find /C /I ";%PROGRAMFILES%\platform-tools;" > temp.txt'
# set /p VV=<temp.txt
# if "%VV%" EQU "0" (
# SETX PATH "%PROGRAMFILES%\platform-tools;%CurrPath% > $null 2>&1
# )

# https://stackoverflow.com/a/32596713/2437224
# https://superuser.com/a/1278250/1200777
# https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/copy
# Creating 'Latest ADB Launcher' at Desktop
Write-Host "Creating 'Latest ADB Launcher' at Desktop"
$desktop = [Environment]::GetFolderPath('Desktop') | Select -Last 1
Copy-Item -Force "Latest-ADB-Launcher" $desktop -EA ignore

# Deleting the temporary directory
Write-Host 'Deleting the temporary folder'
Pop-Location
Remove-Item -Recurse -Force -EA Ignore temporarydir

# Source:https://stackoverflow.com/questions/7308586/using-batch-Write-Host-with-special-characters
# Escape special chars in Write-Host
# Installation done
Write-Host
Write-Host
Write-Host 'Hurray!! Installation Complete, Now you can run ADB and Fastboot commands'
Write-Host 'using Command Prompt, Beginners can use 'Latest ADB Launcher' located'
Write-Host 'at Desktop, to flash TWRP, GSI etc'
Start-Sleep -Seconds 10
Write-Host
Write-Host 'Note: In Case fastboot mode is not getting detected, just connect your phone'
Write-Host 'in fastboot mode and run the installer tool again.'
Start-Sleep -Seconds 4
Write-Host
Write-Host 'This tool is Sponsored by SendLetters, the Easiest way to Send Letters'
Write-Host 'and Documents Physically Anywhere in the World'
Start-Sleep -Seconds 4
Write-Host
Write-Host 'Press enter to exit'
Read-Host

Pop-Location
