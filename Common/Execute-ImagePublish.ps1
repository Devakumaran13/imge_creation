	param(
    $app,
    $client_id,
    $subscription_id,
    $tenent_id,
    $run_Id
   )
   
$subscriptionId = $subscription_id
$tenentid =$tenent_id
$clientid = $client_id
$imageUrl = ""

#common Variables Json file location
$jsonCommonVariablesPath ='Common/Variables.json'

# Specify the path to your JSON file
$jsonVariablesPath = $app+'/Packer/Variables.json'
$result = 'true'

#Image publish function
Function  PublishImage($path) {
 try {
        #Read Common Variable
        $jsonCommonContent = Get-Content -Path $jsonCommonVariablesPath -Raw | ConvertFrom-Json
        $az_portal_uri = $jsonCommonContent.az_portal_uri

        #Read Variable file
        $jsonContent = Get-Content -Path $jsonVariablesPath -Raw
        $jsonContent = $jsonContent | ConvertFrom-Json

        $resource_group = $jsonContent.resource_group_name
        $gallery_name = $jsonContent.image_gallery_name
        $image_def = $jsonContent.image_definition
        $image_ver = $jsonContent.image_version
        $image_name = $jsonContent.vm_name
        $image_region = $jsonContent.region
        $resourceGrp = $jsonContent.resource_group_name
        $publisher = $jsonContent.publisher
        $offer = $jsonContent.offer
        $sku = $jsonContent.sku
        $os_type = $jsonContent.os_type

        #Check Image-definition is exists in gallery
        #Get the image definations by gallery-name.
        $image_def_exists = 'false'
        $get_gallery_image_definations = az sig image-definition list --gallery-name "$gallery_name" --resource-group "$resource_group"
        $image_definations = $get_gallery_image_definations | ConvertFrom-Json
        $image_defes = $image_definations.name
        foreach ($image_defe in $image_defes) 
        {
            if($image_defe -eq $image_def){ 
                $image_def_exists = 'true'
                break;
            }
        }

        #Create Image-definition
        if($image_def_exists -eq 'false'){
            $rand = Get-Random -Minimum -100000 -Maximum 999999
	        $publisher = $publisher+"_"+$rand
            az sig image-definition create --resource-group "$resource_group" --gallery-name "$gallery_name" --gallery-image-definition "$image_def" --publisher "$publisher" --offer "$offer" --sku "$sku" --os-type "$os_type"
        }

        #Get Image versions list by image-defination, gallery-name and rg
        $get_versions = az sig image-version list --gallery-image-definition="$image_def" --gallery-name="$gallery_name" --resource-group="$resource_group" | ConvertFrom-Json
        $new_ver = '1.0.0'

        if ( $get_versions.count -gt 0 ) 
        {
            #init versionNames array
            $versionNamesAry = [System.Collections.ArrayList]@()
            #Add items in versionNames array
            foreach ($item in $get_versions.name) { $versionNamesAry.Add($item) }

            #Sorting Image versions in ascending order
            $LatestVersion = $versionNamesAry | Sort-Object { $_ -as [version]  } | Select-Object -Last 1
            Write-Host "Print existing latest version - $LatestVersion"

            $lv = $LatestVersion.Split(".")
            $major_ver = $lv[0]
            $minor_ver = $lv[1]
            $build_ver = [int]($lv[2]) +1 
            $new_ver = "$major_ver.$minor_ver.$build_ver"
        }

        #managed image (VM_Name of Variable file)
        $managed_img = "/subscriptions/" + $subscriptionId + "/resourceGroups/"  + $resourceGrp + "/providers/Microsoft.Compute/images/" + $image_name
       
        Write-Host "Publish Image start"
        #Create Image version under Image-definition
        az sig image-version create --resource-group "$resource_group" --gallery-name "$gallery_name" --gallery-image-definition "$image_def" --gallery-image-version "$new_ver" --target-regions "$image_region" --managed-image "$managed_img" --tags "runId=$run_Id"
        Write-Host "Publish Image End"
       
        #Image url
        $imageUrl = "$az_portal_uri" + $subscriptionId + "/resourceGroups/"  + $resourceGrp + "/providers/Microsoft.Compute/galleries/"+ $gallery_name+"/images/"+$image_def+"/versions/"+$new_ver
        #Set output param to pass value between tasks 
        echo "ImageVersionUrl=$imageUrl" >>$env:GITHUB_OUTPUT

        #Delete managed image from rg
   	DeleteManagedImage $resource_group  $image_name
    }
 catch {
        Write-Host "An error occurred: $($_.Exception.Message)"
        $result = 'false'
        return $result
    }

    return $result
}


function DeleteManagedImage($resource_group, $imgName)
{
  try
  {
        Write-Host "rg:$resource_group, imageName:$imgName"
        $vmimages = az image list --resource-group "$resource_group" | ConvertFrom-Json

        if ($vmimages.Count -gt 0) 
        { 
            $tag_runIds = $vmimages.tags.runId
            
            foreach ($runId in $tag_runIds)
            {
                Write-Host "Inside for each Runid"
                if($runId -eq $run_Id){
                    #Delete managed image from resource group
                    az image delete --image-name "$imgName" --resource-group "$resource_group"
                    break;
                } 
            }
        }	
   }
   catch
   {
   	 Write-Host "An error occurred while deleting managed image : $($_.Exception.Message)"
   }
}

$output = PublishImage($jsonVariablesPath)
if($output-eq 'false') { exit 1 }
