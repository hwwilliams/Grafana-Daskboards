#Get data from UPS through primary hyperv host node
$webClient = New-Object System.Net.WebClient
$parseMe = $webClient.DownloadString('http://localhost:3052/agent/ppbe.js/init_status.js')

#get timestamp of time pulled
$timeStamp = [System.Math]::Truncate((Get-Date -Date (Get-Date).ToUniversalTime() -UFormat %s))

#get rid of extra spaces and whatnot
$parseMe = $parseMe.Trim()

#get rid of var ppbeJsObj=
$parseMe = $parseMe.Substring(14)

#get rid of last ;
$parseMe = $parseMe.Substring(0, $parseMe.Length - 1)

#convert to Json
$myUPSJson = $parseMe | ConvertFrom-Json | ConvertTo-Json

Write-Host($myUPSJson)

#convert to powershell object
$myUPS = $myUPSJson | ConvertFrom-Json

#Utility Power Inputs
$InputState     = $myUPS.status.utility.state;
$InputVoltage   = "{0:N}" -f [float]$myUPS.status.utility.voltage;
$InputFrequency = "{0:N}" -f [float]$myUPS.status.utility.frequency 

#Output Power
$OutputState   = $myUPS.status.output.state;
$OutputVoltage = "{0:N}" -f [float]$myUPS.status.output.voltage;
$OutputLoad    = "{0:N}" -f [float]$myUPS.status.output.load;
$OutputWatt    = "{0:N}" -f [float]$myUPS.status.output.watt;

#Battery Info
$BatteryState     = $myUPS.status.battery.state.Replace(" ","\ ")
$BatteryCapacity  = "{0:N}" -f [float]$myUPS.status.battery.capacity
$BatteryMinsLeft  = "{0:N}" -f [float]((60 * $myUPS.status.battery.runtimeHour) + $myUPS.status.battery.runtimeMinute)

#Device ID just incase I get another one ...
$DeviceID = $myUPS.status.deviceId

#checking values
<#
Write-Host("`$DeviceID = " + $DeviceID)
Write-Host("`$InputState = " + $InputState)
Write-Host("`$InputVoltage = " + $InputVoltage)
Write-Host("`$InputFrequency = " + $InputFrequency)
Write-Host("`$OutputState = " + $OutputState)
Write-Host("`$OutputVoltage = " + $OutputVoltage)
Write-Host("`$OutputLoad = " + $OutputLoad)
Write-Host("`$OutputWatt = " + $OutputWatt)
Write-Host("`$BatteryState = " + $BatteryState)
Write-Host("`$BatteryCapacity = " + $BatteryCapacity)
Write-Host("`$BatteryMinsLeft = " + $BatteryMinsLeft)
#>

$postParams = @()
$postParams += "ups_info_frequency,host=$DeviceID,type=input value=$InputFrequency"
$postParams += "ups_info_state,host=$DeviceID,type=input value=`"$InputState`""
$postParams += "ups_info_state,host=$DeviceID,type=output value=`"$OutputState`""
$postParams += "ups_info_state,host=$DeviceID,type=battery value=`"$BatteryState`""
$postParams += "ups_info_voltage,host=$DeviceID,type=input value=$InputVoltage"
$postParams += "ups_info_voltage,host=$DeviceID,type=output value=$OutputVoltage"
$postParams += "ups_info_wattage,host=$DeviceID,type=output value=$OutputWatt"
$postParams += "ups_info_battery,host=$DeviceID,type=mins_left value=$BatteryMinsLeft"
$postParams += "ups_info_battery,host=$DeviceID,type=capacity value=$BatteryCapacity"
$postParams += "ups_info_load,host=$DeviceID,type=output value=$OutputLoad"

$postMe = ""
foreach ($item in $postParams)
{
    $postMe += $item + "`n"
}

#Write-Host($postMe)

$uri = 'http://192.168.1.243:8086/write?db=powerpanel'
Invoke-RestMethod -Uri $uri -Method POST -Body $postMe