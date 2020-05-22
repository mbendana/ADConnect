<#

.AUTHOR
    Milton Halton

.SYNOPSIS
   Export AD Connect custom rules

.DESCRIPTION
   This script is to export AD Connect custom rules from a source computer (Active ADConnect server) to a target computer (Staging Mode ADConnect server) or viceversa.
The script exports all custom rules from the source computer, including the ones disabled.
The script has been tested with ADConnect versions: 1.3.21.0, 1.4.38.0 and 1.5.30.0.
Since the script uses the Test-NetConnection cmdlet to test connectivity with the target computer for creating a remote session with it, it should be run with PowerShell version 4 and above or in Windows Server 2012 R2.
PowerShell Remoting WinRM port 5985 has to be open on the target computer for the script to complete successfully.

.EXAMPLE
   .\Export-CustomRule.ps1

.EXAMPLE
   .\Export-CustomRule.ps1 -targetComputerName <ComputerName>

.INPUTS
   -targetComputerName (not from pipeline)

.OUTPUTS
   folders and files (not to pipeline)

.FUNCTIONALITY
   This script is to export AD Connect custom rules from a source computer (Active ADConnect server) to a target computer (Staging Mode ADConnect server) or viceversa.
The script exports all custom rules from the source computer, including the ones disabled.
The script has been tested with ADConnect versions: 1.3.21.0, 1.4.38.0 and 1.5.30.0.
Since the script uses the Test-NetConnection cmdlet to test connectivity with the target computer for creating a remote session with it, it should be run with PowerShell version 4 and above or in Windows Server 2012 R2.
PowerShell Remoting WinRM port 5985 has to be open on the target computer for the script to complete successfully.

The only value the script needs is the target computer name:
$targetComputerName

The script creates a folder named "ADConnectExportedCustomRules" under the Desktop folder on the source computer.
For each source computer connector that has at least 1 custom rule related to it, additional folders are created under the "ADConnectExportedCustomRules" folder with the name of the correspoding connector.
1 .ps1 file is created under each connector folder. The file contains all custom rules related to the connector: Inbound/Outbound, Enabled/Disabled.

After the folder and file creations are done, they are all copied over to the target computer.
After the copy operation is done (if the test connectivity with the target computer was successful), the process of replacing the source connector Ids with the target connector Ids in the .ps1 files occurs.

Once the .ps1 files are on the target computer, run the files with PowerShell to import the custom rules.

If the PowerShell Remoting WinRM port 5985 is not open, the AD Connect custom rules are still exported to the source computer but have to be manually copied over to the target computer and the target computer connector Ids in the .ps1 files have to be changed manually as per:
https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-upgrade-previous-version#move-a-custom-configuration-from-the-active-server-to-the-staging-server

ALSO, the script at https://github.com/mbendana/ADConnect/blob/ExportCustomRules/ExportCustomRules/Set-CustomRule.ps1 can be used to automatically change the the connector Ids in the .ps1 files.

#>

#Requires -modules ADSync

#Get the target computer name
[CmdletBinding()]
Param(
      [Parameter(Mandatory=$True)]  [string]$targetComputerName
)

#Set the source folders
$rootFolder = "$HOME\Desktop\"
$targetFolder = "ADConnectExportedCustomRules"
$targetPath = $rootFolder + $targetFolder + "\"

#Test if path exists. If yes, remove all and recreate it. If no, create it
if((Test-Path $targetPath)){
    Remove-Item -Path $targetPath -Recurse -Force
    New-Item -Path $targetPath -ItemType Directory | Out-Null
}
else{
    New-Item -Path $targetPath -ItemType Directory | Out-Null
}

#Get all connectors
$connectors = Get-ADSyncConnector

