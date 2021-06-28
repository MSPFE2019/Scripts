#Function to Import Files from Fileshare to SharePoint Online

Function Import-FileShareToSPO
{
 param
    (
        [Parameter(Mandatory=$true)] [string] $SiteURL,
        [Parameter(Mandatory=$true)] [string] $SourceFolderPath,
        [Parameter(Mandatory=$true)] [string] $ListName,            
        [Parameter(Mandatory=$true)] [string] $LogFile
    )
 
    Try {
        Add-content $Logfile -value "`n---------------------- Import Files Script Started: $(Get-date -format 'dd/MM/yyy hh:mm:ss tt')-------------------"  
        #Connect to PnP Online
        Connect-PnPOnline -Url $SiteURL -Useweblogin
 
        #Get Number of Source Items in the source
        $SourceItemsCount =  (Get-ChildItem -Path $SourceFolderPath -Recurse -Force).count 
 
        #Get the Target List to Upload
        $Web = Get-PnPWeb
        $List = Get-PnPList -Identity $ListName
        Write-Host $ListName
        $ListName = [RegEx]::Replace($ListName, "[{0}]" -f ([RegEx]::Escape([String]'\$#"*:<>?/\|')), '') 
        Write-Host "New List Name: " $ListName
        If($List -eq $null)
        
        {
        
        $List = New-PnPList -Title $ListName -Template DocumentLibrary        
        }
        $List = Get-PnPList $ListName -Includes RootFolder

        
        
        $TargetFolder = $List.RootFolder
        $TargetFolderSiteRelativeURL = $TargetFolder.ServerRelativeURL.Replace($Web.ServerRelativeUrl,"") 
  
        #Get All Items from the Source
        $SourceItems = Get-ChildItem -Path $SourceFolderPath -Recurse -Force
        $Source = @($SourceItems | Select FullName, Name, PSIsContainer, @{Label='TargetItemURL';Expression={$_.FullName.Replace($SourceFolderPath,$TargetFolderSiteRelativeURL).Replace("\","/")}})
     
        #Get All Files from the target document library - In batches of 2000
        $TargetFiles = Get-PnPListItem -List $ListName -PageSize 2000
        $Target = @($TargetFiles | Select @{Label='TargetItemURL';Expression={$_.FieldValues.FileRef.Replace($Web.ServerRelativeUrl,"")}},
                            @{Label='FullName';Expression={$_.FieldValues.FileRef.Replace($TargetFolder.ServerRelativeURL,$SourceFolderPath).Replace("/","\")}},
                                @{Label='PSIsContainer';Expression={$_.FileSystemObjectType -eq "Folder"}})

        #Compare Source and Target and upload files which are not in the target
        $Counter = 1
        $FilesDiff = Compare-Object -ReferenceObject $Source -DifferenceObject $Target -Property FullName, TargetItemURL, PSIsContainer,Name
        $FilesDiff = @($FilesDiff | Where {$_.SideIndicator -eq "<="})
        $FilesDiffCount = $FilesDiff.Count
 
        #Check if Source Folder Items count and Target Folder Items count are different
        If($FilesDiffCount -gt 0)
        {
            Write-host "Found difference between Source and Target! Source: $SourceItemsCount Target: $($List.Itemcount)"
            Add-content $Logfile -value "Found difference between Source and Target! Source: $SourceItemsCount Target: $($List.Itemcount)" 
     
            $FilesDiff | ForEach-Object {
                #Calculate Target Folder URL for the file
                $TargetFolderURL = (Split-Path $_.TargetItemURL -Parent).Replace("\","/").TrimStart("/")
                $TargetFolderURL =  [RegEx]::Replace($TargetFolderURL, "[{0}]" -f ([RegEx]::Escape([String]'\%$#"*:<>?|')), '_')
                
                #Replace Invalid Characters
                $ItemName = [RegEx]::Replace($ItemName, "[{0}]" -f ([RegEx]::Escape([String]'\%$#"*:<>?/\|')), '_') 
                 $FileName =  [RegEx]::Replace($FileName, "[{0}]" -f ([RegEx]::Escape([String]'\%$#"*:<>?/\|')), '_') 
                
                #Display Progress bar
                $Status  = "Importing '" + $ItemName + "' to " + $TargetFolderURL +" ($($Counter) of $($FilesDiffCount))"
                Write-Progress -Activity "Uploading ..." -Status $Status -PercentComplete (($Counter / $FilesDiffCount) * 100)

                If($_.PSIsContainer)
                {
                    #Ensure Folder
                    $Folder  = Resolve-PnPFolder -SiteRelativePath ($TargetFolderURL+"/"+$ItemName)
                    Write-host "Created Folder '$($ItemName)' to Folder $TargetFolderURL"
                    Add-content $Logfile -value "Ensured Folder '$($ItemName)' to Folder $TargetFolderURL"
                }
                Else
                {
                    #Upload File

                    #This fixes the Name, it remove all these characters $%#"*:<>?| and replace with nospace
                    $newName  = [RegEx]::Replace($_.Name , "[{0}]" -f ([RegEx]::Escape([String]'$%#"*:<>?|')), '') 
                   Write-host $newName 
                   $File  = Add-PnPFile -Path $_.FullName -Folder $TargetFolderURL -NewFileName $NewName 
                    Write-host "Uploaded File '$($_.FullName)' to Folder $TargetFolderURL"
                    Add-content $Logfile -value "Ensured File '$($_.FullName)' to Folder $TargetFolderURL"
                }
                $Counter++
            }
        }
        Else
        {
            Write-host "Found no difference between Source and Target! Source: $SourceItemsCount Target: $($List.Itemcount)"
            Add-content $Logfile -value "Found no difference between Source and Target! Source: $SourceItemsCount Target: $($List.Itemcount)"
        }
    }
    Catch {
        Write-host -f Red "Error:" $_.Exception.Message 
        Add-content $Logfile -value "Error:$($_.Exception.Message)"
    }
    Finally {
       Add-content $Logfile -value "---------------------- Import Files Script Completed: $(Get-date -format 'dd/MM/yyy hh:mm:ss tt')-----------------"
    } 
}

$sitelist = Get-ChildItem -Path "C:\source\$dsites\" -Force |?{ $_.PSIsContainer }
foreach ($dsites in $sitelist)
{
    Write-Host "Creating Document Libraries on " $dsites

   $xSourceItems = Get-ChildItem -Path "C:\source\$dsites\" -Force |?{ $_.PSIsContainer }
    ForEach($folder in $xSourceItems)
            {
                #$files = Get-ChildItem -Path "C:\source\$dsites\$folder" -Force -Recurse |?{ $_.PSIsContainer }
                Write-Host "Document Library" $folder " has been located"
                Write-Host "Copying has started"
                Import-FileShareToSPO -SiteURL https://x013550.sharepoint.com/sites/$dsites/ -SourceFolderPath "C:\Source\$dsites\$folder" -ListName $folder -LogFile "C:\Source\Reports-LOG.log"
            }     
}
