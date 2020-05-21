#Requires -modules ADSync

#Check if module is present, if not import it

if (-not (Get-Module -Name ADSync)){
    Import-Module "C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync\ADSync.psd1"
}
#$originalStagingModeSetting = (Get-ADSyncScheduler).StagingModeEnabled

$GlobalSettings = Get-ADSyncGlobalSettings

$StagingModeSettings = $GlobalSettings.Parameters["Microsoft.Synchronize.StagingMode"]

if ($StagingModeSettings.Value -eq $False){
    $GlobalSettings.Parameters["Microsoft.Synchronize.StagingMode"].Value = $True
}
else {
    $GlobalSettings.Parameters["Microsoft.Synchronize.StagingMode"].Value = $False
}

Set-ADSyncGlobalSettings -GlobalSettings $GlobalSettings | Out-Null

#$currentStagingModeSetting = (Get-ADSyncScheduler).StagingModeEnabled

#if ($currentStagingModeSetting -eq $True){
#    $currentStagingModeSetting = "Enabled"
#}
#else {
#    $currentStagingModeSetting = "Disabled"
#}

#Write-Output "`nPrevious Staging Mode state was $originalStagingModeSetting"

#Write-Output "`nStaging Mode has been $currentStagingModeSetting"

Get-ADSyncScheduler | Select StagingModeEnabled