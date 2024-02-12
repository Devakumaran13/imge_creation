#Parameters app ID, client ID, subscription ID and tenant id passed from pipeline
param(
    $app,
    $client_id,
    $subscription_id,
    $tenant_id
   )
   
$subscriptionId = $subscription_id
$tenantid =$tenant_id
$clientid = $client_id

#common Variables Json file location
$jsonCommonVariablesPath ='Common/Variables.json'
#Read Common Variable
$jsonCommonContent = Get-Content -Path $jsonCommonVariablesPath -Raw | ConvertFrom-Json
$enableAzLatest = $jsonCommonContent.enableAzLatest

# Specify the path to your JSON file
$jsonFilePath = $app+'/Packer/PackerImageTemplate.json'
$jsonVariablesPath =$app+'/Packer/Variables.json'
$Config_validationPath =$app+'/Packer/ValidationConfig.json'
$result = 'true'
$response='true'
$file = "file"
$err = "Error*"
$warning = "Warning*"

#function for read json file 
Function  Configurationvalidation() {
# Read the JSON content from the file
 try { 
        #Tenantid validation
        if ([string]::IsNullOrEmpty($tenantid)) {
            Write-Host "The tenantid not exist."
            $result = 'false'
            return $result 
        }
        
        # ClientId Validation
        if ([string]::IsNullOrEmpty($clientid)) {
            Write-Host "The clientid not exist. "
            $result = 'false'
            return $result 
        }
       
        # subscriptionId Validation
        if ([string]::IsNullOrEmpty($subscriptionId)) {
            Write-Host "The subscriptionId did not exist ."
            $result = 'false'
            return $result 
        }
        Write-Host "TenantId, ClientId and Subscription verified successfully."

      # Packer image Validation
      if($result -eq $response) {
            $packervalidate=ValidatePackerScript
            if($packervalidate -eq $response) {
                Write-Host " Packer Syntex validation succesfully complete."
                $result='true'
            }
            else {
                Write-Host " Packer Syntex is not valid."
                $result='false'
                return $result
            }
        }
     
        #Read Variable file
        $jsonContent = Get-Content -Path $jsonVariablesPath -Raw
        $jsonContent = $jsonContent | ConvertFrom-Json
        
        #Read validationConfig
        $ValidationConfigContent = Get-Content -Path $Config_validationPath -Raw
        $ValidationConfigContent = $ValidationConfigContent | ConvertFrom-Json
        
        
        $storageAccountName = $jsonContent.storageAccountName
        $containername = $jsonContent.container_name
        $resourceGroup = $jsonContent.storage_resource_group
        
        # imagepath Validation
        if($result -eq $response) {
            # Access the provisioners configuration
            $provisioners = $ValidationConfigContent.softwares
            $outlist= ValidationAccessPermission -storageAccountName $storageAccountName -containerName $containerName -resourceGroup $resourceGroup
            
            if (![string]::IsNullOrEmpty($outlist))
            {
                foreach ($provisioner in $provisioners)
                {
                    if ($provisioner.type -eq $file)
                    {
                        $url = $provisioner.source
                        $fileNames = [System.IO.Path]::GetFileName($url)

                        if (![string]::IsNullOrEmpty($url))
                        {
                            # Define a regular expression pattern for a valid file path
                            $pattern = "^[A-Za-z]:\\.*$"
                            $urlPattern = "^(https?|ftp)://[^\s/$.?#].[^\s]*$"

                            # Use the -match operator to check if the file path matches the pattern
                            if ($url -match $pattern -or $url -match $urlPattern) 
                            {
                                Write-Host "The file path syntax is valid: $url"
                                $filename = [System.IO.Path]::GetFileName($imagepath)
                                Write-Host "The file name is : $filename"

                                if ($outlist.Name -contains $fileNames) {
                                    Write-Host " $fileNames exist in the blob storage."
                                    $result = 'true'
                                }
                                else {
                                    Write-Host "$fileNames is not exist in the blob storage."
                                    $result = 'false'
                                    break
                                }
                            }else 
                            {
                                Write-Host "The file path syntax is not valid: $filePath"
                                $result = 'false'
                                break
                            }
                        }
                        else {
                            Write-Host "The image url not exist."
                            $result = 'false'
                            break
                        }
                    }
                }
            }
            else{
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

Function  ValidationAccessPermission([string] $storageAccountName, [string] $containerName,[string] $resourceGroup) {
    try {
            if($enableAzLatest -eq "false"){
                Install-Module -Name Az -RequiredVersion 11.2.0 -Repository PSGallery -Force -AllowClobber
            }else{
                Install-Module -Name Az -Force -AllowClobber 
            }

            Install-Module -Name Az.Attestation
          
        # Set the context to the storage account
        $context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName).Value[0]
        $blockblob = Get-AzStorageBlob -Container  $containerName -Context  $context #-Prefix $blobName
   }catch {
        Write-Host "An error occurred: $($_.Exception.Message)"
    }
    return $blockblob
}

#Validation Packer script syntex and file.
Function ValidatePackerScript() {
try {  
        Write-Host "Packer validate script initialize."
        $output = ""
        #sets the output as machine readable
        $packerCommand = "packer validate -machine-readable -var-file='$jsonVariablesPath' $jsonFilePath"
        $output = Invoke-Expression -Command $packerCommand
        if($output -like $err) {
            Write-Host($output)
            return 'false'
        } elseif ($output -like $warning) {
            Write-Host($output)
        }
        
        #check syntax only with packer
        $packerCommand = "packer validate -syntax-only -var-file='$jsonVariablesPath' $jsonFilePath"
        $output = Invoke-Expression -Command $packerCommand
        if($output -like $err) {
            Write-Host($output)
            return 'false'
        } elseif ($output -like $warning) {
            Write-Host($output)
        }
        # Construct the packer validate command with the variable values
        $packerCommand = "packer validate -var-file='$jsonVariablesPath' $jsonFilePath"

        # Execute the command
        $output  = Invoke-Expression -Command $packerCommand

        if($output -like $err) {
            Write-Host($output)
            return 'false'
        } elseif ($output -like $warning) {
            Write-Host($output)
        }
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)"
    return 'false'
}
    return 'true'
}

#call function for jsonfile reader
$output = Configurationvalidation
if($output-eq 'false')
{
 exit 1
}
