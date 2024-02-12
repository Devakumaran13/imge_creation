#constants
$vcCrtDll = "vcruntime140d.dll"
$uCrtDll = "ucrtbased.dll"
$envFilePath = "C:\dtsenv.json"
$ServiceRegistryPort = 8119
$vcRedistProdName = "Microsoft Visual C++ 2015-2022 Redistributable (x64) - 14.36.32532"
$vcRegistryPath = "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
$siteId = "2A911F39-8DCA-4FB1-B968-3181AFB791EC"
$srvRegExePath = "C:\svcreg\Citrix.XaXd.Cloud.ServiceRegistry.exe"
$sqlService = "MSSQL`$`SQLEXPRESS"
$sqlBrowserService = "SQLBrowser"
$sqlSrvProdName = 'Microsoft SQL Server 2019 Setup (English)'
$sqlSrvProdVer = '15.0.4013.40'
$uninstallProgRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$localDBProductName = 'Microsoft SQL Server 2019 LocalDB'
$localDbProductVersion ='15.0.4198.2'
$dockerService = "docker"
$tcp = "TCP"
$udp = "UDP"
$tcpPortNo = 1433
$udpPortNo = 1434
$tcpRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp"
$cdfFilePath = "C:\CdfCaptureService.msi"
$fwSqlTcpRule = "SQL TCP 1433"
$fwSqlUdpRule = "SQL UDP 1434"
$fwSqlExeRule = "SQL sqlservr.exe"
$fwSqlBrowserExeRule = "SQL sqlbrowser.exe"
$dirSystem32="\System32\"
$sqlExpress="SQLEXPRESS"
$vcRedist="Microsoft Visual C++*Redistributable*"
$sqlServerSetup="Microsoft SQL Server 2019*Setup*"
$sqlServerLocaldb="Microsoft SQL Server*LocalDB*"
$statusRunning="Running"
$InboundDirection="Inbound"

# Variables
$rptpath = $env:tmpFolderPath.Trim()
$StorageAccountKey = $env:StorageAccountKey.Trim()
$storageAccountName = $env:storageAccountName.Trim()
$logFileName = $env:runId.Trim()
$logFilePath = $rptpath + "\" + $logFileName + ".log"
$containerValidationlogs = $env:containerValidationlogs.Trim()
$blobName = $logFileName.Trim() + ".log"

$Global:resultlog = ""

#create the log file and upload it to blob storage
Function createAndUploadLog()
{
    try{
        #storageAccountKey Validation
        if ([string]::IsNullOrEmpty($StorageAccountKey)) {
            Write-Host "The StorageAccountKey does not exist."
        }

        #storageAccountName Validation
        if ([string]::IsNullOrEmpty($storageAccountName)) {
            Write-Host "The storageAccountName does not exist."
        }

        #logFileName validation
        if ([string]::IsNullOrEmpty($logFileName)) {
            Write-Host "The logFileName does not exist."
        }

        #tempFolderPath validation
        if ([string]::IsNullOrEmpty($rptpath)) {
            Write-Host "The tempFolderPath does not exist."
        }

        #containerValidationlogs validation
        if ([string]::IsNullOrEmpty($containerValidationlogs)) {
            Write-Host "The containerValidationlogs does not exist."
        }

        #log directory validation
        if (!(test-path -path $rptpath)) {
            new-item -path $rptpath -itemtype directory
        }

        #Writing the log message into log file
        Set-Content -Path $logFilePath -Value $Global:resultlog
        
        # Get the storage account and container
        $storage_context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $StorageAccountKey
        
        # Upload the file to the blob
        Set-AzStorageBlobContent -Container $containerValidationlogs -Blob $blobName -File $logFilePath -Context $storage_context
        
    } catch {
        Write-Host "ERROR: An error occurred: $($_.Exception.Message)"
    }
}

