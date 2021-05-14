
#### 
###Run this on the server that will remove the script
####Add-PnPStoredCredential -Name "https://tenant.sharepoint.com" -Username yourname@tenant.onmicrosoft.com -Password (ConvertTo-SecureString -String "YourPassword" -AsPlainText -Force)

#region Parameters
#url https://yourdomain-admin.sharepoint.com
$URL='https://GOV210645-admin.sharepoint.com' 
$group = 'JohannaL@GOV210645.OnMicrosoft.com'

#endregion Parameters

#region Credentials

# region Get Site Collecions   
Connect-PnPOnline -Url $URL -cred o365
## Powershell will prompt for sign
## Copy Url from msg and code
## Consent form only click ok, don't consent for entire org

# Get the site collections  
$siteColl=Get-PnPTenantSite  
#endregion Get Site Collecions

# Loop through the site collections  
foreach($site in $siteColl)  
{  
  Connect-PnPOnline -Url $site.URL  -Credentials o365
  
  Start-Sleep -Seconds 10

Set-PnPTenantSite -identity $site.URL -Owners $group

$FormatEnumerationLimit=-1
$perm = Get-PnPUser -withrightsAssignedDetailed | where {$_.Title.Startswith('Diego')}
$Perm = [pscustomobject]@{'Title' = $perm.Title; 'Groups' = $perm.Groups; 'Permissions' = $perm.Permissions}
$perm | Select Title, @{Name ='Groups';expression={[string]::join(";",($_.Groups))}}, @{Name ='Permissions';expression={[string]::join(";",($_.Permissions))}}| Export-Csv -Path PermFile.csv -Append -force 
$perm
Get-PnPTenantSite -Identity $site.url 
  write-host -ForegroundColor Green "Working on " $site.Url
  Start-Sleep -Seconds 10
#Get-PnPUser | ? Title -like $group | Remove-PnPSiteCollectionAdmin


}  


Get-PnPTenantSite | ForEach-Object {
   $site = $_
   Write-Host "Processing $($site.Url)..."
   Connect-PnPOnline $site.Url -Credentials o365
   Get-PnPUser | ? Email -like $group | Remove-PnPSiteCollectionAdmin
   Get-PnPSiteCollectionAdmin
}