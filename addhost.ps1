#define paramaters
$baseurl = "http://librenms.example.com/api/v0"
$Headers = @{'X-Auth-Token'='yourtokenhere'}
$deviceurl = $baseurl + "/devices"
$community = "public"
$hostname = "yourhost"
$librenmsip = "10.0.0.1"
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
$session = New-PSSession -ComputerName $hostname

#install snmp on remote host
Invoke-Command -Session $session -ScriptBlock {
Get-WindowsFeature snmp* |Install-WindowsFeature
}

#configure snmp community
Invoke-Command -Session $session -ScriptBlock {
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities" /v $community /t REG_DWORD /d 4 /f | Out-Null
}

#add snmp manager (librenms server ip) to allowed snmp monitoring machines
Invoke-Command -Session $session -ScriptBlock {
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" /v 2 /t REG_SZ /d $librenmsip /f | Out-Null
}

#restart snmp service to apply settings
Invoke-Command -Session $session -ScriptBlock {
Restart-service snmp**
}
#close pssession
Remove-PSSession $session

# add host to libremns
Invoke-RestMethod -Uri $deviceurl -Headers $headers -method post -body $body -ContentType "application/json" # |select -ExpandProperty devices |ogv


