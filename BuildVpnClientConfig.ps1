<#	
	.NOTES
	===========================================================================
	 Created on:	4/3/2018 1:05 AM
	 Created by:	Marcin Wisniowski @mwisniowski
	 Organization:	LISS Group
	 Filename:	BuildVpnClientConfig.ps1
	===========================================================================
	.SYNOPSIS
		Build Windows Built-in VPN configuration batch file.		

	.DESCRIPTION
		Tool that builds a batch file to execute encoded PowerShell command. 
		Resulting batch file can be run on client workstation to automatically
		configure Built-in VPN client on Windows 8.1/2012R2 and higher machines.

	.PARAMETER Name
        Specifies the name of this VPN connection profile.
	
	.PARAMETER ServerAddress
        Specifies the address of the remote VPN server to which the client connects.
        You can specify the address as a URL, an IPv4 address, or an IPv6 address.

	.PARAMETER PreSharedKey
        Specifies the value of the PSK to be used for L2TP authentication.

	.PARAMETER TunnelType
        Specifies the type of tunnel used for the VPN connection.
        The acceptable values for this parameter are:

        -- PPTP
        -- L2TP
        -- SSTP
        -- IKEv2
        -- Automatic

	.PARAMETER AuthenticationMethod
        Specifies the authentication method to use for the VPN connection.
        The acceptable values for this parameter are:
    
        -- PAP
        -- CHAP
        -- MSCHAPv2
        -- EAP

	.PARAMETER EncryptionLevel
        Specifies the encryption level for the VPN connection.
        The acceptable values for this parameter are:

        -- NoEncryption
        -- Optional
        -- Required
        -- Maximum

	.PARAMETER AllUserConnection
        Indicates that the cmldet adds the VPN connection to the global phone book entries.

	.PARAMETER SplitTunneling
        Indicates that the cmdlet enables split tunneling for this VPN connection profile.
        When you enable split tunneling, traffic to destinations outside the intranet
        does not flow through the VPN tunnel. If you do not specify this parameter split
        tunneling is disabled.

	.PARAMETER DnsSuffix
        Specifies the DNS suffix of the VPN connection.

	.PARAMETER RememberCredential
        Indicates that the credentials supplied at the time of first successful
        connection are stored in the cache.

	.PARAMETER UseWinlogonCredential
        Indicates that MSCHAPv2 or EAP MSCHAPv2 is used as the authentication method,
        and that Windows logon credentials are used automatically when connecting
        with this VPN connection profile.

	.PARAMETER Path
		Specifies the destination folder for the distributable batch file, default: '$PSSCriptRoot\dist'
#>
[CmdletBinding()]
param
(
  [parameter(Position = 1,
             Mandatory = $true,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [string]$Name,
  
  [parameter(Position = 2,
             Mandatory = $true,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [string]$ServerAddress,
  
  [parameter(Position = 3,
             Mandatory = $true,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [string]$PreSharedKey,

  [parameter(Position = 4,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [string]$TunnelType = "L2tp",
  
  [parameter(Position = 5,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [string]$AuthenticationMethod = "Pap",
  
  [parameter(Position = 6,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [string]$EncryptionLevel = "Optional",
  
  [Parameter(Position = 7,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [switch]$AllUserConnection,
  
  [Parameter(Position = 8,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [string]$SplitTunneling,

  [Parameter(Position = 9,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [string]$DnsSuffix = $null,

  [parameter(Position = 10,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [switch]$RememberCredential,

  [parameter(Position = 11,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true)]
  [switch]$UseWinlogonCredential,

  [Parameter(Position = 12,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName)]
  [string]$Path = "$PSScriptRoot\dist"
)

begin { }

process
{
  $installScript = @"
#Requires -Version 4 
try { Remove-VpnConnection -Name "$Name" -ErrorAction Stop -Force }
catch { }
finally
{
	Add-VpnConnection -Name "$Name" ``
		-ServerAddress "$ServerAddress" ``
		-TunnelType "$TunnelType" ``
		-L2tpPsk "$PreSharedKey" ``
		-AuthenticationMethod "$AuthenticationMethod" ``
		-EncryptionLevel "$EncryptionLevel" ``
		$(if ($AllUserConnection) { "-AllUserConnection ``" })
		$(if ($SplitTunneling) { "-SplitTunneling ``" })
		$(if ($DnsSuffix) { "-DnsSuffix $DnsSuffix ``" })
		$(if ($RememberCredential) { "-RememberCredential ``" })
		$(if ($UseWinlogonCredential) { "-UseWinlogonCredential ``" })
		-Force ``
		-WarningAction SilentlyContinue
}
"@ -creplace '(?m)^\s*\r?\n', ''
  
  $bytes = [System.Text.Encoding]::Unicode.GetBytes($installScript)
  $encodedCommand = [System.Convert]::ToBase64String($bytes)
  
  $executionCommand = @"
@echo off
setlocal enabledelayedexpansion
cls
mode con:cols=80 lines=22
color 0F

:: Execute encoded PowerShell command
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.EXE -NoLogo -NoProfile -Enc $encodedCommand

Exit %ERRORLEVEL%
"@
  
  if (-not (Test-Path -Path $Path))
  {
    New-Item -Path $Path -Type Directory -Force | Out-Null
  }
  $filePathArgs = @{
      Path = $Path
      ChildPath = "ConfigureVpnClient_$($Name.Replace(" ", "-")).cmd"
  }
  $filePath = Join-Path @filePathArgs
  $executionCommand | Out-File -FilePath $filePath -Encoding ascii -Force
}

end { }
