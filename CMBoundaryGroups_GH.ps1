<#
.Synopsis
   Script to create Boundary Groups for every AD site based boundary and set default Site System servers in these Boundary Groups

.DESCRIPTION
   Script to create boundary Groups for all AD Site based boundaries, so a list of Site System servers is assigned if a client roams in Active Directory
   sigurd werner; 2018

.PARAMETER CMSiteCode
Configuration Manager site code [mandatory]
.PARAMETER CMProviderMachineName
Machine name of Configuration Manager SMSProvider to be used by the script [mandatory]
.PARAMETER CMSiteSystemServers
Comma separated list of Site System Servers for autocreated Boundary Groups [mandatory]

.EXAMPLE
CMCreateBoundaryGroups.ps1 -CMSiteCode PRD -CMProviderMachineName gdc02791.swatchgroup.net -CMSiteSystemServers gdc02793.swatchgroup.net,gdc02794.swatchgroup.net

.Notes
Get-CMBoundary
For (all boundaries)
{
    if (GroupCount = 0 and BoundaryType = 1) {
        if (New-CMBoundaryGroup) {
            Add-CMBoundaryToGroup
        }
    }
}

A log-file CreateBoundaryGroups_%DATE%.log is created in LogFolder (default %TEMP%)
#>

Param(
 [Parameter (Mandatory=$true)][string]$CMSiteCode,
 [Parameter (Mandatory=$true)][string]$CMProviderMachineName,
 [Parameter (Mandatory=$true)][string]$CMSiteSystemServers
)

#ErrorActionPreference

# Prepare some paths and logfile per application
$CMBoundaryGroupdescription = 'Autocreated Boundary Group'

$CMSiteSystemServerLists = $CMSiteSystemServers.split(",");

# Prepare log-file
$LogFolder = $env:TEMP
$Logfile = "CreateBoundaryGroups_" + (Get-Date -Format FileDateTimeUniversal)
$LogPath = "$LogFolder\$Logfile.log"
if (!(Test-Path -LiteralPath $LogPath)) {
    New-Item -Path $LogPath  -ItemType file -Force
}

# Log parameters and values
Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) -->Start Create Boundary Groups"
Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) -->Start initialization step"
# Customizations
$initParams = @{}
Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) Initialzed"
#$initParams.Add("Verbose", $true)
#$initParams.Add("ErrorAction", "Stop")

# Import the ConfigurationManager.psd1 module 
if(!(Get-Module ConfigurationManager)) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}
Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) PoSh module loaded"

# Connect to the site's drive if it is not already present
if(!(Get-PSDrive -Name $CMSiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $CMSiteCode -PSProvider CMSite -Root $CMProviderMachineName @initParams
}
Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) Connected to CM site"

# Set the current location to be the site code.
Set-Location "$($CMSiteCode):\" @initParams
Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) Set location = $CMSiteCode"
Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) <--Finished initialization step"


# get all boundaries
$CMBoundaries = Get-CMBoundary -BoundaryName '*' -ForceWildcardHandling

foreach ($CMBoundary in $CMBoundaries) {
    # if boundary is type = ADSite and has no Boundary Group membership
    if (($CMBoundary.BoundaryType -eq 1) -and ($CMBoundary.GroupCount -eq 0)) {
        $CMBName = $CMBoundary.DisplayName
        $CMBGName = $CMBoundary.Value
        Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) Found ADSite based boundary w/o Boundary Group = $CMBName"
        # Create new Boundary Group named as the boundary
        if (New-CMBoundaryGroup -Name $CMBGName -Description $CMBoundaryGroupdescription -AddSiteSystemServerName $CMSiteSystemServerLists[0]) {
            Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) Created Boundary Group = $CMBGName w/ SiteSystem = $CMSiteSystemServerLists[0]"
            # Add additional Site System servers
            for ($i = 1; $i -lt $CMSiteSystemServerLists.Count; $i++) {
                Set-CMBoundaryGroup -Name $CMBGName -AddSiteSystemServerName $CMSiteSystemServerLists[$i]
                Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) Changed Boundary Group = $CMBGName added SiteSystem = $CMSiteSystemServerLists[$i]"
            }
            # Add Boundary to Boundary Group
            if (Add-CMBoundaryToGroup -BoundaryName $CMBName -BoundaryGroupName $CMBGName) {
                Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format o) Changed Boundary Group = $CMBGName added Boundary = $CMBName"
            }
        }
        
    }
}

