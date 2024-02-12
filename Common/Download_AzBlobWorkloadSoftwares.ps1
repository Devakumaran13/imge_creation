$rptpath = "C:\tmp"

if (!(test-path -path $rptpath)) 
{
   new-item -path $rptpath -itemtype directory
}

$containerName = $env:container_name.Trim()
$storageAccountKey = $env:StorageAccountKey.Trim()
$storageAccountName = $env:storageAccountName.Trim()
$destinationPath = '/tmp'
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

$blobs = Get-AzStorageBlob -Container $containerName -Context $context

$validationConfig ='/tmp/ValidationConfig.json'
$jsonValidationConfig = Get-Content -Path $validationConfig -Raw | ConvertFrom-Json
$provisioners = $jsonValidationConfig.softwares

foreach($blob in $blobs) 
{ 
   foreach ($provisioner in $provisioners) 
   {
      $sourceFile = [System.IO.Path]::GetFileName($provisioner.source)
    
      if($blob.Name.ToLower() -eq $sourceFile.ToLower()) 
      {
         Get-AzStorageBlobContent -Container $containerName -Blob $blob.Name -Destination $destinationPath -Context $context
      }
   }
}
