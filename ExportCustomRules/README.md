This script is to export AD Connect custom rules from a source server (Active) to a target server (Staging Mode) or viceversa.
The script exports all custom rules from the source server, including the ones disabled.
The script has been tested with ADConnect versions: 1.3.21.0, 1.4.38.0 and 1.5.30.0.

The only value to add to the script is the target computer name at line 4:

$targetComputerName = ""

Since the script uses the Test-NetConnection cmdlet to test connectivity with the target server, it should be run with PowerShell version 4 and above or in Windows Server 2012 R2.

PowerShell Remoting WinRM port 5985 has to be open on the target server for the script to complete successfully.

If the port is not open, the AD Connect custom rules are still exported to the source server but have to be manually copied to the target server and the target server connector Ids in the .ps1 files have to be changed manually as per:
https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-upgrade-previous-version#move-a-custom-configuration-from-the-active-server-to-the-staging-server


