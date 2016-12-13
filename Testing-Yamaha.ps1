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

$R.SetDialogueLevel(3) # Set dialogue level
$R.SetDialogueLift(5) # Set dialogue lift level

$R.SetPureDirect($true) # Turn on Pure Direct mode
$R.SetPureDirect($false) # Turn off Pure Direct mode

$R.SetEnhancer($true) # Turn enhancer mode on
$R.SetEnhancer($false) # Turn enhancer mode off

$R.SetAdaptiveDRC($true) # Turn Adaptive DRC on
$R.SetAdaptiveDRC($false) # Turn Adaptive DRC off

$R.SetCinema3DDSP($true) # Turn Cinema 3D DSP on
$R.SetCinema3DDSP($false) # Turn Cinema 3D DSP off