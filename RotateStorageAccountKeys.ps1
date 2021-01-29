    <#
    . SYNOPSIS
         Enable Keys Rotation for the storage accounts using the Key Vault

    . DESCRIPTION
        This script will rotate storage Keys based on the schedule and stores them in the key vault as secrets.

    .REQUIREMENTS
		This can be run by deploying the script into the Azure Runbooks
        Provide access to automation account and having modify rights on the key vault
        
    .AUTHOR
        Ram Mara
		
	.Steps:
	1. Create an Azure Runbooks in Azure Automation Account and make sure to have enough access to run the runbooks.
	2. Copy the below code in the created runbook
	3. Create a schedule based on the need and link it to the Azure Automation Account
    4. Run the runbook using three parameters:
        Parameter1: Provide the Subcription Name or use the default value "ALL" which applies to all subscriptions within the tenant
        Parameter2: Provide the Storage Account Name(s) followed by comma(,) or use the default value "ALL" which applies to all storage accounts within the subscription(s)
        Parameter3: Provide the Key1 or Key2 or All(To change for both the keys)
        Parameter4: Provide the keyvault Name where secrets will be stored
        Parameter5: Provide as "Copy" if you want to copy the existing storage accounts keys in the key vault
                    Provide a "CopyandRotate" option, if you want to copy the existing keys and generate a new key and copy to the key vault

	.Implications:
	1. This script will create two secrets in the given KeyVault based on the storage account name, $StorageAccountName-Key1 and $StorageAccountName-Key2
	2. The latest copy of the Storage Keys will be stored in the Key Vault secrets based on the option provided
    3. If you want to refer to the previous key, please sort out the secrets based on the versions and retrieve the latest one
