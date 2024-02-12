#Parameters app ID, client ID, subscription ID and tenant id passed from pipeline
param(
	$app,
	$subscription_id,
	$run_id,
	$Storage_Account_Key
)

$pkrKeyVault = 'pkrkv*'
$pkrNic = "pkrni*"
$pkrDisk = "pkros*"
$err = "ERROR:*"

#common Variables Json file location
$jsonCommonVariablesPath ='Common/Variables.json'
#Read Common Variable
$jsonCommonContent = Get-Content -Path $jsonCommonVariablesPath -Raw | ConvertFrom-Json
$enableAzLatest = $jsonCommonContent.enableAzLatest

# Specify the path to JSON file
$imageFilePath = $app + '/Packer/PackerImageTemplate.json'
$variableFilePath = $app + '/Packer/Variables.json'
 
#function for read json file
Function  configurationPostValidation() {
 
	$result = 'true'
	try {
		$subscriptionId = $subscription_id
		  
		# Read the JSON content from the file
		$imgFileContent = Get-Content -Path $imageFilePath -Raw
		$varFileContent = Get-Content -Path $variableFilePath -Raw
  
		# Parse the JSON content
		$imgJsonObject = $imgFileContent | ConvertFrom-Json
		$varJsonObject = $varFileContent | ConvertFrom-Json
 
		# Now $jsonObject contains the data from the JSON file
  
		$imageName = $imgJsonObject.builders[0].managed_image_name
		$resourceGrp = $varJsonObject.resource_group_name
		$storageAccountName = $varJsonObject.storageAccountName
		$containerValidationLogs = $varJsonObject.containerValidationlogs
		$vmName = $varJsonObject.vm_name
 		
		# subscriptionId Validation
 
		if ([string]::IsNullOrEmpty($subscriptionId)) {
			Write-Host "The subscriptionId does not exist"
			return 'false'
		}
 
		#resource group validation
		if ([string]::IsNullOrEmpty($resourceGrp)) {
			Write-Host "The resource group does not exist in the variables.json file."
			return 'false'
		}
  
		#Image name validation
		if ([string]::IsNullOrEmpty($imageName)) {
			Write-Host "The Image Name does not exist in the variables.json file."
			return 'false'
		}

		#vm name validation
		if ([string]::IsNullOrEmpty($vmName)) {
			Write-Host "The vmName does not exist in the variables.json file."
			return 'false'
		}

		#storageAccountName validation
		if ([string]::IsNullOrEmpty($storageAccountName)) {
			Write-Host "The storageAccountName does not exist in the variables.json file."
			return 'false'
		}

		#containerValidationlogs validation
		if ([string]::IsNullOrEmpty($containerValidationlogs)) {
			Write-Host "The containerValidationlogs does not exist in the variables.json file."
			return 'false'
		}

		#run_id validation
		if ([string]::IsNullOrEmpty($run_id)) {
			Write-Host "The $run_id does not exist."
			return 'false'
		}
  
		$imageName = -join ($imageName.Substring(0, $imageName.IndexOf("{")), $vmName)
		
		if($enableAzLatest -eq "false"){
			Install-Module -Name Az -RequiredVersion 11.2.0 -Repository PSGallery -Force -AllowClobber
		}else{
			Install-Module -Name Az -Force -AllowClobber 
		}

		Install-Module -Name Az.Attestation
                
		#Resource ID
		$resourceId = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $resourceGrp + "/providers/Microsoft.Compute/images/" + $imageName

		#Function to Validate the image and it's size
		$result = ValidateImageAndSize($resourceId)
		if ($result -eq 'false') {
			return $result
		}
		# check the resources in resource group
		$result = CheckResources $resourceGrp $imageName
		if ($result -eq 'false') {
			return $result
		}
		$result = VerifyErrorLog $storageAccountName $containerValidationlogs
	}
	catch {
		Write-Host "An error occurred: $($_.Exception.Message)"
		$result = 'false'
	}
	return $result
}
#Function to validate the Image and to check the Image size
Function ValidateImageAndSize($resourceId) {
	$runId = $run_id
	$result = 'true'
	try {
		#Get the resource info
		$resourceInfo = Get-AzResource -ResourceId $resourceId
		if ($resourceInfo -and ![string]::IsNullOrEmpty( $resourceInfo.Tags.runId)) {
  			if($resourceInfo.Tags.runId -eq $runId) {
				#get the size of Image
				$diskSize = $resourceInfo.Properties.storageProfile.osDisk.diskSizeGB
				if ($diskSize -eq 0) {
					Write-Host("Invalid Image.")
					$result = 'false'
				}
				else {
					Write-Host("Image exists.")
				}
   			} else {
      				Write-Host("RunId: $runId does not match.")
				$result = 'false'
      			}
		}
		else {
			Write-Host("Resource: $resourceId does not exists")
			$result = 'false'
		}
	}
	catch {
		Write-Host "An error occurred: $($_.Exception.Message)"
		$result = 'false'
	}
	return $result
}