# Validation Scripts 
#validateDlls
Function validateDlls()
{
    try{
        $winPath = $env:windir
        $sysPath = $winPath + $dirSystem32
        $vcCrtdllPath = $sysPath + $vcCrtDll
        $uCrtDlldllPath = $sysPath + $uCrtDll
        if(![System.IO.File]::Exists($vcCrtdllPath)){
            $Global:resultlog = $Global:resultlog + "ERROR: Dll : $vcCrtdllPath does not exists.`n"
        } else {
            $Global:resultlog = $Global:resultlog + "INFO: $vcCrtDll exists.`n"
        }
        if(![System.IO.File]::Exists($uCrtDlldllPath)){
            $Global:resultlog = $Global:resultlog + "ERROR: Dll : $uCrtDlldllPath does not exists." + "`n"
        } else {
            $Global:resultlog = $Global:resultlog + "INFO: $uCrtDll exists." + "`n"
        }
    }
    catch{
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)" + "`n"
    }
}
 
#validateEnvFile
Function validateEnvFile()
{
    $result='true'
    try{
        if([System.IO.File]::Exists($envFilePath))
        {
            $envFileContent = Get-Content -Path $envFilePath -Raw
            $envJsonObject = $envFileContent | ConvertFrom-Json
            $serverName = $envJsonObject.SQLServerName
            $serverInstanceName = $envJsonObject.SQLServerInstanceName
            $serverUsrName = $envJsonObject.SQLServerUser
            $srvRegPort = $envJsonObject.ServiceRegistryPort
            if ([string]::IsNullOrEmpty($serverName)) {
                $Global:resultlog = $Global:resultlog + "ERROR: The SQLServerName does not exist.`n"
                $result='false'
             }
            if ([string]::IsNullOrEmpty($serverInstanceName)) {
                $Global:resultlog = $Global:resultlog + "ERROR: The Server Instance Name does not exist.`n"
                $result='false'
            } elseif ($serverInstanceName -ne $sqlExpress) {
                $Global:resultlog = $Global:resultlog + "ERROR: Invalid Sql Server Instance Name: $serverInstanceName`n"
                $result='false'
            }
 
            if ([string]::IsNullOrEmpty($serverUsrName)) {
                $Global:resultlog = $Global:resultlog + "ERROR: The SQLServerUser does not exist.`n"
                $result='false'
             }
 
            if ([string]::IsNullOrEmpty($srvRegPort)) {
                $Global:resultlog = $Global:resultlog + "ERROR: The ServiceRegistryPort does not exist.`n"
                $result='false'
             } elseif ($srvRegPort -ne $serviceRegistryPort) {
                $Global:resultlog = $Global:resultlog + "ERROR: Invalid serivce registry port: $srvRegPort`n"
                $result='false'
            }
        } else {
            $Global:resultlog = $Global:resultlog + "ERROR: Environment file: $envFilePath does not exists.`n"
            $result='false'
          }
    }
    catch{
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
        $result='false'
     }
    if($result -eq 'true'){
        $Global:resultlog = $Global:resultlog + "INFO: $envFilePath verified successfully.`n"
    }
}
 
#Validate VcRedist
Function ValidateVcRedist()
{
    $bFound = $false
    Try
    {
        # Get all installed programs
        $installedPrograms = Get-ItemProperty -Path "$vcRegistryPath\*" | Where-Object { $_.DisplayName -like $vcRedist }
        # Display the product names
        if(![string]::IsNullOrEmpty($installedPrograms))
        {
          foreach($item in $installedPrograms){
            $Global:resultlog = $Global:resultlog + "INFO: " + $item.DisplayName + " installed.`n"
            if($vcRedistProdName.Trim().ToLower() -eq $item.DisplayName.Trim().ToLower())
            {
                $Global:resultlog = $Global:resultlog + "INFO: Required version " + $item.DisplayName + " exists in current System.`n"
                $bFound = $true
            }
           
          }
          if($bFound -ne $true) {
                $Global:resultlog = $Global:resultlog + "ERROR: " + $vcRedistProdName + " not found.`n"
            }
        }
         else {
            $Global:resultlog = $Global:resultlog + "ERROR: " + $vcRedistProdName + " is not installed.`n"
         }
     } Catch {
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
     }
}

#Validate Service Registry 
Function checkServiceRegistry()
{
    try{
        if(![System.IO.File]::Exists($srvRegExePath)){
            $Global:resultlog = $Global:resultlog + "ERROR: " + $srvRegExePath + " does not exists.`n"
        } else {
            $Global:resultlog = $Global:resultlog + "INFO: " + $srvRegExePath + " exists.`n"
        }
        $envPath = $env:ASPNETCORE_URLS
        if($envPath -ne "http://*:$ServiceRegistryPort") {
            $Global:resultlog = $Global:resultlog + "ERROR: Environment ASPNETCORE_URLS properly not set.`n"
        }else{
            $Global:resultlog = $Global:resultlog + "INFO: Environment variable ASPNETCORE_URLS properly set.`n"
        }
        $envPath = $env:VIRTUAL_SITE_IDS
        if($envPath -ne $siteId) {
            $Global:resultlog = $Global:resultlog + "ERROR: Environment VIRTUAL_SITE_IDS properly not set.`n"
        }else{
            $Global:resultlog = $Global:resultlog + "INFO: Environment variable VIRTUAL_SITE_IDS properly set.`n"
        }
    }catch{
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
    }
}
 
