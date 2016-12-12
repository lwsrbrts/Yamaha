Enum Volume {
    v1 = -800
    v2 = -750
    v3 = -700
    v4 = -650
    v5 = -600
    v6 = -550
    v7 = -500
    v8 = -450
    v9 = -400
    v10 = -350
    v11 = -300
    v12 = -250
    v13 = -200
}

Class ErrorHandler {
    # Base class defining a method for error handling which we can extend
    # Return errors and terminates execution

    hidden [void] ReturnError([string] $e) {
        Write-Error $e -ErrorAction Stop
    }

    hidden [void] ReturnWarning([string] $e) {
        Write-Warning $e
    }
}

Class Yamaha : ErrorHandler {

    ##############
    # PROPERTIES #
    ##############

    [ipaddress] $IPAddress
    [bool] $PowerOn
    [bool] $MuteOn
    [string] $CurrentInput
    [ValidateRange(-800,-200)][Volume] $VolumeLevel
    [ValidateRange(-60,60)][int] $SubTrimLevel
    [ValidateRange(-60,60)][int] $BassLevel
    [ValidateRange(-60,60)][int] $TrebleLevel
    [ValidateRange(0,3)][int] $DialogueLevel
    [ValidateRange(0,5)][int] $DialogueLift
    [bool] $PureDirectOn
    [bool] $EnhancerOn
    [bool] $Cinema3DDSPMode
    [bool] $AdaptiveDRC
    [System.Xml.XmlDocument] $Status
    [psobject] $Inputs

    ###############
    # CONSTRUCTOR #
    ###############

    Yamaha ([ipaddress] $IPAddress) {
        $this.IPAddress =  $IPAddress
        $this.SetState()
    }

    ###########
    # METHODS #
    ###########

    hidden [bool] ConvertState([string] $State) {
        switch ($State)
        {
            'Off' { Return $false}
            'On'  {Return $true}
            'Auto' {Return $true}
        }
        Return $false
    }

    # Get the current state of the receiver.
    hidden [void] SetState() {
        $this.Status = $this.GetMainZoneStatus()
        $this.PowerOn = $this.ConvertState($this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Power_Control.Power)
        $this.MuteOn = $this.ConvertState($this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Volume.Mute)
        $this.VolumeLevel = $this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Volume.Lvl.Val
        $this.CurrentInput = $this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Input.Input_Sel
        $this.SubTrimLevel = $this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Volume.Subwoofer_Trim.Val
        $this.BassLevel = $this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Sound_Video.Tone.Bass.Val
        $this.TrebleLevel = $this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Sound_Video.Tone.Treble.Val
        $this.PureDirectOn = $this.ConvertState($this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Sound_Video.Pure_Direct.Mode)
        $this.DialogueLevel = $this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Sound_Video.Dialogue_Adjust.Dialogue_Lvl
        $this.DialogueLift = $this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Sound_Video.Dialogue_Adjust.Dialogue_Lift
        $this.EnhancerOn = $this.ConvertState($this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Surround.Program_Sel.Current.Enhancer)
        $this.Cinema3DDSPMode = $this.ConvertState($this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Surround._3D_Cinema_DSP)
        $this.AdaptiveDRC = $this.ConvertState($this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Sound_Video.Adaptive_DRC)
        $this.GetInputs()
    }

    hidden [System.Xml.XmlDocument] GetNetworkStandbyStatus() {
        $Body = '<YAMAHA_AV cmd="GET"><System><Misc><Network><Network_Standby>GetParam</Network_Standby></Network></Misc></System></YAMAHA_AV>'
        $State = $null
        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
            Return $State
        }
        Catch {
            $this.ReturnError('GetNetworkStandbyStatus(): An error occurred while getting the state of the receiver.'+"`n"+$_)
            Return $null
        }
    }

    hidden [System.Xml.XmlDocument] GetMainZoneStatus() {
        $Body = '<YAMAHA_AV cmd="GET"><Main_Zone><Basic_Status>GetParam</Basic_Status></Main_Zone></YAMAHA_AV>'
        $State = $null
        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
            Return $State
        }
        Catch {
            $this.ReturnError('GetMainZoneStatus(): An error occurred while getting the state of the receiver.'+"`n"+$_)
            Return $null
        }
    }

    # Set the power state of the receiver.
    [void] SetPower([bool] $State) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()

        $Body = $null

        Switch ($State) {
            $true {
                If ($this.PowerOn -eq $true) { $this.ReturnWarning("The receiver is already on."); Return }
                Else { $Body = '<YAMAHA_AV cmd="PUT"><Main_Zone><Power_Control><Power>On</Power></Power_Control></Main_Zone></YAMAHA_AV>' }
                Break
            }
            $false {
                If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver is already off."); Return }
                Else { $Body = '<YAMAHA_AV cmd="PUT"><Main_Zone><Power_Control><Power>Standby</Power></Power_Control></Main_Zone></YAMAHA_AV>' }
                Break
            }
        }

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetPower([bool] $State): An error occurred while setting the power of the receiver.'+"`n"+$_)
        }
        $this.SetState()
    }

    # Mute/unmute the volume of the receiver.
    [void] SetMute([bool] $State) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()
        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }

        $Body = $null

        Switch ($State) {
            $true {
                If ($this.MuteOn -eq $true) { $this.ReturnWarning("The receiver is already muted."); Return }
                Else { $Body = '<YAMAHA_AV cmd="PUT"><Main_Zone><Volume><Mute>On</Mute></Volume></Main_Zone></YAMAHA_AV>' }
                Break
            }
            $false {
                If ($this.MuteOn -eq $false) { $this.ReturnWarning("The receiver is not currently muted."); Return }
                Else { $Body = '<YAMAHA_AV cmd="PUT"><Main_Zone><Volume><Mute>Off</Mute></Volume></Main_Zone></YAMAHA_AV>' }
                Break
            }
        }

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetMute([bool] $State): An error occurred while setting the mute status of the receiver.'+"`n"+$_)
        }
        $this.SetState()
    }

    # Set the volume on the receiver.
    [void] SetVolume([Volume] $VolumeLevel) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()

        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }
        If ($VolumeLevel % 5 -ne 0) { $this.ReturnWarning("VolumeLevel must be divisible by 5."); Return }
        $this.VolumeLevel = $VolumeLevel.value__

        $Body = "'<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Volume><Lvl><Val>$($VolumeLevel.value__)</Val><Exp>1</Exp><Unit>dB</Unit></Lvl></Volume></Main_Zone></YAMAHA_AV>"
        $State = $null

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetVolume([int] $VolumeLevel): An error occurred while setting the volume.'+"`n"+$_)
        }
        $this.SetState()
    }

    hidden [void] GetInputs() {
        # Refresh the state of the receiver, who knows what's changed.
        $Body = '<YAMAHA_AV cmd="GET"><System><Config>GetParam</Config></System></YAMAHA_AV>'
        $State = $null

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('GetInputs(): An error occurred while getting inputs.'+"`n"+$_)
        }

        $AVInputs = @{}
        Foreach ($AVInput in $State.YAMAHA_AV.System.Config.Name.Input.ChildNodes) {
            $AVInputs.Add($AVInput.Name.Replace('_',''), $AVInput.InnerText) # Clean up the input names, they don't have underscores!
        }

        $this.Inputs = $AVInputs
    }

    [void] SetInput([string] $InputName) {
        # Refresh the state of the receiver, who knows what's changed.

        If ($InputName -notin $this.Inputs.Keys) { $this.ReturnWarning("The input name specified (`"$InputName`") is not a valid input on the receiver. Check the .Inputs property for a list."); Return }

        $Body = "<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Input><Input_Sel>$InputName</Input_Sel></Input></Main_Zone></YAMAHA_AV>"

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetInput([string] $InputName): An error occurred while setting the input.'+"`n"+$_)
        }
        $this.SetState()
    }

    [void] SetSubTrim([int] $SubTrimLevel) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()

        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }
        If ($SubTrimLevel % 5 -ne 0) { $this.ReturnWarning("SubTrimLevel must be divisible by 5."); Return }
        $this.SubTrimLevel = $SubTrimLevel

        $Body = "'<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Volume><Subwoofer_Trim><Val>$($this.SubTrimLevel)</Val><Exp>1</Exp><Unit>dB</Unit></Subwoofer_Trim></Volume></Main_Zone></YAMAHA_AV>"

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetSubTrim([int] $SubTrimLevel): An error occurred while setting the subwoofer trim level.'+"`n"+$_)
        }
        $this.SetState()
    }

    [void] SetBass([int] $BassLevel) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()

        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }
        If ($BassLevel % 5 -ne 0) { $this.ReturnWarning("BassLevel must be divisible by 5."); Return }
        $this.BassLevel = $BassLevel

        $Body = "'<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Sound_Video><Tone><Bass><Val>$($this.BassLevel)</Val><Exp>1</Exp><Unit>dB</Unit></Bass></Tone></Sound_Video></Main_Zone></YAMAHA_AV>"

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetBass([int] $BassLevel): An error occurred while setting the bass level.'+"`n"+$_)
        }
        $this.SetState()
    }

    [void] SetTreble([int] $TrebleLevel) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()

        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }
        If ($TrebleLevel % 5 -ne 0) { $this.ReturnWarning("TrebleLevel must be divisible by 5."); Return }
        $this.TrebleLevel = $TrebleLevel

        $Body = "'<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Sound_Video><Tone><Treble><Val>$($this.TrebleLevel)</Val><Exp>1</Exp><Unit>dB</Unit></Treble></Tone></Sound_Video></Main_Zone></YAMAHA_AV>"

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetTreble([int] $TrebleLevel): An error occurred while setting the treble level.'+"`n"+$_)
        }
        $this.SetState()
    }

    # Set Pure Direct on or off ($true or $false)
    [void] SetPureDirect([bool] $State) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()
        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }

        $Body = $null

        Switch ($State) {
            $true {
                If ($this.PureDirectOn -eq $true) { $this.ReturnWarning("Pure Direct mode is already on."); Return }
                Else { $Body = "'<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Sound_Video><Pure_Direct><Mode>On</Mode></Pure_Direct></Sound_Video></Main_Zone></YAMAHA_AV>" }
                Break
            }
            $false {
                If ($this.PureDirectOn -eq $false) { $this.ReturnWarning("Pure Direct mode is already off."); Return }
                Else { $Body = "'<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Sound_Video><Pure_Direct><Mode>Off</Mode></Pure_Direct></Sound_Video></Main_Zone></YAMAHA_AV>" }
                Break
            }
        }

        Try {
            $Result = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetPureDirect([bool] $State): An error occurred while setting the Pure Direct status of the receiver.'+"`n"+$_)
        }
        $this.SetState()
    }

    [void] SetDialogueLevel([int] $DialogueLevel) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()

        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }
        $this.DialogueLevel = $DialogueLevel

        $Body = "<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Sound_Video><Dialogue_Adjust><Dialogue_Lvl>$($this.DialogueLevel)</Dialogue_Lvl></Dialogue_Adjust></Sound_Video></Main_Zone></YAMAHA_AV>"

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetDialogueLevel([int] $DialogueLevel): An error occurred while setting the dialogue level.'+"`n"+$_)
        }
        $this.SetState()
    }

    [void] SetDialogueLift([int] $DialogueLift) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()

        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }
        $this.DialogueLift = $DialogueLift

        $Body = "<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Sound_Video><Dialogue_Adjust><Dialogue_Lift>$($this.DialogueLift)</Dialogue_Lift></Dialogue_Adjust></Sound_Video></Main_Zone></YAMAHA_AV>"

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetDialogueLift([int] $DialogueLift: An error occurred while setting the dialogue level.'+"`n"+$_)
        }
        $this.SetState()
    }

    # Set Enhancer on or off ($true or $false)
    [void] SetEnhancer([bool] $State) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()
        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }

        $Body = $null

        Switch ($State) {
            $true {
                If ($this.EnhancerOn -eq $true) { $this.ReturnWarning("Enhancer is already on."); Return }
                Else { $Body = "<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Surround><Program_Sel><Current><Enhancer>On</Enhancer></Current></Program_Sel></Surround></Main_Zone></YAMAHA_AV>" }
                Break
            }
            $false {
                If ($this.EnhancerOn -eq $false) { $this.ReturnWarning("Enhancer is already off."); Return }
                Else { $Body = "<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Surround><Program_Sel><Current><Enhancer>Off</Enhancer></Current></Program_Sel></Surround></Main_Zone></YAMAHA_AV>" }
                Break
            }
        }

        Try {
            $Result = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetEnhancer([bool] $State): An error occurred while setting the enhancer state on the receiver.'+"`n"+$_)
        }
        $this.SetState()
    }

    # Set Cinema 3D DSP mode on or off ($true or $false)
    [void] SetCinema3DDSP([bool] $State) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()
        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }

        $Body = $null

        Switch ($State) {
            $true {
                If ($this.Cinema3DDSPMode -eq $true) { $this.ReturnWarning("Cinema 3D DSP mode is already on."); Return }
                Else { $Body = "<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Surround><_3D_Cinema_DSP>Auto</_3D_Cinema_DSP></Surround></Main_Zone></YAMAHA_AV>" }
                Break
            }
            $false {
                If ($this.Cinema3DDSPMode -eq $false) { $this.ReturnWarning("Cinema 3D DSP mode is already off."); Return }
                Else { $Body = "<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Surround><_3D_Cinema_DSP>Off</_3D_Cinema_DSP></Surround></Main_Zone></YAMAHA_AV>" }
                Break
            }
        }

        Try {
            $Result = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetCinema3DDSP([bool] $State): An error occurred while setting the Cinema 3D DSP mode on the receiver.'+"`n"+$_)
        }
        $this.SetState()
    }

    # Set Adaptive DRC on or off ($true or $false)
    [void] SetAdaptiveDRC([bool] $State) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()
        If ($this.PowerOn -eq $false) { $this.ReturnWarning("The receiver must be powered on first."); Return }

        $Body = $null

        Switch ($State) {
            $true {
                If ($this.AdaptiveDRC -eq $true) { $this.ReturnWarning("Adaptive DRC is already on."); Return }
                Else { $Body = "<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Sound_Video><Adaptive_DRC>Auto</Adaptive_DRC></Sound_Video></Main_Zone></YAMAHA_AV>" }
                Break
            }
            $false {
                If ($this.AdaptiveDRC -eq $false) { $this.ReturnWarning("Adaptive DRC is already off."); Return }
                Else { $Body = "<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Sound_Video><Adaptive_DRC>Off</Adaptive_DRC></Sound_Video></Main_Zone></YAMAHA_AV>" }
                Break
            }
        }

        Try {
            $Result = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetAdaptiveDRC([bool] $State): An error occurred while setting Adaptive DRC mode on the receiver.'+"`n"+$_)
        }
        $this.SetState()
    }

}