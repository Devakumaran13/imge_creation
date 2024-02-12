#Start-Sleep -Seconds 24000
#sql logs zip

$sqlLogPath = $env:sqlLogPath.Trim()
$zipFolderLocation = $env:zipFolderLocation.Trim()

$zipFileName = (get-item env:\computername).Value + "_" + "sqllog.zip"
$zipFileLocation = $zipFolderLocation + $zipFileName

Compress-Archive -Path $sqlLogPath -DestinationPath $zipFileLocation

#SQL Logs upload into blob storage container
$containersqllogs = $env:containersqllogs.Trim()
$storageAccountKey = $env:StorageAccountKey.Trim()
$storageAccountName = $env:storageAccountName.Trim()

$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $StorageAccountKey

$sqlLogsBlob = @{
    File             = $zipFileLocation
    Container        = $containersqllogs
    Blob             = $zipFileName
    Context          = $context
    StandardBlobTier = 'Hot'
  }

Set-AzStorageBlobContent @sqlLogsBlob
