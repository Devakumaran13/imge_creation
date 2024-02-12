Function StartDocker()
{
  #Start Docker service & Pulling docker image during vm startup
  Start-Service docker
  &$Env:Windir\docker\docker run hello-world:nanoserver
}

Function StartSQLAtStartUp()
{
  #Adding this code to start service 
  Set-Service -Name 'MSSQL$SQLEXPRESS' -Status Running -PassThru -StartupType Automatic
}

StartDocker

StartSQLAtStartUp
