param($nopause)

$thisrepofiles = 'https://raw.githubusercontent.com/Luiz-Monad/Latest-adb-fastboot-installer-for-windows/master/files/'

# Initial message
Write-Host '===================================================='
Write-Host 'Do not despair of the mercy of God [Quran 39:53]'
Write-Host '===================================================='
Write-Host 'Unsigned Driver Installer Tool For Windows'
Write-Host 'By fawazahmed0 @ GitHub'
Write-Host '===================================================='
Write-Host ''


# Source: https://stackoverflow.com/questions/23735282/if-not-exist-command-in-batch-file/23736306
# Check for .inf file exists or not
if (-not (Get-ChildItem *.inf)) {
    Write-Host 'Please paste this .bat file in driver folder where .inf file is located'
    Write-Host 'Press enter to exit'
    Read-Host
    exit
}

# Source: https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file
# Source: https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights
# batch code to request admin previleges, if no admin previleges
net session > $null 2>&1
if (-not $LASTEXITCODE -eq 0) {
    powershell -executionpolicy bypass start -verb runas "$PSCommandPath" am_admin 
    exit
}

# Going back to script directory
# get-help about_Scripts
Push-Location $PSScriptRoot


# Source: https://stackoverflow.com/questions/4619088/windows-batch-file-file-download-from-a-url
# Fetching the binaries required for signing the driver
Write-Host 'Downloading files required for signing the driver'
Invoke-WebRequest "$thisrepofiles/files.zip" -OutFile 'files.zip'


# Source: https://stackoverflow.com/questions/37814037/how-to-unzip-a-zip-file-with-powershell-version-2-0
# Source: https://www.microsoft.com/en-us/download/details.aspx?id=11800
# These files were take from Windows Driver Kit Version 7.1.0
# Extracting the .zip file
function extract($filename, $target) {
    $shell_app = new-object -com shell.application
    $zip_file = $shell_app.namespace((Get-Item $filename).Fullname)
    $destination = $shell_app.namespace((Get-Item $target).FullName)
    $destination.Copyhere($zip_file.items())
}

extract -filename 'files.zip' -target (Get-Location)

Push-Location files

# Source: http://woshub.com/how-to-sign-an-unsigned-driver-for-windows-7-x64/
# Signing the Drivers
Write-Host 'Signing the drivers'
./inf2cat.exe /driver:.. /os:7_X64 
./inf2cat.exe /driver:.. /os:7_X86 
./SignTool.exe sign /f ./myDrivers.pfx /p testabc /t http://timestamp.verisign.com/scripts/timstamp.dll /v ../*.cat 

# Adding the Certificates
./CertMgr.exe -add ./myDrivers.cer -s -r localMachine ROOT 
./CertMgr.exe -add ./myDrivers.cer -s -r localMachine TRUSTEDPUBLISHER 


# Source: https://stackoverflow.com/questions/22496847/installing-a-driver-inf-file-from-command-line
# If the bat file is launched from 32 bit program i.e firefox etc, the cmd will start as 32 bit with directory as syswow64 in 64bit pc.
# pnputil is not accessible directly from 32 bit cmd and will throw error saying no internal or external command ..
# In that case, it should be accessed from here %WinDir%\Sysnative\
# I assume, the cmd changes to syswow64, after requesting for admin previleges
# Source: https://stackoverflow.com/questions/8253713/what-is-pnputil-exe-location-in-64bit-systems
# Source: https://stackoverflow.com/questions/23933888/pnputil-exe-is-not-recognized-as-an-internal-or-external-command
# Installing Drivers
pnputil -i -a ../*.inf 
if (-not $LASTEXITCODE -eq 0) {
    & "$env:WinDir\Sysnative\pnputil.exe" -i -a ../*.inf 
}

# Source: https://social.technet.microsoft.com/Forums/en-US/d109719c-ca97-41e1-a529-0113e23ff5b0/deleting-a-certificate-using-certmgrexe?forum=winserversecurity
# Removing the Certificates
./CertMgr.exe -del -c -n "Fawaz Ahmed" -s -r localMachine ROOT 
./CertMgr.exe -del -c -n "Fawaz Ahmed" -s -r localMachine TrustedPublisher 

Pop-Location

# Deleting the temporary items
Write-Host 'Deleting the temporary files and folders'
Remove-Item -Recurse -Force -EA Ignore files 
Remove-Item -Force -EA Ignore files.zip 

# Installation done
Write-Host ''
Write-Host 'Driver Installation complete.'
Write-Host 'Press enter to exit'
if (-not $nopause) { Read-Host }