#Function to check the resources in resource group
Function CheckResources($resourceGrp, $imageName) {
	$runId = $run_id
	$result = 'true'
	try {
		# GET Key Vault
		$kvault = Get-AzKeyVault -VaultName $pkrKeyVault
	
		# GET Network Interface Card
		$nic = Get-AzResource -Name $pkrNic -ResourceType Microsoft.Network/networkInterfaces
	
		# GET Disk 
		$disk = Get-AzResource -Name $pkrDisk -ResourceType Microsoft.Compute/disks
 	
		if ($nic.count -gt 0) {
			if (![string]::IsNullOrEmpty( $nic.Tags.runId) -and $nic.Tags.runId -eq $runId) {
			  Write-Host "Additional NIC found in resource group $resourceGrp, cleanup required"
			  $result = 'false'
			}
		}
 
		if ($kvault.count -gt 0) {
			if (![string]::IsNullOrEmpty( $kvault.Tags.runId) -and $kvault.Tags.runId -eq $runId) {
				Write-Host "Additional KeyVault found in resource group $resourceGrp, cleanup required"
				$result = 'false'
			}
		}
 
		if ($disk.count -gt 0) {
			if (![string]::IsNullOrEmpty( $disk.Tags.runId) -and $disk.Tags.runId -eq $runId) {
				Write-Host "Additional Disk found in resource group $resourceGrp, cleanup required"
				$result = 'false'
			}
		}
	}
	catch {
		Write-Host "An error occurred: $($_.Exception.Message)"
		$result = 'false'
	}
	return $result
}

Function VerifyErrorLog($storageAccName, $containerValidationLogs) {
	$result = 'true'
	try {
		$StorageAccountKey = $Storage_Account_Key
		#StorageAccountKey validation
		if ([string]::IsNullOrEmpty($StorageAccountKey)) {
			Write-Host "The StorageAccountKey does not exist."
			return 'false'
		}

		$storageAccountName = $storageAccName
		$containerName = $containerValidationLogs
		$blobName = $run_id
		$blobName = $blobName.ToString()
		$blobName = $blobName + ".log"
  
		$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $StorageAccountKey
		$container_client = Get-AzStorageContainer -Name $containerName -Context $context
		$source_blob_client = $container_client.CloudBlobContainer.GetBlockBlobReference($blobName)
		if (!$source_blob_client.Exists()) {
			Write-Host "The $blobName does not exist."
			$result = 'false'
			return $result
		}
  
		#download the blob as text into memory
		$download_file = $source_blob_client.DownloadText()
		$download_file = $download_file.Split("`n")
		foreach ($line in $download_file) {
			if ($line -like $err) {
				Write-Host $line
				$result = 'false'
			}
		}
		if ($result -eq 'true') {
			Write-Host "Functional validation successful."
		}
	}
	catch {
		Write-Host "An error occurred: $($_.Exception.Message)"
		$result = 'false'
	}
	return $result
}

#call function for jsonfile reader
$output = configurationPostValidation
if ($output -eq 'false') {
 exit 1
}
