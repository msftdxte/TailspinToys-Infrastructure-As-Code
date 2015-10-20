$username = "azureautomation@msftdxteoutlook.onmicrosoft.com"
$pass = Get-Content "C:\temp\securestring-$username.txt" | convertto-securestring

$mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username,$pass

Add-AzureAccount -Credential $mycred

$sqldbserverName = "tailspintoysdbserver"
$sqldbName = "msftdxte@tailspintoysdbserver"

$sqldbUser = "msftdxte@tailspintoysdbserver"
$sqldbUserPassword = "Build@123"

function Invoke-SQL {
    param(
        [string] $sqlCommand = $(throw "Please specify a query."),
        [string] $sqldbserverName = $(throw "Please specify a sqldbserverName."),
        [string] $sqldbUser = $(throw "Please specify a sqldbUser."),
        [string] $sqldbUserPassword = $(throw "Please specify a sqldbUserPassword.")
      )

    $connectionString = "Server=tcp:$sqldbserverName.database.windows.net,1433;Database=$sqldbName;User ID=$sqldbUser@$sqldbserverName;Password=$mypassword;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;"


    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null

    $connection.Close()
    $dataSet.Tables | ft -AutoSize

}



# call function
Invoke-SQL -sqlCommand "select top 1 * from sys.dm_db_resource_stats order by end_time desc"



# get all sql azure db server listed
$dbservers = @(Get-AzureSqlDatabaseServer)
# result: bbqjj59bc6 


foreach ($dbserver in $dbservers)
{
    $sqldbName = $dbserver.ServerName
    $sqldbUser = $dbserver.AdministratorLogin

    $sqlServerContext = New-AzureSqlDatabaseServerContext -ServerName $dbserver -UseSubscription

    Start-Sleep -Seconds 1

    # get all DBs from Server
    Get-AzureSqlDatabase $sqlServerContext | select Name,Edition, ServiceObjectiveName,ServiceObjectiveAssignmentStateDescription, MaxSizeGB| ft -AutoSize

    Write-Host
    $database = Read-Host "Choose your Database on"

    $db = Get-AzureSqlDatabase $sqlServerContext -DatabaseName $database

    $perflevel = Read-Host "Choose your new Database Performance Level: (Basic, S0, S1, S2, P1, P2, P3)"

    # define a Premium performance level for the Database
    $performanceLevel = Get-AzureSqlDatabaseServiceObjective $sqlServerContext -ServiceObjectiveName $perflevel  # set value to "P1 or P2 or P3"

    # set the db performance Level to current db
    switch -wildcard ($performanceLevel.Description) 
        { 
            "*Basic*"    { Set-AzureSqlDatabase $sqlServerContext –Database $db –ServiceObjective $performanceLevel –Edition Basic -Force
                          Write-Output "setup to basic"
                        } 
            "*Standard*" { Set-AzureSqlDatabase $sqlServerContext –Database $db –ServiceObjective $performanceLevel –Edition Standard -Force 
                          Write-Output "setup to standard"
                        }
            "*Premium*"  { Set-AzureSqlDatabase $sqlServerContext –Database $db –ServiceObjective $performanceLevel –Edition Premium -Force 
                          Write-Output "setup to premium"
                        }
        }

    Write-Host
    Write-Host "new performance level"
    $status = Get-AzureSqlDatabase $sqlServerContext -DatabaseName $database 

    write-host "operation status is " $status.ServiceObjectiveAssignmentStateDescription.ToString()

    while ($status.ServiceObjectiveAssignmentStateDescription -eq 'Pending')
    {
        $status = Get-AzureSqlDatabase $sqlServerContext -DatabaseName $database 
        $time = get-date

        write-host "operation status is: " $status.ServiceObjectiveAssignmentStateDescription.ToString() " - " $time.ToLongTimeString()
    
    }
    Get-AzureSqlDatabase $sqlServerContext -DatabaseName $database | select Name,Edition, ServiceObjectiveName,ServiceObjectiveAssignmentStateDescription, MaxSizeGB| ft -AutoSize
}