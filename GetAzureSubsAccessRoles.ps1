$RolesList = @()
#Excel file used to store the report contents
[String]$opfile = Read-host "Enter the location of desired .csv output file"

#Remove output file if it already exists.
Remove-Item $opfile -ErrorAction SilentlyContinue

#Login to Azure
Login-AzAccount > $null

$subs = Get-AzSubscription | Select name, id
foreach ($sub in $subs) {
    #Change the subscription context
    Select-AzSubscription -SubscriptionId $sub.Id

    #Common variables - Do NOT change
    $outarray = @()

    #Get list of all RBAC roles for each subcription 
    $sub = Get-Azcontext | Select-Object -ExpandProperty Subscription | Select-Object Name
    $roles = Get-Azroleassignment
    foreach ($r in $roles) {
        $outarray = New-Object PSObject
        $outarray | Add-Member NoteProperty -Name Subscription -Value $sub.Name
        $outarray | Add-Member NoteProperty -Name DisplayName -Value $r.DisplayName
        $outarray | Add-Member NoteProperty -Name ObjectType -Value $r.ObjectType
        $outarray | Add-Member NoteProperty -Name RoleDefinitionName -Value $r.RoleDefinitionName
        $outarray | Add-Member NoteProperty -Name SignInName -Value $r.SignInName
        $outarray | Add-Member NoteProperty -Name Scope -Value $r.Scope
        $RolesList += $outarray
    }
}
#Export the array output to CSV file
$RolesList | Export-csv -Path $opfile -NotypeInformation
