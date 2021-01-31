Param
(   
    [Parameter(Mandatory = $true)]
    [String]
    $TagName = "Schedule",
    [Parameter(Mandatory = $true)]
    [String]
    $TagValue = "Mo-Su:0000-2400",
    [Parameter(Mandatory = $true)]
    [Boolean]
    $Shutdown
)

try {
    $tempDate = (Get-Date).ToUniversalTime()
    $tzAWST = [System.TimeZoneInfo]::FindSystemTimeZoneById("W. Australia Standard Time")
    $timestart = [System.TimeZoneInfo]::ConvertTimeFromUtc($tempDate, $tzAWST)

    "Start Time: " + $timestart
    $dayOfWeek = $timestart.DayOfWeek;
    "Day of the Week: " + $dayOfWeek;

    #Ensures that any credentials apply only to the execution of this runbook
    Disable-AzContextAutosave -Scope Process

    "Logging in to Azure..."
    $rbCredential = Get-AutomationPSCredential -Name 'accoutname'
    Connect-AzAccount -Credential $rbCredential
    if ($? -eq "True") { Write-Output "Login sucessfull." } else { Write-Output "Login failed.." }

    #Get all subscriptions
    $subscriptions = (get-azsubscription).Name

    #Loop through all subscriptions
    foreach ($sub in $subscriptions) { 
        #Change the subscription context
        set-azcontext -Subscription $sub
        $FindVMs = $null
        $FindVMs = Get-AzResource -TagName $TagName -TagValue $TagValue | where { $_.ResourceType -like "Microsoft.Compute/virtualMachines" }
        if ($FindVMs) {      
            Write-Output "VM(s) exists under this subscription Name: $sub"
            Write-Output "No. of Virtual Machines found: $($FindVMs.Count)"
            if (!$Shutdown) {       
                Foreach ($VM in $FindVMs) {
                    $vmName = $VM.Name
                    $ResourceGroupName = $VM.ResourceGroupName
                    Write-Output "Starting $($VM.Name)";
                    Start-AzVM -Name $vmName -ResourceGroupName $ResourceGroupName -NoWait;
                    if ($? -eq "True") { 
                        Write-Output "VM Started successfully: $($VM.Name)"
                    }
                    else {
                        Write-Output "VM failed to start: $($VM.Name)"
                    }
                }
            }
            else {
                Foreach ($VM in $FindVMs) {
                    $vmName = $VM.Name
                    $ResourceGroupName = $VM.ResourceGroupName
                    Write-Output "Stopping $($VM.Name)";
                    Stop-AzVM -Name $vmName -ResourceGroupName $ResourceGroupName -Force -NoWait;
                    if ($? -eq "True") { 
                        Write-Output "VM Stopped successfully: $($VM.Name)"
                    }
                    else {
                        Write-Output "VM failed to stop: $($VM.Name)"
                    }
                }   
            }
        }
        else {
            Write-Output "VM(s) doesn't exists under this subscription Name: $sub"
        }     
    }
    $tempDate = (Get-Date).ToUniversalTime()
    $tzAWST = [System.TimeZoneInfo]::FindSystemTimeZoneById("W. Australia Standard Time")
    $timeend = [System.TimeZoneInfo]::ConvertTimeFromUtc($tempDate, $tzAWST)

    "Time Ended: " + $timeend
    $timediff = New-TimeSpan â€“Start $timestart â€“End $timeend
    ""; "Total Time: " + $timediff

    Disconnect-AzAccount
    if ($? -eq "True") { Write-Output "Logout sucessfull." } else { Write-Output "Logout failed.." }

}
catch {
    throw $_.Exception
}
