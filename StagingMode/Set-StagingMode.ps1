<#

.AUTHOR
    Milton Halton

.SYNOPSIS
    This script is to simply toggle on/off the Staging Mode setting on an AD Connect server.

.DESCRIPTION
    This script is to simply toggle on/off the Staging Mode setting on an AD Connect server.

#>

#Requires -modules ADSync

#Check if module is present, if not import it

if (-not (Get-Module -Name ADSync)){
    Import-Module "C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync\ADSync.psd1"
}

$GlobalSettings = Get-ADSyncGlobalSettings

$StagingModeSettings = $GlobalSettings.Parameters["Microsoft.Synchronize.StagingMode"]

if ($StagingModeSettings.Value -eq $False){
    $GlobalSettings.Parameters["Microsoft.Synchronize.StagingMode"].Value = $True
}
else {
    $GlobalSettings.Parameters["Microsoft.Synchronize.StagingMode"].Value = $False
}

Set-ADSyncGlobalSettings -GlobalSettings $GlobalSettings | Out-Null

Get-ADSyncScheduler | Select StagingModeEnabled