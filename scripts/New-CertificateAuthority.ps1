[CmdletBinding()]
param(
    [string]
    $Username,

    [string]
    $Password,

    [string]
    $DomainDNSName
)

<#
    Requires xAdcsDeployment DSC Resource:

    https://gallery.technet.microsoft.com/scriptcenter/xAdcsDeployment-PowerShell-cc0622fa/file/126018/1/xAdcsDeployment_0.1.0.0.zip
    https://github.com/PowerShell/xAdcsDeployment
#>

$Pass = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList "$Username@$DomainDNSName", $Pass

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = $env:COMPUTERNAME
            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration CertificateAuthority {      
    Import-DscResource -ModuleName xAdcsDeployment
       
    Node $AllNodes.NodeName
    {   
        WindowsFeature ADCS-Cert-Authority 
        { 
               Ensure = 'Present' 
               Name = 'ADCS-Cert-Authority' 
        } 
        xADCSCertificationAuthority ADCS 
        { 
            Ensure = 'Present' 
            Credential = $Credential
            CAType = 'EnterpriseRootCA' 
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority'               
        } 
        WindowsFeature ADCS-Web-Enrollment 
        { 
            Ensure = 'Present' 
            Name = 'ADCS-Web-Enrollment' 
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority' 
        } 
        WindowsFeature RSAT-ADCS 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS' 
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority' 
        } 
        WindowsFeature RSAT-ADCS-Mgmt 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS-Mgmt' 
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority' 
        } 
        xADCSWebEnrollment CertSrv 
        { 
            Ensure = 'Present' 
            Name = 'CertSrv' 
            Credential = $Credential
            DependsOn = '[WindowsFeature]ADCS-Web-Enrollment','[xADCSCertificationAuthority]ADCS' 
        }  
    }   
}  

CertificateAuthority -ConfigurationData $ConfigurationData
Start-DscConfiguration -Path .\CertificateAuthority -Wait -Verbose -Force
Get-ChildItem .\CertificateAuthority *.mof -ErrorAction SilentlyContinue | Remove-Item -Confirm:$false -ErrorAction SilentlyContinue

Get-ChildItem C:\Windows\system32\CertSrv\CertEnroll *.crt | Copy-Item -Destination c:\inetpub\wwwroot\cert.crt