#validateSqlServer
Function validateSqlServer()
{
    try {
        $srvcInfo = Get-Service -Name $sqlService -ErrorAction Stop
        if(![string]::IsNullOrEmpty($srvcInfo)) {
            if($srvcInfo.Status -eq $statusRunning) {
                $Global:resultlog = $Global:resultlog + "INFO: " + $sqlService + " service is running.`n"
            } else {
                $Global:resultlog = $Global:resultlog + "ERROR: " + $sqlService + " service is not running.`n"
            }
        } else {
            $Global:resultlog = $Global:resultlog + "ERROR: " + $sqlService + " service not found.`n"
        }
 
        $srvcInfo = Get-Service -Name $sqlBrowserService -ErrorAction Stop
 
        if(![string]::IsNullOrEmpty($srvcInfo)) {
            if($srvcInfo.Status -eq $statusRunning) {
                $Global:resultlog = $Global:resultlog + "INFO: " + $sqlBrowserService + " service is running.`n"
            } else {
                $Global:resultlog = $Global:resultlog + "ERROR: " + $sqlBrowserService + " service is not running.`n"
            }
        } else {
            $Global:resultlog = $Global:resultlog + "ERROR: " + $sqlBrowserService + " service not found.`n"
        }
    }
    catch {
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
    }
}
 
#Validate SqlServerVersion
function validateSqlServerVersion
{
    try
    {
        # Get all installed programs
        $installedPrograms = Get-ItemProperty -Path "$uninstallProgRegPath\*" | Where-Object { $_.DisplayName -like $sqlServerSetup }
        # Display the product names
        if(![string]::IsNullOrEmpty($installedPrograms))
        {
          foreach($item in $installedPrograms){
          if($sqlSrvProdName.Trim().ToLower() -eq $item.DisplayName.Trim().ToLower())
          {
            $Global:resultlog = $Global:resultlog + "INFO: " + $item.DisplayName + " exist in current System.`n"
            if($sqlSrvProdVer -eq $item.DisplayVersion) {
                $Global:resultlog = $Global:resultlog + "INFO: " + $item.DisplayName + " supported version exist in current System.`n"
                ValidateTcpAndPort
                break
           } else {
            $Global:resultlog = $Global:resultlog + "ERROR: " + $item.DisplayName + " supported version " + $item.Version + " is not match as per the required configuration.`n"
           }
          }else{
            $Global:resultlog = $Global:resultlog + "ERROR: " + $sqlSrvProdName + " does not exists in current System.`n"
          }
         }
         }
         else {
            $Global:resultlog = $Global:resultlog + "ERROR: " + $sqlSrvProdName + " does not exists in current System.`n"
         }
     } Catch {
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
     }
}
 
#validate firewall settings
Function checkFirewallSettings()
{
    try {
        #Get firewall settings
        $fireWallStatus = Get-NetFirewallProfile
        #check the Status
        $fireWallStatus | ForEach-Object -Process {
            if($_.Enabled -eq $true) {
                $Global:resultlog = $Global:resultlog + "ERROR: Firewall not disabled for profile " + $_.Profile + "`n"
 
            }else {
                $Global:resultlog = $Global:resultlog + "INFO: Firewall disabled for profile " + $_.Profile + "`n"
 
            }
        }
    }
    catch {
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
    }
}
 
#Validate SQLSERVER LocalDB
function ValidateSqlServerLocalDb
{
    Try
    { 
        # Get all installed programs
        $installedPrograms = Get-ItemProperty -Path "$uninstallProgRegPath\*" | Where-Object { $_.DisplayName -like $sqlServerLocaldb }
 
        # Display the product names
        if(![string]::IsNullOrEmpty($installedPrograms))
        {
          foreach($item in $installedPrograms){
 
          if($localDBProductName.Trim().ToLower() -eq $item.DisplayName.Trim().ToLower())
          {
            $Global:resultlog = $Global:resultlog + "INFO: " + $item.DisplayName.Trim() + " exist in current System.`n"
           if($localDbProductVersion -eq $item.DisplayVersion){
            $Global:resultlog = $Global:resultlog + "INFO: " + $item.DisplayName.Trim() + " supported version " +  $item.DisplayVersion + " exist in current System.`n"
            break
 
           }else{
            $Global:resultlog = $Global:resultlog + "ERROR:" + $item.DisplayName.Trim() + " supported version " +  $item.Version + " is not match as per the required configuration.`n"
           }
          }else{
            $Global:resultlog = $Global:resultlog + "ERROR: " + $localDBProductName + " does not exists in current System.`n"
           }
         }
         }
         else{
            $Global:resultlog = $Global:resultlog + "ERROR: " + $localDBProductName + " is not installed.`n"
         }
    }Catch{
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
    }
}
 
