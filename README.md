# Yamaha AV Receiver PowerShell

Something I cobbled together one afternoon.

$Receiver = [Yamaha]::New('192.168.1.149')

$Receiver.SetVolume(-400)

$Receiver.SetMute($true)

$Receiver.SetPower($true)

