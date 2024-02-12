$containerName = $env:container_name.Trim()
$storageAccountKey = $env:StorageAccountKey.Trim()
$storageAccountName = $env:storageAccountName.Trim()
$destinationPath = 'C:\Windows\Temp'
$storageAccount = New-AzStorageContext -StorageAccountName storageAccountName -StorageAccountKey $StorageAccountKey
Get-AzStorageBlob -Container $containername -Context $storageAccount

# $container_name = $env:container_name
# $StorageAccountKey = $env:StorageAccountKey
# $container_name = $container_name #'$env:CONTAINERNAME'
# $destination_path = 'C:\Windows\Temp'
# $storage_account = New-AzStorageContext -StorageAccountName "stdtsimagepackages01" -StorageAccountKey $StorageAccountKey
# Get-AzStorageBlob -Container $container_name.Trim() -Context $storage_account


  
