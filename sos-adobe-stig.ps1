# Adobe Reader DC STIG Script
# https://github.com/simeononsecurity
# https://simeononsecurity.ch

# Continue on error
$ErrorActionPreference = 'Continue'

# Elevate privileges for this process
Write-Output "Elevating privileges for this process"
$elevationSuccess = $false
$process = Get-Process -Id $PID
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($windowsIdentity)

if ($windowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $elevationSuccess = $true
}
else {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
        FileName = $process.Path
        Arguments = "-File `"$PSCommandPath`""
        Verb = 'RunAs'
        WorkingDirectory = $PSScriptRoot
    }
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $elevationSuccess = $process.Start()
}

if (-not $elevationSuccess) {
    Write-Warning "Failed to elevate privileges. Aborting script."
    exit 1
}

# Unblock all files required for the script
Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" -Recurse | Unblock-File

# Set directory to PSScriptRoot
Set-Location -Path $PSScriptRoot

# Implement Adobe Reader DC STIG
Write-Host "Implementing Adobe Reader DC STIG..." -ForegroundColor Green -BackgroundColor Black

$featureLockDownPath = "HKLM:\Software\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown"

$featureLockDownItems = @(
    "cCloud",
    "cDefaultLaunchURLPerms",
    "cServices",
    "cSharePoint",
    "cWebmailProfiles",
    "cWelcomeScreen"
)

foreach ($item in $featureLockDownItems) {
    New-Item -Path $featureLockDownPath -Name $item -Force | Out-Null
}

Set-ItemProperty -Path "HKLM:\Software\Adobe\Acrobat Reader\DC\Installer" -Name DisableMaintenance -Type DWORD -Value 1 -Force
Set-ItemProperty -Path $featureLockDownPath -Name bAcroSuppressUpsell -Type DWORD -Value 1 -Force
Set-ItemProperty -Path $featureLockDownPath -Name bDisablePDFHandlerSwitching -Type DWORD -Value 1 -Force
Set-ItemProperty -Path $featureLockDownPath -Name bDisableTrustedFolders -Type DWORD -Value 1 -Force
Set-ItemProperty -Path $featureLockDownPath -Name bDisableTrustedSites -Type DWORD -Value 1 -Force
Set-ItemProperty -Path $featureLockDownPath -Name bEnableFlash -Type DWORD -Value 0 -Force
Set-ItemProperty -Path $featureLockDownPath -Name bEnhancedSecurityInBrowser -Type DWORD -Value 1 -Force
Set-ItemProperty -Path $featureLockDownPath -Name bEnhancedSecurityStandalone -Type DWORD -Value 1 -Force
Set-ItemProperty -Path $featureLockDownPath -Name bProtectedMode -Type DWORD -Value 1 -Force
Set-ItemProperty -Path $featureLockDownPath -Name iFileAttachmentPerms -Type DWORD -Value 1 -Force
Set-ItemProperty -Path $featureLockDownPath -Name iProtectedView -Type DWORD -Value 2 -Force

Set-ItemProperty -Path "$featureLockDownPath\cCloud" -Name bAdobeSendPluginToggle -Type DWORD -Value 1 -Force
Set-ItemProperty -Path "$featureLockDownPath\cDefaultLaunchURLPerms" -Name iURLPerms -Type DWORD -Value 1 -Force
Set-ItemProperty -Path "$featureLockDownPath\cDefaultLaunchURLPerms" -Name iUnknownURLPerms -Type DWORD -Value 3 -Force

Set-ItemProperty -Path "$featureLockDownPath\cServices" -Name bToggleAdobeDocumentServices -Type DWORD -Value 1 -Force
Set-ItemProperty -Path "$featureLockDownPath\cServices" -Name bToggleAdobeSign -Type DWORD -Value 1 -Force
Set-ItemProperty -Path "$featureLockDownPath\cServices" -Name bTogglePrefsSync -Type DWORD -Value 1 -Force
Set-ItemProperty -Path "$featureLockDownPath\cServices" -Name bToggleWebConnectors -Type DWORD -Value 1 -Force
Set-ItemProperty -Path "$featureLockDownPath\cServices" -Name bUpdater -Type DWORD -Value 0 -Force

Set-ItemProperty -Path "$featureLockDownPath\cSharePoint" -Name bDisableSharePointFeatures -Type DWORD -Value 1 -Force
Set-ItemProperty -Path "$featureLockDownPath\cWebmailProfiles" -Name bDisableWebmail -Type DWORD -Value 1 -Force
Set-ItemProperty -Path "$featureLockDownPath\cWelcomeScreen" -Name bShowWelcomeScreen -Type DWORD -Value 0 -Force

Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Adobe\Acrobat Reader\DC\Installer" -Name DisableMaintenance -Type DWORD -Value 1 -Force

# Implement Adobe Reader DC STIG GPO
Write-Host "Implementing Adobe Reader DC STIG GPO..." -ForegroundColor White -BackgroundColor Black
$lgpoPath = Join-Path $PSScriptRoot "Files\LGPO\LGPO.exe"
$gpoPath = Join-Path $PSScriptRoot "Files\GPO\"

if (Test-Path $lgpoPath -and Test-Path $gpoPath) {
    Start-Process -FilePath $lgpoPath -ArgumentList "/g $gpoPath" -Wait
}
else {
    Write-Warning "LGPO.exe or GPO files not found. GPO configuration skipped."
}

Write-Host "Done" -ForegroundColor Green -BackgroundColor Black
