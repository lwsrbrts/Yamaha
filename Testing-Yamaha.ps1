Import-Module -Name .\Yamaha.ps1 -Force

$Endpoint = "192.168.1.6"

$Receiver = [Yamaha]::new($Endpoint)

$Receiver

$Receiver.SetVolume(-900)
$Receiver.SetVolume('v8')

$Receiver.SetPower($true)
$Receiver.SetPower($false)

$Receiver.SetMute($true)
$Receiver.SetMute($false)

$Receiver.SetVolume

$Receiver.GetInputs()

$Receiver.SetInput('HDMI3')