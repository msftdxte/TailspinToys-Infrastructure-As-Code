$sqldbserverName = "tailspintoysdbserver"
$sqldbName = "tailspintoysdb"

$sqldbUser = "msftdxte"
$sqldbUserPassword = "Build@123"

function Invoke-SQL {
    param(
        [string] $mySqlCommand = $(throw "Please specify a query."),
        [string] $mySqlDbserverName = $(throw "Please specify a sqldbserverName."),
        [string] $mySqlDbName = $(throw "Please specify a sqldbName."),
        [string] $mySqlDbUser = $(throw "Please specify a sqldbUser."),
        [string] $mySqlDbPassword = $(throw "Please specify a sqldbUserPassword.")
      )

    $connectionString = "Server=tcp:$mySqlDbserverName.database.windows.net,1433;Database=$mySqlDbName;User ID=$mySqlDbUser@$mySqlDbserverName;Password=$mySqlDbPassword;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;"


    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($mySqlCommand,$connection)
    $connection.Open()

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null

    $connection.Close()
    $dataSet.Tables #| ft -AutoSize
}

$query = "select top 120 * from sys.dm_db_resource_stats order by end_time desc"
#$query = "select @@version"


# call function
$result = Invoke-SQL -mySqlCommand $query -mySqlDbserverName $sqldbserverName -mySqlDbName $sqldbName -mySqlDbUser $sqldbUser -mySqlDbPassword $sqldbUserPassword

$scaleUpLine = 80 # 80 % of a ressource

for ($i=0; $i -lt $result.Rows.Count;$i++)
{
Write-Host "Row: $i"
    if (
        $result.Rows[$i].avg_cpu_percent -gt $scaleUpLine -or
        $result.Rows[$i].avg_data_io_percent -gt $scaleUpLine -or
        $result.Rows[$i].avg_log_write_percent -gt $scaleUpLine -or
        $result.Rows[$i].avg_memory_usage_percent -gt $scaleUpLine)
    {
        Write-Output "we have to scale..."
    }
    else
    {
        Write-Output "we are fine"
        Write-Output $result.Rows[$i]
        Start-Sleep -Seconds 5
    }
}
