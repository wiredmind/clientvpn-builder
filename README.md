
# 🔧 ClientVPNBuilder

## Description 
PowerShell tool that builds a batch file to execute encoded PowerShell command.Resulting batch file can be run on client workstation to automatically configure—Cisco Meraki Client VPN compatible—Built-in VPN client on machines running Windows 8.1/2012R2 and better.

This is PowerShell, run from PowerShell 😉

Given parameters `Name`, `ServerAddress`, `PreSharedKey`, and optionally `Path` builds a file `ConfigureVpnClient_%NAME%.cmd`.
If you don’t specify `Path` the resulting batch file will be saved in subdirectory `dist` of the script directory.

In addition to specifying parameters on the command line, this tool takes input from the pipeline, which allows it to read required parameters from a text file, CSV file, even SQL database. It can be completely automated.

## Examples
Import entries from CSV file and pipe to BuildVpnClientConfig.ps1. Check out `clientlist.csv` for reference.
```
Import-Csv .\examples\clientlist.csv | .\BuildVpnClientConfig.ps1
```

Specify parameters on the command line
```
.\BuildVpnClientConfig.ps1 -Name 'The Roman Empire' `
  -ServerAddress 'vpn.rome.com' -PreSharedKey 'veritas-NUMQUAM-perit-&%#DC' -Path 'ClientVPN'
