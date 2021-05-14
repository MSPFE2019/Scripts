
Import-Csv .\Site.csv | ForEach-Object {
  Write-Host "Working on $($_.Url)"
  Connect-PnPOnline -Url $_.Url  -cred o365
##Remove Everyone Except External Users 
  Remove-PnPUser -Identity "Everyone except external users" -Confirm:$false
  write-host -ForegroundColor Green "Removing Everyone except external users from: " $_.Url    

##Remove Everyone 
  Remove-PnPUser -Identity "Everyone" -Confirm:$false
  write-host -ForegroundColor Green "Removing Everyone from: " $_.Url  
  }
