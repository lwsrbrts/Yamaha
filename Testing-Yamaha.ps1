Import-Module -Name .\Yamaha.ps1 -Force

$Endpoint = "192.168.1.6"

$Receiver = [Yamaha]::new($Endpoint)

$Receiver

$Receiver.SetVolume(-555)
$Receiver.SetVolume(-900)

$Receiver.SetPower($true)
$Receiver.SetPower($false)

$Receiver.SetMute($true)
$Receiver.SetMute($false)

$Receiver.SetVolume

$State = $Receiver.GetMainZoneStatus()

$State.YAMAHA_AV