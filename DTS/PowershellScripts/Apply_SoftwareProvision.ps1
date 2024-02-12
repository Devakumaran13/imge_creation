# sequence to follow 
# vc++ should run first before sqllocaldb

$tmpFolderPath = $env:tmpFolderPath.Trim()
$sys32FolderPath = $env:sys32FolderPath.Trim()

Function SetupVCDist()
{
  try{
      #VC++ Installation Cmd
      Start-Process -Wait -FilePath $tmpFolderPath\VC_redist.x64.exe -ArgumentList '/s /v/qn' -PassThru
     } 
    catch {
        Write-Host "ERROR: An error occurred: $($_.Exception.Message)"
    }
}

Function SetupSQLLocalDB()
{
  try{
      #SQLLOCALDB MSI Installation Cmd
      cd $tmpFolderPath
      Write-Host "Installing SetupSQLLocalDB"
      Start-Process msiexec.exe -Wait -ArgumentList '/I SQLLOCALDB.MSI IACCEPTSQLLOCALDBLICENSETERMS=YES /quiet'
    } 
    catch {
        Write-Host "ERROR: An error occurred: $($_.Exception.Message)"
    }
}

Function UnzipSoftwares()
{
  try{
      #DTS.zip from the link: DTS Development Environment
      #Extraction of two DLL files
      Copy-Item -Path $tmpFolderPath\ucrtbased.dll -Destination $sys32FolderPath\ucrtbased.dll
      
      Copy-Item -Path $tmpFolderPath\vcruntime140d.dll -Destination $sys32FolderPath\vcruntime140d.dll
      
      #Copy dtsEnv.json to C:\
      Copy-Item -Path $tmpFolderPath\dtsenv.json -Destination 'C:\dtsenv.json'
      
      # # Unzip the SQLExpress setup
      Expand-Archive -LiteralPath $tmpFolderPath\SQLExpress.zip -DestinationPath $tmpFolderPath\sqlsw
      
      #Extraction of Service registry
      Expand-Archive -LiteralPath $tmpFolderPath\ServiceRegistry.zip -DestinationPath $tmpFolderPath\ServiceRegistry
      } 
      catch {
        Write-Host "ERROR: An error occurred: $($_.Exception.Message)"
    }
}

# CDFCapture Intall function
Function InstallCDF()
{
  try{
      # Unzip the CDF Control
      Expand-Archive -LiteralPath $tmpFolderPath\CDFControl.zip -DestinationPath $tmpFolderPath\CDFControl
      
      #Installation of CDF control
      Start-Process -Wait -FilePath $tmpFolderPath\CDFControl\CDFControl.exe -ArgumentList '/s /v/qn' -PassThru
    } 
    catch {
        Write-Host "ERROR: An error occurred: $($_.Exception.Message)"
    }
}

#Set up CDFCapture function
Function SetupCDFCapture() 
{
  try{
    Expand-Archive -LiteralPath $tmpFolderPath\CdfCaptureService.zip -DestinationPath $tmpFolderPath\CdfCaptureService
    Copy-Item -Path $tmpFolderPath\CdfCaptureService\x64\Release\Installers\CdfCaptureService.msi -Destination 'C:\CdfCaptureService.msi'
   } 
    catch {
        Write-Host "ERROR: An error occurred: $($_.Exception.Message)"
    }
}

#Environment Setup function
Function EnvironmentSetup() 
{
  try{
      $environment_setup = $env:environment_setup.Trim()
      mkdir C:/svcreg
      Expand-Archive -LiteralPath $tmpFolderPath\ServiceRegistry\win-x64\Citrix.Xaxd.Cloud.ServiceRegistry.2.0.25921.6306.zip -DestinationPath 'C:\svcreg\Citrix.Xaxd.Cloud.ServiceRegistry.2.0.25921.6306'
      Copy-Item -Path 'C:\svcreg\Citrix.Xaxd.Cloud.ServiceRegistry.2.0.25921.6306\Citrix.Xaxd.Cloud.ServiceRegistry.exe' -Destination 'C:\svcreg\Citrix.Xaxd.Cloud.ServiceRegistry.exe'
      $ServiceRegistryPort = 8119
      [System.Environment]::SetEnvironmentVariable('ASPNETCORE_URLS', "http://*:$ServiceRegistryPort", [System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('VIRTUAL_SITE_IDS', $environment_setup,[System.EnvironmentVariableTarget]::Machine)
      Start-Process -FilePath 'C:\svcreg\Citrix.Xaxd.Cloud.ServiceRegistry.exe' -ArgumentList '-deployment:Inmemory -environment:development' -PassThru
   } 
    catch {
        Write-Host "ERROR: An error occurred: $($_.Exception.Message)"
    }
}

#Docker Installation function
Function InstallDocker() 
{
  try{
      Install-WindowsFeature -Name Containers
      Restart-Computer -Force
      Expand-Archive $tmpFolderPath\docker-24.0.7.zip -DestinationPath $Env:Windir
      &$Env:Windir\docker\dockerd --register-service
      Start-Service docker
      &$Env:Windir\docker\docker docker --version
      Get-Service docker
   } 
  catch {
        Write-Host "ERROR: An error occurred: $($_.Exception.Message)"
    }
}

# Run SetupVCDist - # vc++ should run first before sqllocaldb
SetupVCDist

# Run SetupSQLLocalDB
SetupSQLLocalDB

# Run UnzipSoftwares
UnzipSoftwares

# Run InstallCDF
InstallCDF

# Run Setup CDFCapture
SetupCDFCapture

# Run EnvironmentSetup
EnvironmentSetup

# Run InstallDocker
InstallDocker