#Start looping each connector found
foreach($connector in $connectors){

#Assign connector variables
$connectorName = $connector.Name
$connectorId = $connector.Identifier
$connectorType = $connector.ConnectorTypeName

#Get all rules related with current connector in the loop
$customRules = Get-ADSyncRule | Where-Object { ($_.IsStandardRule -eq $False) -and ($_.Connector -eq $connectorId)}

#Set to blank the file which will collect all script content
$customRuleFileContent = @()

#Set custom rule counter
$customRuleCounter = 0

#Continue only if there are rules found
if($customRules.count -gt 0){

#Start looping each rule found
foreach ($customRule in $customRules) {

    $customRuleDirection = $customRule.Direction
    $customRuleIdentifier = $customRule.Identifier

    $description = $customRule.Description.Replace("'","''").Replace("`n","").Trim()
    $isCustomRuleDisabled = $customRule.Disabled

    $customRuleFileContent +=
    "New-ADSyncRule  ``
-Name '$($customRule.Name)' ``
-Identifier '$($customRule.Identifier)' ``
-Description '$($description)' ``
-Direction '$($customRule.Direction)' ``
-Precedence $($customRule.Precedence) ``
-PrecedenceAfter '$($customRule.PrecedenceAfter)' ``
-PrecedenceBefore '$($customRule.PrecedenceBefore)' ``
-SourceObjectType '$($customRule.SourceObjectType)' ``
-TargetObjectType '$($customRule.TargetObjectType)' ``
-Connector '$($customRule.Connector)' ``
-LinkType '$($customRule.LinkType)' ``
-SoftDeleteExpiryInterval 0 ``
-ImmutableTag '' ``"

    if($isCustomRuleDisabled -eq $True){
        $customRuleFileContent +=
"-Disabled ``
-OutVariable syncRule`n"

    }
    else{
        $customRuleFileContent +=
"-OutVariable syncRule`n"
    }

    # WORKING ON ATTRIBUTE FLOW MAPPINGS

    $attributeFlowMappings = $customRule.AttributeFlowMappings

    foreach($attributeFlowMapping in $attributeFlowMappings){

    $flowType = $attributeFlowMapping.FlowType
    $source = $attributeFlowMapping.Source

    $customRuleFileContent += "Add-ADSyncAttributeFlowMapping  ``
-SynchronizationRule `$syncRule[$($customRuleCounter)] ``
-Destination '$($attributeFlowMapping.Destination)' ``
-FlowType '$($attributeFlowMapping.FlowType)' ``
-ValueMergeType '$($attributeFlowMapping.ValueMergeType)' ``"
    
    if($flowType -eq "Expression"){
        $customRuleFileContent +=
"-Expression '$($attributeFlowMapping.Expression)' ``
-OutVariable syncRule`n"
    }
    else{
        $customRuleFileContent +=
"-Source @('$source') ``
-OutVariable syncRule`n"

    }

    }

    # WORKING ON SCOPING FILTERS / CONDITIONS

    $scopeGroupConditions = $customRule.ScopeFilter

    foreach($scopeGroupCondition in $scopeGroupConditions) {
    
    $scopeConditionCounter = 0
    $scopeConditions = @()

    foreach($scopeCondition in $scopeGroupCondition.ScopeConditionList){
        $customRuleFileContent += "New-Object  ``
-TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition' ``
-ArgumentList '$($scopeCondition.Attribute)','$($scopeCondition.ComparisonValue)','$($scopeCondition.ComparisonOperator)' ``
-OutVariable condition$($scopeConditionCounter)`n"

        $scopeConditions += '$condition' + $($scopeConditionCounter) + '[0]'
        $scopeConditionCounter += 1
    }
        
        if($scopeConditions.count -gt 1){
            $scopeConditions = $scopeConditions -join ","
        }

        $customRuleFileContent += "Add-ADSyncScopeConditionGroup  ``
-SynchronizationRule `$syncRule[$($customRuleCounter)] ``
-ScopeConditions @($scopeConditions) ``
-OutVariable syncRule`n"

    }

    # WORKING ON JOIN FILTERS / CONDITIONS

    $joinGroupConditions = $customRule.JoinFilter

    foreach($joinGroupCondition in $joinGroupConditions) {
    
    $joinConditionCounter = 0
    $joinConditions = @()

    foreach($joinCondition in $joinGroupCondition.JoinConditionList){

        $customRuleFileContent += "New-Object  ``
-TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.JoinCondition' ``
-ArgumentList '$($joinCondition.CSAttribute)','$($joinCondition.MVAttribute)', `$$($joinCondition.CaseSensitive) ``
-OutVariable condition$($joinConditionCounter)`n"

        $joinConditions += '$condition' + $($joinConditionCounter) + '[0]'

        $joinConditionCounter += 1
    }
        
        if($joinConditions.count -gt 1){
            $joinConditions = $joinConditions -join ","
        }

        $customRuleFileContent += "Add-ADSyncJoinConditionGroup  ``
-SynchronizationRule `$syncRule[$($customRuleCounter)] ``
-JoinConditions @($joinConditions) ``
-OutVariable syncRule`n"

    }

    $customRuleFileContent += "Add-ADSyncRule ``
-SynchronizationRule `$syncRule[$($customRuleCounter)]`n"

    $customRuleFileContent += "Get-ADSyncRule ``
-Identifier '$($customRuleIdentifier)'`n"

}

#///////////////////////////////////////

    if($connectorName -like "*AAD"){
        $connectorFolderName = "Cloud_Connector" + "_" + $connectorId
    }
    else{
        $connectorFolderName = $connectorName + "_" + "Connector" + "_" + $connectorId
    }

    New-Item -Path $targetPath -Name $connectorFolderName -ItemType Directory | Out-Null

    $fileName = $connectorName + ".ps1"

    $fileNamePath = New-Item -Path "$targetPath$connectorFolderName\" -Name $fileName -ItemType File

    Set-Content -Value $customRuleFileContent -Path $fileNamePath.FullName

#///////////////////////////////////////

}

}

#Test connection to target computer on PSRemoting WinRM port
try{
    Test-NetConnection -ComputerName $targetComputerName -Port 5985 -WarningAction Stop -ErrorAction Stop | Out-Null
}
catch{
    Write-Warning "Could not connect to $targetComputerName via PowerShell. Check the computer has port 5985 open."
    Write-Warning "The custom rule files have been created under folder $targetPath
    The files have to be manually copied over to the target computer $targetComputerName and the target computer connector Ids in the .ps1 files have to be changed manually as per:
    https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-upgrade-previous-version#move-a-custom-configuration-from-the-active-server-to-the-staging-server"
    break
}

#Create a session with the target computer
$targetComputerSession = New-PSSession -ComputerName $targetComputerName -Name $targetComputerName.Split(".")[0]

#Check if target folder exists and, if yes, remove it.
Invoke-Command -Session $targetComputerSession `
    -ScriptBlock `
    {
        if((Test-Path "$HOME\Desktop\ADConnectExportedCustomRules\")){
           Remove-Item -Path "$HOME\Desktop\ADConnectExportedCustomRules\" -Recurse -Force
        }
    }

#Copy all folders and files to the target computer
Copy-Item -Path $targetPath -ToSession $targetComputerSession -Destination $rootFolder -Recurse -Force -Verbose

#Part to change old content with new content, replacing the old connector Ids with the new ones
Invoke-Command -Session $targetComputerSession `
    -ScriptBlock `
    {
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
    }

#Remove the session with the target computer
Remove-PSSession -Session $targetComputerSession