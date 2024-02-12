
param(
$app,
$image_version_url,
$az_keyvault_Url

)

#common Variables Json file location
$jsonCommonVariablesPath ='Common/Variables.json'

Function  PublishArtifacts()
{
 try {
        #$PSScriptRoot
        #. .\locationofcallingfunction.ps1 - method1
        #Import-Module ./locationofcallingfunction.ps1 - method2
        #Get-Greeting "Mary" - calling function in called psfile
       #  Import-Module ./Execute-ImagePublish.ps1
       #  $imageUrl = GetImageUrl() 

       #Read Common Variables
       $jsonCommonContent = Get-Content -Path $jsonCommonVariablesPath -Raw | ConvertFrom-Json
       $contact = $jsonCommonContent.contact
       $slack_contact = $jsonCommonContent.slack_contact
       $teamdetails = $jsonCommonContent.teamdetails
       $workload_names = $jsonCommonContent.workloads

        #Code for placing Artifacts 
        $imageLocationTxt = $app+' Image (Click here)'
        $start = "<html><body><title>Deployment Summary</title>"
        $paragraphs ="<p><a href=$image_version_url>$imageLocationTxt</a></p>"
        
        if($app.ToLower() -eq $workload_names.Split(",")[0].ToLower()){
            $paragraphs +="<p><a href=$az_keyvault_Url>$app - SA Password Location (Azure Keyvault)</a></p>"
        }
     
        $paragraphs +="<p>$contact</p>"
        $paragraphs +="<p>$slack_contact</p>"
        $paragraphs +="<p>$teamdetails</p>"
        $end = "</body></html>"

        $body = $($start+""+$paragraphs+""+$end)

        mkdir WorkflowArtifact
        cd WorkflowArtifact
        echo "$body" >WorkflowArtifacts.html
        cd ..
        #Artifacts-code end
 }
 catch {
        Write-Host "An error occurred while publishing the Artifacts: $($_.Exception.Message)"
 }
}

PublishArtifacts