#Docker Validation
function ValidateDocker()
{
    try
    {
        # Check if Docker service is running
        $dockerService = Get-Service -Name $dockerService -ErrorAction Stop
        if ($dockerService.Status -eq $statusRunning) {
            $Global:resultlog = $Global:resultlog + "INFO:" + $dockerService + "service is running.`n"
        } else {
            $Global:resultlog = $Global:resultlog + "ERROR:" + $dockerService + "service is not running.`n"
        }
   
    } catch {
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
    }
}
 
#SQL Server TCP IP Port Validation
Function ValidateTcpAndPort()
{
    try{
        $Keys = Get-ItemProperty -Path $tcpRegistryPath
        if(![string]::IsNullOrEmpty($keys)) {
            foreach($key in $Keys) {
                if($Key.Enabled -eq 1) {
                    $Global:resultlog = $Global:resultlog + "INFO: TCP protocol is enabled.`n"
                } else {
                    $Global:resultlog = $Global:resultlog + "ERROR: TCP protocol is not enabled.`n"
                }
            }
        } else {
            $Global:resultlog = $Global:resultlog + "Error: Registry path not found.`n"
        }
        #Restart sql server service
        restart-service $sqlService
        $output = Test-NetConnection -ComputerName localhost -Port $tcpPortNo
 
        if($output.TcpTestSucceeded -eq "True") {
            $Global:resultlog = $Global:resultlog + "INFO: Port no $tcpPortNo configured.`n"
        } else {
            $Global:resultlog = $Global:resultlog + "ERROR: Port no $tcpPortNo not configured.`n"
        }
        }Catch{
            $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
        }
}
 
#CDF Package Validation
function ValidateCDFPackage()
{
    try{
        if([System.IO.File]::Exists($cdfFilePath)) {
            $Global:resultlog = $Global:resultlog + "INFO: $cdfFilePath exists.`n"
           
        } else {
            $Global:resultlog = $Global:resultlog + "ERROR: $cdfFilePath does not exists.`n"
 
        }
    }
    catch{
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
    }
}
 
