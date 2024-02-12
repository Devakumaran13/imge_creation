
#common Variables Json file location
$jsonCommonVariablesPath ='Common/Variables.json'
$result = 'true'

#Function for Deleting ImageVersions
#if morethan 3 versions exists for each image defination under image gallery
Function  DeleteImageVersions($path) 
{
 try {
        #Read common variable file
        $jsonContent = Get-Content -Path $path -Raw | ConvertFrom-Json
        $resource_group = $jsonContent.resource_group_name
        $gallery_names = $jsonContent.image_gallery_names.split(",")

        Write-Host "print rgname - $resource_group"
        foreach ($gallery_name in $gallery_names) 
        {
                #Print image gallery name
                Write-Host "An image gallery name: '$gallery_name'"

                #Get the image definations in $gallery_name.
                $get_gallery_image_definations = az sig image-definition list --gallery-name "$gallery_name" --resource-group "$resource_group"
                $image_definations = $get_gallery_image_definations | ConvertFrom-Json
                $image_defs = $image_definations.name
                
                #loop through image defination names
                foreach ($image_def in $image_defs) 
                {
                        #Print image defination name
                        Write-Host "An image defination name: '$image_def'"

                        #Get the image version of image defination in $image_def.
                        $get_image_versions = az sig image-version list --gallery-image-definition="$image_def" --gallery-name="$gallery_name" --resource-group="$resource_group" | ConvertFrom-Json
                        $version_names = $get_image_versions.name
                        $versions_count = $get_image_versions.count

                        #Print image defination versions count
                        Write-Host "The '$image_def' image defination total image version(s): '$versions_count'."

                        #check image defination having morethen 3 versions
                        if ( $versions_count -gt 3 ) 
                        {
                        #versionNames array
                        $versionNamesAry = [System.Collections.ArrayList]@()

                        #Add items in versionNames array
                        foreach ($item in $version_names) { $versionNamesAry.Add($item) }

                        #Sorting Image versions in ascending order
                        $versionNames = $versionNamesAry | Sort-Object { $_ -as [version]  }

                        $counter = 0
                        #loop through image version names
                        foreach ($versionName in $versionNames) 
                        {
                                #exits the loop before reaching to latest 3 versions
                                if($versions_count -eq ($counter+3)){ break }

                                Write-Host "Deleting an image defination '$image_def' version : '$versionName'"
                                #Deleting the image version
                                az sig image-version delete --resource-group "$resource_group" --gallery-name "$gallery_name" --gallery-image-definition "$image_def" --gallery-image-version "$versionName"
                                $counter++       
                        }

                        Write-Host "The '$image_def' image defination has been cleaned-up."
                        }    
                        else { 
                        Write-Host "The image clean-up is not required for '$image_def' image defination."
                        }
                }
        }
 }
 catch 
 {
    Write-Host "An error occurred: $($_.Exception.Message)"
    $result = 'false'
    return $result
 }
  
 return $result
}

$output = DeleteImageVersions($jsonCommonVariablesPath)
if($output-eq 'false') { exit 1 }
