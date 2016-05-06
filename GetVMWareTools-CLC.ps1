<#

PowerShell script to create a report of the VMWare tools version of every Virtual Machine in a given CenturyLink Cloud Account Alias
Note: This script will only work with Windows Machines
This script calls the CenturyLink Cloud V1 API to generate a list of servers that are in a given account alias.
It then queries each of these servers for their VMWare tools version.
You will need login credentials for each server being queried. You will be prompted if you want to use the same credentials for each server.
An output file with results will be opened automatically. It will also be stored locally at c:\users\public\clc
Author: Matt Schwabenbauer
Date: 5/6/2016

#>


Write-Verbose "This script will iterate through every Virtual Machine in a given CenturyLink Cloud account alias and create a report showing the VMWare tools version." -Verbose
Write-Verbose "You will need the administrator user name and password for each of the machines you are querying." -Verbose
Write-Verbose "This information can be found by navigating to the specific VM in the dashboard at control.ctl.io/manage and clicking 'show credentials'."
Write-Verbose "Information can only be gathered for machines with a Windows Operating System." -Verbose
Write-Verbose "At the end of the operation, the output file will be opened. It will also be stored locally at C:\Users\Public\CLC." -Verbose

Write-Verbose "Logging in to the CenturyLink Cloud V1 API." -Verbose
$APIKey = Read-Host "Please enter your CenturyLink Cloud V1 API Key"
$APIPass = Read-Host "Please enter your CenturyLink Cloud V1 API Password"
$body = @{APIKey = $APIKey; Password = $APIPass} | ConvertTo-Json
$restreply = Invoke-RestMethod -uri "https://api.ctl.io/REST/Auth/Logon/" -ContentType "Application/JSON" -Body $body -Method Post -SessionVariable session 
$global:session = $session 
Write-Host $restreply.Message

if ($restreply.StatusCode -eq 100)
{
   Write-Verbose "Error logging in to CLC API V1." -Verbose
   exit 1
}
Else
{
}

$VMWarevers = $null
$servers = @()
$allServerNames = @()
$account = Read-Host "Please enter the account alias you would like to query servers for"
$datacenterList = "DE1,GB1,GB3,SG1,WA1,CA1,UC1,UT1,NE1,IL1,CA3,CA2,VA1,NY1,AU1"
$datacenterList = $datacenterList.Split(",")

$genday = Get-Date -Uformat %a
$genmonth = Get-Date -Uformat %b
$genyear = Get-Date -Uformat %Y
$genhour = Get-Date -UFormat %H
$genmins = Get-Date -Uformat %M
$gensecs = Get-Date -Uformat %S

$gendate = "Generated-$genday-$genmonth-$genyear-$genhour-$genmins-$gensecs"

New-Item -ItemType Directory -Force -Path C:\Users\Public\CLC

$filename = "C:\Users\Public\CLC\$account-CLCVMToolsVers-$gendate.csv"

foreach($datacenter in $datacenterList)
{
    $JSON = @{AccountAlias = $account; Location = $datacenter } | ConvertTo-Json 
    $groups = Invoke-RestMethod -Uri "https://api.ctl.io/REST/Group/GetGroups/" -ContentType "Application/JSON" -WebSession $session -Method Post -Body $JSON
    foreach($group in $groups)
    {
        #Get Servers in Group
        $JSON = @{AccountAlias = $account; HardwareGroupUUID = $group.HardwareGroups.ID; Location = $datacenter } | ConvertTo-Json 
        $Servers = Invoke-RestMethod -Uri "https://api.ctl.io/REST/Server/GetAllServers/" -ContentType "Application/JSON" -WebSession $session -Method Post -Body $JSON
        #Add Server to Array
        $allServerNames += $Servers.Servers.Name
    }
}

$allServerNames = $allServerNames | select -unique

function getVers
{
    $login = $args[0]
    Foreach ($server in $allServerNames)
    {
        Write-Verbose "Please enter the administrator password for $server." -Verbose
        # Get VMWare tools versions
        $VMWarevers = Invoke-Command -ComputerName UC1MSCHPWSH01 -ScriptBlock {  C:\"Program Files"\VMware\"VMware Tools"\VMwareToolboxCmd.exe -v } -credential $login
        $newRow = new-object system.object
        $newRow | Add-Member -type NoteProperty -name "ServerName" -value $server
        $newRow | Add-Member -type NoteProperty -name "VMWare Tools Version" -value $VMWarevers
        $newRow | export-csv $filename -append -force -NoTypeInformation
    }
}


Write-Verbose "If you have the same administrator credentials for all of your servers, you can instruct this script to use the same username and password for each machine that will be queried." -Verbose
Write-Verbose "If there are different administrator credentials for each of your servers, you will need to type each set in directly."
$sameCreds = Read-Host "Would you like to use the same set of credentials for each of your servers? (Y/N)"

if ($sameCreds -eq "Y")
{
    $global:adminCreds = Get-Credential -message "Please enter the Administrator credentials for all of your servers" -ErrorAction Stop 
    $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $global:adminCreds
    getVers($Cred)
}
else
{
    getVers("administrator")
}


$file = & $filename

Write-Verbose "Operation complete. The output file is located at $filename." -Verbose