#Validate firewall rules
Function ValidateFirewallRules()
{
    try{
        #Verfify tcp firewall rule for 1433
        $firewallSetting = Get-NetFirewallPortFilter |
            Where-Object { $_.LocalPort -eq $tcpPortNo -and $_.Protocol -eq $tcp} | Get-NetFirewallRule
 
        if(![string]::IsNullOrEmpty($firewallSetting)) {
            if($firewallSetting.DisplayName -eq $fwSqlTcpRule) {
                $Global:resultlog = $Global:resultlog + "INFO: Firewall rule " + $fwSqlTcpRule + " found.`n"
                if($firewallSetting.Enabled -eq "True" -and $firewallSetting.Direction -eq $InboundDirection) {
                    $Global:resultlog = $Global:resultlog + "INFO: Firewall rule " + $fwSqlTcpRule + " configured properly.`n"
                } else {
                    $Global:resultlog = $Global:resultlog + "ERROR: Firewall rule " + $fwSqlTcpRule + " not configured properly.`n"
                }
            } else {
                $Global:resultlog = $Global:resultlog + "Error: Firewall rule " + $fwSqlTcpRule + " not found.`n"
            }
        } else {
            $Global:resultlog = $Global:resultlog + "Error: Firewall rule for " + $tcp + " protocol and port " + $tcpPortNo + " not found.`n"
        }
 
        #Verfify udp firewall rule for 1434
        $firewallSetting = Get-NetFirewallPortFilter |
            Where-Object { $_.LocalPort -eq $udpPortNo -and $_.Protocol -eq $udp} | Get-NetFirewallRule
 
        if(![string]::IsNullOrEmpty($firewallSetting)) {
            if($firewallSetting.DisplayName -eq $fwSqlUdpRule) {
                $Global:resultlog = $Global:resultlog + "INFO: Firewall rule " + $fwSqlUdpRule + " found.`n"
                if($firewallSetting.Enabled -eq "True" -and $firewallSetting.Direction -eq $InboundDirection) {
                    $Global:resultlog = $Global:resultlog + "INFO: Firewall rule " + $fwSqlUdpRule + " configured properly.`n"
                } else {
                    $Global:resultlog = $Global:resultlog + "ERROR: Firewall rule " + $fwSqlUdpRule + " not configured properly.`n"
                }
            } else {
                $Global:resultlog = $Global:resultlog + "Error: Firewall rule " + $fwSqlUdpRule + " not found.`n"
            }
        } else{
            $Global:resultlog = $Global:resultlog + "Error: Firewall rule for " + $udp + " protocol and port " + $udpPortNo + " not found.`n"
        }
 
        #To check sqlsserverexe firewall rule
        $firewallSetting = Get-NetFirewallRule |
            Where-Object { $_.DisplayName -eq $fwSqlExeRule} | Get-NetFirewallApplicationFilter
 
        if(![string]::IsNullOrEmpty($firewallSetting)) {
            $Global:resultlog = $Global:resultlog + "INFO: Firewall rule " + $fwSqlExeRule + " found.`n"
            if([System.IO.File]::Exists($firewallSetting.Program)) {
                $Global:resultlog = $Global:resultlog + "INFO: " + $firewallSetting.Program + " exists.`n"
            } else {
                $Global:resultlog = $Global:resultlog + "ERROR: " + $firewallSetting.Program + " does not exists.`n"
            }
        } else {
            $Global:resultlog = $Global:resultlog + "ERROR: Firewall rule " + $fwSqlExeRule + " not found.`n"
        }
 
        #To check sqlbrowserexe firewall rule
        $firewallSetting = Get-NetFirewallRule |
            Where-Object { $_.DisplayName -eq $fwSqlBrowserExeRule} | Get-NetFirewallApplicationFilter
        if(![string]::IsNullOrEmpty($firewallSetting)) {
            $Global:resultlog = $Global:resultlog + "INFO: Firewall rule " + $fwSqlBrowserExeRule + " found.`n"
            if([System.IO.File]::Exists($firewallSetting.Program)) {
                $Global:resultlog = $Global:resultlog + "INFO: " + $firewallSetting.Program + " exists.`n"
            } else {
                $Global:resultlog = $Global:resultlog + "ERROR: " + $firewallSetting.Program + " does not exists.`n"
            }
        } else {
            $Global:resultlog = $Global:resultlog + "Error: Firewall rule " + $fwSqlBrowserExeRule + " not found.`n"
        }
 
    }catch{
        $Global:resultlog = $Global:resultlog + "ERROR: An error occurred: $($_.Exception.Message)`n"
    }
}

#get hostname and timestamp
Function getHostNameandTimestamp()
{
    #get the hostname
    $hostname = $env:COMPUTERNAME
    $Global:resultlog = $Global:resultlog + "Hostname:" + $hostname + "`n"

    #get the local date and time
    $currentTimeStamp = Get-Date
    $Global:resultlog = $Global:resultlog + "TimeStamp:" + $currentTimeStamp.ToString("yyyy-MM-dd HH:mm:ss") + "`n"

    #get OS name and version
    $osName = (Get-WmiObject Win32_OperatingSystem).Caption
    $osVersion = (Get-WmiObject Win32_OperatingSystem).Version

    $Global:resultlog = $Global:resultlog + "osName:" + $osName + "`n"

    $Global:resultlog = $Global:resultlog + "osVersion:" + $osVersion + "`n"
}


#function calls to execute the validation
Function FunctionalValidation()
{
    $Global:resultlog = $Global:resultlog + "*************************Start Validation*****************************`n"
    getHostNameandTimestamp
    $Global:resultlog = $Global:resultlog + "`n*********************Files-Dll validation*****************************`n"
    #Execution of the functions
    validateDlls
    validateEnvFile
    $Global:resultlog = $Global:resultlog + "`n*************Firewall settings and rules validation*******************`n"
    checkFirewallSettings
    ValidateFirewallRules
    $Global:resultlog = $Global:resultlog + "`n*********************Softwares and config validation******************`n"
    ValidateVcRedist
    checkServiceRegistry
    validateSqlServer
    validateSqlServerVersion
    ValidateSqlServerLocalDb
    ValidateDocker
    ValidateCDFPackage
    $Global:resultlog = $Global:resultlog + "`n*****************************End***************************************"

}

#Function call
FunctionalValidation
createAndUploadLog
