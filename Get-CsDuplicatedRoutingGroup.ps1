
<#PSScriptInfo

.VERSION 1.1

.GUID 2903dd9a-251f-4020-9751-0e486cd30edb

.AUTHOR David Paulino

.COMPANYNAME UC Lobby

.COPYRIGHT

.TAGS Lync LyncServer SkypeForBusiness SfBServer WindowsFabric

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
  Version 1.0: 2019/08/12 - Initial release.
  Version 1.1: 2023/10/07 - Updated to publish in PowerShell Gallery.


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Returns the duplicated routing group information from Lync/Skype for Business Front Ends. 

#> 

[CmdletBinding()]
param(
[parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)]
    [string] $PoolFqdn
)

if($PoolFqdn){

$FrontEnds = Get-CsComputer -Pool $PoolFqdn

$RGAQuery = "SELECT f.Fqdn, r.RoutingGroupName FROM dbo.RoutingGroupAssignment r, dbo.FrontEnd f WHERE f.FrontEndId = r.FrontEndId"
$RGDupOutput = New-Object System.Collections.ArrayList

foreach($FE in $FrontEnds){
    
    try{
        $ServerInstance = $FE.fqdn + "\RTCLOCAL"
        Write-Warning "Trying to connect to : $ServerInstance"
        $DupRGs = Invoke-Sqlcmd -query $RGAQuery -ServerInstance $ServerInstance -Database RTC -ErrorAction SilentlyContinue | Group-Object RoutingGroupName | Where-Object {$_.Count -gt 1} | Select Name
        foreach($DupRG in $DupRGs){

        if($DupRG.Name -ne '00000000-0000-0000-0000-000000000000'){

            $UserCount = (Get-CsUser | ?{$_.UserRoutingGroupId -eq $DupRG.Name}).Count

            $RGDupInfo = New-Object PSObject -Property @{            
                            FrontEnd      = $FE.fqdn
                            RoutingGroup  = $DupRG.Name
                            UserCount = $UserCount
                          }
                [void]$RGDupOutput.Add($RGDupInfo)
        }
     }
    } catch {
            Write-Warning "Failed to connect to: $ServerInstance"
    }
}
    $RGDupOutput | Select FrontEnd,RoutingGroup,UserCount
}