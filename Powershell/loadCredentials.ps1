$username = "azureautomation@msftdxteoutlook.onmicrosoft.com"
$pass = Get-Content "C:\temp\securestring-$username.txt" | convertto-securestring
$mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username,$pass

Add-AzureAccount -Credential $mycred