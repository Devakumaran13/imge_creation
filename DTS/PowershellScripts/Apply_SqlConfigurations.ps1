Import-Module sqlps

# Load the assemblies
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")

Function EnableServerNProtocols() 
{
    # #Enable a server network protocol 
    $instanceName = 'SQLEXPRESS'
    $smo = 'Microsoft.SqlServer.Management.Smo.'
    $wmi = new-object ($smo + 'Wmi.ManagedComputer').
    
    # # List the object properties, including the instance names.
    $Wmi
    
    # # Enable the TCP protocol on the default instance.
    $uri = "ManagedComputer[@Name='" + (get-item env:\computername).Value + "']/ ServerInstance[@Name='$instanceName']/ServerProtocol[@Name='Tcp']"
    $Tcp = $wmi.GetSmoObject($uri)
    $Tcp.IsEnabled = $true
    $Tcp.Alter()
    $Tcp
    
    # # Enable the named pipes protocol for the default instance.
    $uri = "ManagedComputer[@Name='" + (get-item env:\computername).Value + "']/ ServerInstance[@Name='$instanceName']/ServerProtocol[@Name='Np']"
    $Np = $wmi.GetSmoObject($uri)
    $Np.IsEnabled = $true
    $Np.Alter()
    $Np
    
    # #Update TCP Dynamic Port & TCP Port details.
    $instanceName = 'SQLEXPRESS' #Specify the instance name. For default instance, use MSSQLSERVER.
    $smo = 'Microsoft.SqlServer.Management.Smo.'
    $wmi = New-Object ($smo + 'Wmi.ManagedComputer')
    
    # # For the named instance, on the current computer, for the TCP protocol,
    # # loop through all the IPs and configure them to use the standard port
    # # of 1433.
    $uri = "ManagedComputer[@Name='" + (get-item env:\computername).Value + "']/ ServerInstance[@Name='$instanceName']/ServerProtocol[@Name='Tcp']"
    $Tcp = $wmi.GetSmoObject($uri)
    foreach ($ipAddress in $Tcp.IPAddresses)
    {
        $ipAddress.IPAddressProperties["TcpDynamicPorts"].Value = ""
         $ipAddress.IPAddressProperties["TcpPort"].Value = "1433"  #Specify the SQL port number to set 
         Write-Output "SQL Server static port updated"
    }
    $Tcp.Alter()
}

Function StartSQLBrowserService() 
{
    # Start the sqlbrowser service
    Set-Service 'sqlbrowser' -StartupType Automatic
    Start-Service -Name 'sqlbrowser'
}

Function SetupFirewallRules() 
{
    #Creating the firewall rules
    New-NetFirewallRule -DisplayName "SQL sqlservr.exe" -Direction Inbound -Program "C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\Binn\sqlservr.exe" -RemoteAddress LocalSubnet -Action Allow -Profile Domain,Private,Public
    New-NetFirewallRule -DisplayName "SQL sqlbrowser.exe" -Direction Inbound -Program "C:\Program Files (x86)\Microsoft SQL Server\90\Shared\sqlbrowser.exe" -RemoteAddress LocalSubnet -Action Allow -Profile Domain,Private,Public
    
    New-NetFirewallRule -DisplayName "SQL TCP 1433" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow -Profile Domain,Private,Public
    New-NetFirewallRule -DisplayName "SQL UDP 1434" -Direction Inbound -LocalPort 1434 -Protocol UDP -Action Allow -Profile Domain,Private,Public
    
    #Disable windows firewall
    Set-NetFirewallProfile -Profile Domain -Enabled False
    Set-NetFirewallProfile -Profile Public -Enabled False
    Set-NetFirewallProfile -Profile Private -Enabled False
}

EnableServerNProtocols
StartSQLBrowserService
SetupFirewallRules
