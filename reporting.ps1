
#### 
###Run this on the server that will remove the script
####Add-PnPStoredCredential -Name "O365" -Username yourname@tenant.onmicrosoft.com -Password (ConvertTo-SecureString -String "YourPassword" -AsPlainText -Force)


#### Add $owner to each site collection to get permission for the site collection and webs

$Owner = "JohannaL@GOV0645.OnMicrosoft.com"
#endregion Parameters

#Get all the site collections  
$siteColl=Get-PnPTenantSite  
#endregion Get Site Collecions

# Loop through the site collections  
foreach($site in $siteColl)  
{  
  Connect-PnPOnline -Url $site.URL  -Credentials o365
  
### Add $Owner to the Site Collection - Needed to get all the permissions
Set-PnPTenantSite -identity $site.URL -Owners $Owner

### Get Users Permission
##### Replace Mose with how the user name is displayed in O365
$perm = Get-PnPUser -withrightsAssignedDetailed | Where-Object {$_.Title.Startswith('Diego')}

$perm = [pscustomobject]@{'Url'= $site.url;'User' = $perm.Title;'Groups' = $perm.Groups; 'Permissions' = $perm.Permissions; }

###Export to CSV

$perm | Select-Object  Url,User, @{Name ='Groups';expression={[string]::join(";",($_.Groups))}}, @{Name ='Permissions';expression={[string]::join(";",($_.Permissions))}} | Export-Csv -Path PermFile.csv -Append -force 

write-host -ForegroundColor Green "Working on " $site.Url 
 
  #### Remove $owner from the site
  Get-PnPUser | Where-Object Email -eq $Owner | Remove-PnPUser -Confirm:$false


}  

