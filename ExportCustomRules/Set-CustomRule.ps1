<#

.AUTHOR
    Milton Halton

.SYNOPSIS
    Replace the source computer connector Ids in the .ps1 files with the ones on the target computer

.DESCRIPTION
    Use this script to replace the source computer connector Ids in the .ps1 files with the ones on the target computer, if script ExportCustomRules.ps1 at https://github.com/mbendana/ADConnect/blob/ExportCustomRules/ExportCustomRules/Export-CustomRule.ps1 did not complete successfully.

#>

#Requires -modules ADSync

#Check if the ADSync module is loaded. If not, import it.
if (-not (Get-Module -Name ADSync)){
    Import-Module "C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync\ADSync.psd1"
}

foreach($folder in (Get-ChildItem -Path "$HOME\Desktop\ADConnectExportedCustomRules\" -Directory)){
    $sourceConnectorId = $folder.Name.split("_")[2]
    $sourceConnectorName = $folder.Name.split("_")[0]
    try{
        if($sourceConnectorName -eq "Cloud"){
            $targetConnector = Get-ADSyncConnector | Where-Object { ($_.Name -like "*AAD") -and ($_.ConnectorTypeName -eq "Extensible2")}
            $targetConnectorId = $targetConnector.Identifier
        }else{
            $targetConnector = Get-ADSyncConnector -Name $sourceConnectorName
            $targetConnectorId = $targetConnector.Identifier
        }
    }
    catch{
        Write-Warning "No connector with name $sourceConnectorName found on target computer $env:COMPUTERNAME"
    }
            
    $files = Get-ChildItem -Path $folder.FullName -Filter "*.ps1" -File

    foreach ($file in $files){
        $parentPath = $file.PSParentPath
        $fileName = $file.Name

        $fileContent = (Get-Content $file.FullName -raw) -replace $sourceConnectorId, $targetConnectorId

        Set-Content -Value $fileContent -Path $file.FullName
    }
}