#>
    Param
    (   
    [Parameter(Mandatory=$True)]
    [String]
    $SubscriptionName="All",
    [Parameter(Mandatory=$True)]
    [String]
    $StorageAccounts="All",
    [Parameter(Mandatory=$True)]
    [String]
    $Keys="All",
    [Parameter(Mandatory=$True)]
    [String]
    $request="Copy",
    [Parameter(Mandatory=$True)]
    [String]
    $KeyVaultName
    )

    $tempDate =(Get-Date).ToUniversalTime()
    $tzAWST = [System.TimeZoneInfo]::FindSystemTimeZoneById("W. Australia Standard Time")
    $timestart = [System.TimeZoneInfo]::ConvertTimeFromUtc($tempDate, $tzAWST)

    "Start Time: "+ $timestart
     $dayOfWeek=$timestart.DayOfWeek;
    "Day of the Week: "+$dayOfWeek;

        try
        {
            "Logging in to Azure..."
            $rbCredential = Get-AutomationPSCredential -Name 'accountname'
            Connect-AzAccount -Credential $rbCredential
            if($? -eq "True") { Write-Output "Login sucessfull." } else { Write-Output "Login failed.." }

            Function CreateCopyofExistingKeys()
            {                  
                Write-Output "Using function: CreateCopyofExistingKeys for storage account: $StorageAccountName"
                $SAKeys = Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName

                $secretvaluekey1 = ConvertTo-SecureString $SAKeys[0].Value -AsPlainText -Force
                $secretvaluekey2 = ConvertTo-SecureString $SAKeys[1].Value -AsPlainText -Force

                Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameKey1 -SecretValue $secretvaluekey1
                if($? -eq "True") { write-output "Copied storage account key1 successfully" }
				Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameKey2 -SecretValue $secretvaluekey2	
                if($? -eq "True") { write-output "Copied storage account key2 successfully" }
            }

            Function CreateCopyofExistingKey1()
            {                  
                Write-Output "Using function: CreateCopyofExistingKey1 for storage account: $StorageAccountName"
                $SAKeys = Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName

                $secretvaluekey1 = ConvertTo-SecureString $SAKeys[0].Value -AsPlainText -Force

                Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameKey1 -SecretValue $secretvaluekey1
                if($? -eq "True") { write-output "Copied storage account key1 successfully" }
            }


            Function CreateCopyofExistingKey2()
            {                  
                Write-Output "Using function: CreateCopyofExistingKey2 for storage account: $StorageAccountName"
                $SAKeys = Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName

                $secretvaluekey2 = ConvertTo-SecureString $SAKeys[1].Value -AsPlainText -Force

				Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameKey2 -SecretValue $secretvaluekey2	
                if($? -eq "True") { write-output "Copied storage account key2 successfully" }
            }


            Function RotateExistingKeys()
            {
                Write-Output "Using function: RotateExistingKeys for storage account: $StorageAccountName"             
                New-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName -KeyName "key1" -Verbose
				New-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName -KeyName "key2" -Verbose
				
				$SAKeys = Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName
				
				$secretvaluekey1 = ConvertTo-SecureString $SAKeys[0].Value -AsPlainText -Force
				$secretvaluekey2 = ConvertTo-SecureString $SAKeys[1].Value -AsPlainText -Force
					
				Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameKey1 -SecretValue $secretvaluekey1
                if($? -eq "True") { write-output "Rotated storage account key1 successfully" }
				Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameKey2 -SecretValue $secretvaluekey2	
                if($? -eq "True") { write-output "Rotated storage account key2 successfully" }
            }          


            Function RotateExistingKey1()
            {
                Write-Output "Using function: RotateExistingKey1 for storage account: $StorageAccountName"             
                New-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName -KeyName "key1" -Verbose
				
				$SAKeys = Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName
				
				$secretvaluekey1 = ConvertTo-SecureString $SAKeys[0].Value -AsPlainText -Force
					
				Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameKey1 -SecretValue $secretvaluekey1
                if($? -eq "True") { write-output "Rotated storage account key1 successfully" }
            }   


            Function RotateExistingKey2()
            {
                Write-Output "Using function: RotateExistingKey2 for storage account: $StorageAccountName"             
				New-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName -KeyName "key2" -Verbose
				
				$SAKeys = Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName
				
				$secretvaluekey2 = ConvertTo-SecureString $SAKeys[1].Value -AsPlainText -Force
					
				Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameKey2 -SecretValue $secretvaluekey2	
                if($? -eq "True") { write-output "Rotated storage account key2 successfully" }
            }


            Function RotateStorageKeys($value)
            {
                if($value -eq '0')
                {
                    CreateCopyofExistingKeys
                }
                elseif($value -eq '1')
                {
                    CreateCopyofExistingKeys
                    RotateExistingKeys
                }
                    elseif($value -eq '2')
                {
                    RotateExistingKeys
                }
            }

            Function RotateStorageKey1($value)
            {
                if($value -eq '0')
                {
                    CreateCopyofExistingKey1
                }
                elseif($value -eq '1')
                {
                    CreateCopyofExistingKey1
                    RotateExistingKey1
                }
                elseif($value -eq '2')
                {
                    RotateExistingKey1
                }
            }

            Function RotateStorageKey2($value)
            {
                if($value -eq '0')
                {
                    CreateCopyofExistingKey2
                }
                elseif($value -eq '1')
                {
                    CreateCopyofExistingKey2
                    RotateExistingKey2
                }
                elseif($value -eq '2')
                {
                    RotateExistingKey2
                }
            }           

            Function ExecuteOperations()
            {
                $SecretNameKey1 = $StorageAccountName + '-key1'
				$SecretNameKey2 = $StorageAccountName + '-key2'

                $SNKey1 = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameKey1
                $SNKey2 = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretNameKey2

                if($request -eq 'Copy')
                {
                    $value = 0
                    if($Keys -eq 'Key1')
                    {
                        Write-Output "Following key(s) is been selected: $Keys"
                        RotateStorageKey1 -value $value
                    }
                    if($Keys -eq 'Key2')
                    {
                        Write-Output "Following key(s) is been selected: $Keys"
                        RotateStorageKey2 -value $value
                    }
                    elseif($Keys -eq 'All')
                    {           
                        Write-Output "Following key(s) have been selected: $Keys"
                        RotateStorageKeys -value $value
                    }
                }
                elseif($request -eq 'CopyandRotate')
                {
                    if(!$SNKey1.Name -and !$SNKey2.Name)
                    {
                        $value = 1
                        if($Keys -eq 'Key1')
                        {
                            Write-Output "Following key(s) is been selected: $Keys"
                            RotateStorageKey1 -value $value
                        }
                        if($Keys -eq 'Key2')
                        {
                            Write-Output "Following key(s) is been selected: $Keys"
                            RotateStorageKey2 -value $value
                        }
                        elseif($Keys -eq 'All')
                        {           
                            Write-Output "Following key(s) have been selected: $Keys"
                            RotateStorageKeys -value $value
                        }
                    }
                    else
                    {
                        $value = 2
                        if($Keys -eq 'Key1')
                        {
                            Write-Output "Following key(s) is been selected: $Keys"
                            RotateStorageKey1 -value $value
                        }
                        if($Keys -eq 'Key2')                        
                        {
                            Write-Output "Following key(s) is been selected: $Keys"
                            RotateStorageKey2 -value $value
                        }
                        elseif($Keys -eq 'All')
                        {           
                            Write-Output "Following key(s) have been selected: $Keys"
                            RotateStorageKeys -value $value
                        }
                    }
                }
            }

            if($SubscriptionName -ne 'All')
            {                
                $subscriptions = $SubscriptionName
            }
            else
            {           
                #Get all subscriptions
                $subscriptions = (get-azsubscription).Name
            }

	        #Loop through all subscriptions
            foreach ($sub in $subscriptions)
	        { 
		        #Change the subscription context
	            set-azcontext -Subscription $sub
                Write-Output "Subscription Name: $sub"
                Write-Output "Key Vault Name: $KeyVaultName"

                if($StorageAccounts -ne 'All')
                {
                    #Get specific storage accounts                    
                    $rgstordetails = $StorageAccounts.Split("/")
                    foreach($rgstdetail in $rgstordetails)
                    {
                        $scdetails = $rgstdetail.Split(":")
                        $StorageAccountName = $scdetails[0]
                        $RGName = $scdetails[1]                        
                        Write-Output "Following storage account and Resource Group has been selected: $StorageAccountName and $RGName"                                          
                        ExecuteOperations
                    }
                }
                else
                {           
                    #Get all storage accounts
                    $scdetails = Get-AzStorageAccount | Select StorageAccountName,ResourceGroupName
                    Write-Output "No. of Storage Accounts found: $($scdetails.Count)"
                    foreach($scdetail in $scdetails)
		            {
                        $StorageAccountName = $scdetail.StorageAccountName
				        $RGName = $scdetail.ResourceGroupName
                        Write-Output "Following storage account and Resource Group has been selected: $StorageAccountName and $RGName" 
                        ExecuteOperations
		            }
                }
            }          
            $tempDate =(Get-Date).ToUniversalTime()
            $tzAWST = [System.TimeZoneInfo]::FindSystemTimeZoneById("W. Australia Standard Time")
            $timeend = [System.TimeZoneInfo]::ConvertTimeFromUtc($tempDate, $tzAWST)

            Disconnect-AzAccount
            if($? -eq "True") { Write-Output "Logout sucessfull." } else { Write-Output "Logout failed.." }

            "Time Ended: "+$timeend
            $timediff = New-TimeSpan –Start $timestart –End $timeend
            "";"Total Time: "+$timediff

        }
        catch
        {
            throw $_.Exception
        }
