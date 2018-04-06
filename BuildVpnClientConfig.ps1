<#	
	.NOTES
	===========================================================================
	 Created on:   	4/3/2018 1:05 AM
	 Created by:   	Marcin Wisniowski @mwisniowski
	 Organization: 	LISS Group
	 Filename:     	BuildVpnClientConfig.ps1
	===========================================================================
	.DESCRIPTION
		Tool that builds a batch file with encoded PowerShell command. 
		Resulting batch file can be run on client workstation to automatically
		configure Built-in VPN client on Windows 8.1/2012R2 and higher machines.

	.PARAMETER Name
		The name to use for VPN Connection
	
	.PARAMETER ServerAddress
		The DNS name or IP Address of the VPN server for this connection

	.PARAMETER PreSharedKey
		The PreSharedKey to be used for L2TP authentication

	.PARAMETER Path
		The destination folder for the distributable batch file, default $PSSCriptRoot\dist
#>
[CmdletBinding()]
param
(
	[parameter(Position = 0,
			   Mandatory = $true,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)]
	[string]$Name,
	[parameter(Position = 1,
			   Mandatory = $true,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)]
	[string]$ServerAddress,
	[parameter(Position = 2,
			   Mandatory = $true,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)]
	[string]$PreSharedKey,
	[Parameter(Position = 3,
			   ValueFromPipelineByPropertyName)]
	[string]$Path = (Join-Path -Path $PSScriptRoot -ChildPath 'dist')
)

begin { }

process
{
	$installScript = @"
try { Remove-VpnConnection -Name "$Name" -ErrorAction Stop -Force }
catch {}
finally
{
	Add-VpnConnection -Name "$Name" -ServerAddress "$ServerAddress" -TunnelType L2tp -L2tpPsk "$PreSharedKey" -AuthenticationMethod Pap -EncryptionLevel Optional -Force -WarningAction SilentlyContinue
}
"@
	
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($installScript)
	$encodedCommand = [System.Convert]::ToBase64String($bytes)
	
	$executionCommand = @"
@echo off
setlocal enabledelayedexpansion
cls
mode con:cols=80 lines=22
color 0F

:: Execute encoded PowerShell command
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.EXE -NoProfile -Enc {0}

Exit %ERRORLEVEL%
"@ -f $encodedCommand
	
	if (-not (Test-Path -LiteralPath $Path))
	{
		New-Item -Path $Path -Type Directory -Force | Out-Null
	}
	
	$filePath = (Join-Path -Path $PSScriptRoot `
						   -ChildPath "$Path\ConfigureVpnClient_$($Name.Replace(" ", "-")).cmd")
	
	$executionCommand | Out-File -FilePath $filePath -Encoding ascii -Force
}

end {}