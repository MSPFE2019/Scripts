#region Parameters
#url https://yourdomain-admin.sharepoint.com
$URL="https://gov210-admin.sharepoint.com"  
#endregion Parameters

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
  Connect-PnPOnline -Url $site.URL -cred o365
##Remove Everyone Except External Users 
  Remove-PnPUser -Identity "Everyone except external users" -Confirm:$false
  write-host -ForegroundColor Green "Removing Everyone except external users from: " $site.Url  

##Remove Everyone 
  Remove-PnPUser -Identity "Everyone" -Confirm:$false
  write-host -ForegroundColor Green "Removing Everyone from: " $site.Url  
  }
