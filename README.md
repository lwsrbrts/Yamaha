# Yamaha AV Receiver PowerShell

Something I cobbled together one afternoon.

I have a Yamaha RX-V775 AV receiver. It's a couple of years old now so isn't likely to see much integration with any home automation systems - so, knowing there's a web based interface to the receiver, I assumed (correctly) that there would be a way to interface with it by reverse-engineering the web based interface in to PowerShell.

The idea being that this allows me to provide the beginnings of an interface that I might be able to implement in some way to integrate home automation. Powershell unfortunately isn't the right choice for this (Python or Node.js would undoubtedly be better) but technically I can provide custom scripts in an Azure Automation account which are addressable from the interwebs and with which I can interface (maybe) an Alexa skill.

"Alexa, set the receiver input to HDMI2"
"Alexa, set the receiver volume to v8"

This may not amount to much but the code is here nonetheless.

```powershell
Import-Module -Name .\Yamaha.ps1 -Force # Import the module

$Endpoint = "192.168.1.6" # The IP of the receiver.

$R = [Yamaha]::new($Endpoint) # Instantiate a new object.

$R # See the object

$R.SetVolume(-900) # Set the volume to -90.0dB
$R.SetVolume('v8') # Set the volume to v8 (which is -45.0dB)

$R.SetPower($true) # Turn the power on.
$R.SetPower($false) # Turn the power off.

$R.SetMute($true) # Mute the main zone
$R.SetMute($false) # Unmute the main zone.

$R.Inputs # Get a list of valid inputs

$R.SetInput('HDMI3') # Set HDMI3 as the current input.

$R.SetSubTrim(-30) # Set the subwoofer trim level to -3.0dB - ranged as -60 to +60 (-6.0db to +6.0dB)
$R.SetBass(20) # Set the Bass level to 2.0dB - ranged as -60 to +60 (-6.0db to +6.0dB)
$R.SetTreble(15) # Set the Treble level to 1.5dB - ranged as -60 to +60 (-6.0db to +6.0dB)

$R.SetPureDirect($true) # Turn on Pure Direct mode
$R.SetPureDirect($false) # Turn off Pure Direct mode

$R.SetEnhancer($true) # Turn enhancer mode on
$R.SetEnhancer($false) # Turn enhancer mode off

$R.SetAdaptiveDRC($true) # Turn Adaptive DRC on
$R.SetAdaptiveDRC($false) # Turn Adaptive DRC off

$R.SetCinema3DDSP($true) # Turn Cinema 3D DSP on
$R.SetCinema3DDSP($false) # Turn Cinema 3D DSP off
```