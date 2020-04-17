function Install-WinLogBeats {
<#
.SYNOPSIS 
Uses existing PS-Sessions to install WinLogBeats
.DESCRIPTION
This command takes a source filepath and uses C$ admin share to add it to all open PS-Sessions. It will make the filepath if it is not on the remote computer.
.PARAMETER DestinationFilePath
The C:\File Path you want your file to go
.PARAMETER SourcePath
The Source Filepath your file is on your local computer
#>
    [CmdletBinding()]
    Param(
    #Set the Sysmon File Path
        [Parameter(Mandatory=$True,
        ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNull()]
        [String]$PathToWinLogBeatEXE,

    #Full Path to Config File
        [Parameter(Mandatory=$True,
        ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNull()]
        [String]$PathtoWinLogBeatYML
    ) 

$PSSession = Get-PSSession
$PSSession | ForEach-Object { 
    $currentsession = $_
    $ComputerName = ($currentsession).ComputerName
        if (!(Invoke-Command -Session $currentsession -ScriptBlock {Test-Path 'C:\Program Files\winlogbeats'})) {
        Invoke-Command -Session $currentsession -ScriptBlock { New-Item -ItemType Directory -Path 'C:\Program Files\' -Name 'winlogbeats' }
        } #end if

    Copy-Item -Path $PathToWinLogBeatEXE -Destination 'C:\Program Files\winlogbeats' -Force -ToSession $currentsession
    Copy-Item -Path $PathtoWinLogBeatYML -Destination 'C:\Program Files\winlogbeats' -Force -ToSession $currentsession

Invoke-Command -Session $currentsession -ScriptBlock {

# Create the new service.
New-Service -name winlogbeat `
  -displayName Winlogbeat `
  -binaryPathName "`"C:\Program Files\winlogbeats\winlogbeat.exe`" -c `"C:\Program Files\winlogbeats\winlogbeat.yml`" -path.home `"C:\Program Files\winlogbeats`" -path.data `"C:\ProgramData\winlogbeat`" -path.logs `"C:\ProgramData\winlogbeat\logs`""
   Start-Sleep -Seconds 5

# Attempt to set the service to delayed start using sc config.
Try {
  Start-Process -FilePath sc.exe -ArgumentList 'config winlogbeat start=delayed-auto'
}
Catch { Write-Host "An error occured setting the service to delayed start." -ForegroundColor Red }

}
 Start-Sleep -Seconds 5

Get-Service -DisplayName winlogbeat | Start-Service
} # End Foreach
} #End Function