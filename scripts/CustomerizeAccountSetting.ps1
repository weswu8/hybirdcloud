<#
      .DESCRIPTION
           Custermize the SQL server for the demokits
	  .EXAMPLE
	       powershell.exe -ExecutionPolicy RemoteSigned -Command c:\CustomerizeAccountSetting.ps1 /
		   -AdminPassword "Password123" -DomainDNSName "example.com"  -DomainNetBIOSName "example"  /
		   -DomainAdminUser "StackAdmin"  -DomainAdminPassword "Password123"  -ServiceName "MSSQLSERVER"  /
		   -AD1PrivateIp "10.0.0.10"  -AD2PrivateIp "10.0.64.10"
      .NOTES
           AUTHOR:    Wesely Wu
           CREATED:   July, 2015
           VERSION:   1.0.0
		   changelog: 2015.06.28 add the network connection check function

#> 
Param(
    [string]$DomainDNSName,
    [string]$DomainNetBIOSName,
    [string]$DomainAdminUser,
    [string]$DomainAdminPassword,
    [string]$ServiceName,
	[string]$ServerBIOSName,
	[string]$TargetHost
)
# check the network connection
Function TestNetworkConnection ($ServerBIOSName,$TargetHost)
{
    if (!([string]::IsNullOrEmpty($TargetHost)))
	{
	    do {
            #Write-Host "waiting..."
            sleep 10      
        } until(Test-NetConnection $TargetHost -Port 53 | ? { $_.TcpTestSucceeded } )
	}
}
# change password for sa and Resume the database mirroring relationship
Function ChangePasswordAndResumeTheMirroring ($DomainAdminPassword,$ServerBIOSName)
{
    <# TODO change the password
    if (!($DomainAdminPassword -eq "Password123"))
	{
	    $SQLServer = New-Object Add-Type -path 'C:\Program Files\Microsoft SQL Server\110\SDK\Assemblies\Microsoft.SqlServer.Smo.dll' $ServerBIOSName
        $SQLServer.Logins.Item('sa').ChangePassword($DomainAdminPassword)
        $SQLServer.Logins.Item('sa').Alter()
        write-output "111"
	}
    #>
	if ($ServerBIOSName -eq "SQL1")
	{
        $user = "sa"
        $database = "master"
        $sqladminPassword = "Password123"  # TODO change this way
        $connectionString = "Server=$ServerBIOSName;uid=$user; pwd=$sqladminPassword;Database=$database;Integrated Security=False;"
        #$query = "ALTER DATABASE amadb SET PARTNER SUSPEND;"
        $query1 = "ALTER DATABASE amadb SET PARTNER RESUME;"
		$query2 = "ALTER DATABASE WSS_Content SET PARTNER RESUME;"

        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()

        $command1 = $connection.CreateCommand()		
        $command1.CommandText  = $query1
        $result1 = $command1.ExecuteReader()
        $result1.Close()
		$command1.Dispose()
        
        $command2 = $connection.CreateCommand()		
        $command2.CommandText  = $query2
        $result2 = $command2.ExecuteReader()
        $result2.Close()
        $command2.Dispose();
		
        $connection.Close()
	}
}

# change the SharePoint features
Function ChangeSPFeatures ($DomainAccout,$DomainAdminPassword,$ServerBIOSName)
{
  	if ($ServerBIOSName -eq "SP1")
	{
        # Download the file
        $client = New-Object system.net.WebClient
		$client.DownloadFile("https://s3-ap-southeast-1.amazonaws.com/aws-demokits/softwares/PsExec.exe","C:\\PsExec.exe")
		$client.DownloadFile("https://s3-ap-southeast-1.amazonaws.com/aws-demokits/scripts/ChangeSPFeatures.ps1","C:\\ChangeSPFeatures.ps1")
		$client.DownloadFile("https://s3-ap-southeast-1.amazonaws.com/aws-demokits/scripts/CSPF.bat","C:\\CSPF.bat")
		# invoke the command
        Start-Sleep -Seconds 5
		C:\PsExec.exe \\$ServerBIOSName -u $DomainAccout -p $DomainAdminPassword "C:\CSPF.bat"
	}
}

#check the network connection with DNS
#TestNetworkConnection $ServerBIOSName $TargetHost

$DomainAccout = $DomainNetBIOSName + '\' + $DomainAdminUser
#Write-Output $DomainAccout

# Refresh the domain membership
if ((gwmi win32_computersystem).partofdomain -eq $true) {
    if (!([string]::IsNullOrEmpty($ServiceName)) -and !($DomainAdminPassword -eq "Password123"))
	{
        $service="name='" + $ServiceName + "'"
        $svc=gwmi win32_service -filter $service
        $svc.StopService()
        $svc.change($null,$null,$null,$null,$null,$null,$DomainAccout,$DomainAdminPassword,$null,$null,$null)
        $svc.StartService()
		Start-Sleep -Seconds 60		
    }
	ChangePasswordAndResumeTheMirroring $DomainAdminPassword $ServerBIOSName
	ChangeSPFeatures $DomainAccout $DomainAdminPassword $ServerBIOSName
} else {
    #Remove-Computer  -Credential (New-Object System.Management.Automation.PSCredential($DomainAccout,(ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force))) -Force
    Add-Computer -DomainName $DomainDNSName -Credential (New-Object System.Management.Automation.PSCredential($DomainAccout,(ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force))) -Force -Restart
}