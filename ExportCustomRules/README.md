This script is to export AD Connect custom rules from a source computer (Active ADConnect server) to a target computer (Staging Mode ADConnect server) or viceversa.
The script exports all custom rules from the source computer, including the ones disabled.
The script has been tested with ADConnect versions: 1.3.21.0, 1.4.38.0 and 1.5.30.0.
Since the script uses the Test-NetConnection cmdlet to test connectivity with the target computer for creating a remote session with it, it should be run with PowerShell version 4 and above or in Windows Server 2012 R2 and above.
PowerShell Remoting WinRM port 5985 has to be open on the target computer for the script to complete successfully.

The only value the script needs is the target computer name:
$targetComputerName

The script creates a folder named "ADConnectExportedCustomRules" under the Desktop folder on the source computer.
For each source computer connector that has at least 1 custom rule related to it, additional folders are created under the "ADConnectExportedCustomRules" folder with the name of the correspoding connector.
1 .ps1 file is created under each connector folder. The file contains all custom rules related to the connector: Inbound/Outbound, Enabled/Disabled.

After the folder and file creations are done, they are all copied over to the target computer.
After the copy operation is done (if the test connectivity with the target computer was successful), the process of replacing the source connector Ids with the target connector Ids in the .ps1 files occurs.

Once the .ps1 files are on the target computer, run the files with PowerShell to import the custom rules.

If the PowerShell Remoting WinRM port 5985 is not open, the AD Connect custom rules are still exported to the source computer but have to be manually copied over to the target computer and the script at https://github.com/mbendana/ADConnect/blob/ExportCustomRules/ExportCustomRules/Set-CustomRule.ps1 can be used to automatically change the connector Ids in the .ps1 files.

As a last option, the target computer connector Ids in the .ps1 files can also be changed manually as per:
https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-upgrade-previous-version#move-a-custom-configuration-from-the-active-server-to-the-staging-server