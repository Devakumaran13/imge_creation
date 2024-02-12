
param(
    $app,
    $run_type,
    $subscription_id,
    $sapassword 
   )

$subscriptionId = $subscription_id
$sa_password = $sapassword

#common Variables Json file location
$jsonCommonVariablesPath ='Common/Variables.json'

#Read Common Variables
$jsonCommonContent = Get-Content -Path $jsonCommonVariablesPath -Raw | ConvertFrom-Json
$workload_names = $jsonCommonContent.workloads

# Specify the path to your JSON file
$jsonVariablesPath = $app+'/Packer/Variables.json'
$result = 'true'
$output = 'true'

$keyvault_Url = '-1'

Function  LoadAzKeyvault($path) 
{
 try {

    $az_portal_uri = $jsonCommonContent.az_portal_uri
    
    #Read workload Variables
    $jsonContent = Get-Content -Path $path -Raw | ConvertFrom-Json
    $resource_group = $jsonContent.resource_group_name
    $keyVaultName = $jsonContent.key_vault_name
    $keyname = $jsonContent.key_name

    #Un-comment this code if keyvault is same for all environments.
    # $run_types = $jsonCommonContent.run_types
    # $runtypes = $run_types.Split(",")
    # $runtype = $runtypes[0]
    
    # if($run_type.Contains($runtypes[1]))
    # {
    #     $runtype = $runtypes[1]
    # }elseif($run_type.Contains($runtypes[2]))
    # {
    #     $runtype = $runtypes[2]
    # }
    # $keyname = $runtype+"-"+$keyname

    $password = ConvertTo-SecureString $sa_password -AsPlainText -Force

    #Write secret onto Azure Keyvault.
    $secretAccessKeyID = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $keyname -SecretValue $password
    
    #Keyvault url 
    $keyvault_Url = "$az_portal_uri" + $subscriptionId + "/resourceGroups/"  + $resource_group + "/providers/Microsoft.KeyVault/vaults/"+ $keyVaultName+"/secrets"
    Write-Host "Sa password keyvault url: $keyvault_Url"
    #Set output param to pass value between tasks 
    echo "keyvaultUrl=$keyvault_Url" >>$env:GITHUB_OUTPUT
}
 catch {
        Write-Host "An error occurred: $($_.Exception.Message)"
        $result = 'false'
        return $result
 }
    return $result
}

#Execute for DTS workload
if($app.ToLower() -eq $workload_names.Split(",")[0].ToLower()){
    $output = LoadAzKeyvault($jsonVariablesPath)
}else{
    echo "keyvaultUrl=$keyvault_Url" >>$env:GITHUB_OUTPUT
}

if($output-eq 'false') { exit 1 }
