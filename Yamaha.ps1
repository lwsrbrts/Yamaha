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

    [bool] $PowerOn
    [bool] $MuteOn
    [ValidateRange(-800,-200)][int] $VolumeLevel
    [ipaddress] $IPAddress
    [System.Xml.XmlDocument] $Status

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
        }
        Return $false
    }

    # Get the current state of the receiver.
    hidden [void] SetState() {
        $this.Status = $this.GetMainZoneStatus()
        $this.PowerOn = $this.ConvertState($this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Power_Control.Power)
        $this.MuteOn = $this.ConvertState($this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Volume.Mute)
        $this.VolumeLevel = $this.Status.YAMAHA_AV.Main_Zone.Basic_Status.Volume.Lvl.Val
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
                If ($this.PowerOn -eq $true) { Throw "The receiver is already on." }
                Else { $Body = '<YAMAHA_AV cmd="PUT"><Main_Zone><Power_Control><Power>On</Power></Power_Control></Main_Zone></YAMAHA_AV>' }
                Break
            }
            $false {
                If ($this.PowerOn -eq $false) { Throw "The receiver is already off." }
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
        If ($this.PowerOn -eq $false) { Throw "The receiver must be powered on first." }

        $Body = $null

        Switch ($State) {
            $true {
                If ($this.MuteOn -eq $true) { Throw "The receiver is already muted." }
                Else { $Body = '<YAMAHA_AV cmd="PUT"><Main_Zone><Volume><Mute>On</Mute></Volume></Main_Zone></YAMAHA_AV>' }
                Break
            }
            $false {
                If ($this.MuteOn -eq $false) { Throw "The receiver is not currently muted." }
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
    [void] SetVolume([int] $VolumeLevel) {
        # Refresh the state of the receiver, who knows what's changed.
        $this.SetState()

        If ($this.PowerOn -eq $false) { Throw "The receiver must be powered on first." }
        If ($VolumeLevel % 5 -ne 0) { Throw "VolumeLevel must be divisible by 5." }
        $this.VolumeLevel = $VolumeLevel

        $Body = "'<YAMAHA_AV cmd=`"PUT`"><Main_Zone><Volume><Lvl><Val>$VolumeLevel</Val><Exp>1</Exp><Unit>dB</Unit></Lvl></Volume></Main_Zone></YAMAHA_AV>"
        $State = $null

        Try {
            $State = Invoke-RestMethod -Method Post -Uri "http://$($this.IPAddress)/YamahaRemoteControl/ctrl" -ContentType 'text/xml' -Body $Body
        }
        Catch {
            $this.ReturnError('SetVolume([int] $VolumeLevel): An error occurred while setting the volume.'+"`n"+$_)
        }
    }


}