param(
	$runId,
	$app,
	$skip_cleaup, # no value for cleanup, any value to skip 
	$rg_name 
)

# Specify the path to JSON file
$imageFilePath = $app+'/Packer/PackerImageTemplate.json'
$variableFilePath = $app+'/Packer/Variables.json'

# Clean unwanted resources after packer run.
Function  cleanup() 
{
	if ([string]::IsNullOrEmpty($skip_cleaup)) 
	{
		# Clean unwanted resources after packer run.
		# Read the JSON content from the file
		$imgFileContent = Get-Content -Path $imageFilePath -Raw
		$varFileContent = Get-Content -Path $variableFilePath -Raw

		# Parse the JSON content
		$imgJsonObject = $imgFileContent | ConvertFrom-Json
		$varJsonObject = $varFileContent | ConvertFrom-Json

		# $jsonObject contains the data from the JSON file
		$imgJsonObject.builders[0]

		if ([string]::IsNullOrEmpty($rg_name)) 
		{
			$rg_name = $varJsonObject.resource_group_name
		}

		Import-Module Az.Resources	
		if ([string]::IsNullOrEmpty( $runId)) 
		{
			Write-host "VM name not passed for cleanup !"
		}
		else
		{
			$tempvms = Get-AzResource -Name 'pkrvm*'  -ResourceType Microsoft.Compute/virtualMachines

			if ($tempvms.count -gt 0) 
			{
				Write-host "Deleting Temp VM as part of forced cleanup"

				foreach ($tempvm in $tempvms)
				{
    					if (![string]::IsNullOrEmpty( $tempvm.Tags.runId)) 
					{		
						if($tempvm.Tags.runId -eq $runId)
						{
							Remove-AzResource -ResourceId $tempvm.id -Force
						}
      					}
				}
			}	

			# GET Network Interface Card
			$nics = Get-AzResource -Name 'pkrni*'  -ResourceType Microsoft.Network/networkInterfaces

			if ($nics.count -gt 0) 
			{
				Write-host "Deleting Nics as part of forced cleanup"
				foreach ($nic in $nics)
				{
    				  	if (![string]::IsNullOrEmpty( $nic.Tags.runId)) 
					{
						#Nic deletion
						if($nic.Tags.runId -eq $runId)
						{
							Remove-AzResource -ResourceId $nic.id -Force
						}
      					}
				}
			}

			# GET Key Vault
			$kvaults = Get-AzResource -Name 'pkrkv*'  -ResourceType Microsoft.KeyVault/vaults

			if ($kvaults.count -gt 0) 
			{
				Write-host "Deleting Keyvaults as part of forced cleanup"	
				foreach ($kvault in $kvaults) 
				{	
    					if (![string]::IsNullOrEmpty( $kvault.Tags.runId)) 
					{
						if($kvault.Tags.runId -eq $runId)
						{
							Remove-AzResource -ResourceName $kvault.Name -ResourceType Microsoft.KeyVault/vaults -ResourceGroup  $rg_name -Force
						}
      					}
				}
			}

			$disks = Get-AzResource -Name 'pkrosd*'  -ResourceType Microsoft.Compute/diskAccesses

			if ($disks.count -gt 0) 
			{ 
				Write-host "Deleting Disks as part of forced cleanup"
				foreach ($disk in $disks) 
				{	
    					if (![string]::IsNullOrEmpty( $disk.Tags.runId)) 
					{
						if($disk.Tags.runId -eq $runId)
						{
							Remove-AzResource -ResourceId $disk.id -Force
						}
      					}
				}
			}
		}

	}
	else{
		Write-host "Forced Cleanup skipped !"
	}
}
		
# Calling cleanup method.
cleanup
