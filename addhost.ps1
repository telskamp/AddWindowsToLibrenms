#define paramaters
$baseurl = "http://librenms.yourdomain.com/api/v0"
$Headers = @{'X-Auth-Token'='yourtokenhere'}
$deviceurl = $baseurl + "/devices"
$community = "yoursnmpcommunity"
$hostname = "your.hostname.com"
$librenmsip = "10.1.2.3"
#create body for adding hosts & convert to JSON
$body = @{"hostname"=$hostname;
"version"="v1";
"community"=$community;
} |convertTo-json

<#json format body example
$json = @'
{"hostname":"localhost.localdomain",
"version":"v1",
"community":"public"
}
'@
#>

#create session to host for installing/enabling snmp 
write-host "creating session to $hostname"
$session = New-PSSession -ComputerName $hostname



#install snmp and allow ping trough windows firewall on remote host
write-host "installing snmp on $hostname"
Invoke-Command -Session $session -ScriptBlock {
Get-WindowsFeature snmp* |Install-WindowsFeature
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities" /v "$using:community" /t REG_DWORD /d 4 /f | Out-Null 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" /v 2 /t REG_SZ /d "$using:librenmsip" /f | Out-Null 
Restart-service snmp** 
Import-Module NetSecurity 
New-NetFirewallRule -Name Allow_Ping -DisplayName “Allow Ping”  -Description “Ping ICMPv4” -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Any -Action Allow
}


#close pssession
Remove-PSSession $session

# add host to libremns
write-host "adding $hostname to librenms"
Invoke-RestMethod -Uri $deviceurl -Headers $headers -method post -body $body -ContentType "application/json" # |select -ExpandProperty devices |ogv


