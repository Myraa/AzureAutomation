<#
.SYNOPSIS
   Remove logs older than X days old in an Azure table
.DESCRIPTION 
   This script will delete logs older than X days in a single Azure table.

.EXAMPLE
    .\Remove-LogsXDaysOld.ps1 -ResourceGroupName "resourcegroupname" -StorageAccountName "storageaccountname" -StorageTableName "storagetablename" -DaysOld 30
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # Resource Group name for StorageAccount
    [Parameter(Mandatory = $true)] 
    [string]$ResourceGroupName,

    # StorageAccount name
    [Parameter(Mandatory = $true)] 
    [string]$StorageAccountName,

    # Remove blobs from specified table.
    [Parameter(Mandatory = $true)]
    [string]$StorageTableName,

    [Parameter(Mandatory = $true)] 
    [Int32]$DaysOld
    )

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

Import-Module AzureRmStorageTable

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Context
$table = Get-AzureStorageTable -Name $StorageTableName -Context $saContext

$compareDate = (Get-Date).AddDays(-$DaysOld).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

Get-AzureStorageTableRowByColumnName -table $table -columnName "time" -value "$compareDate" -operator LessThanOrEqual | Remove-AzureStorageTableRow -table $table
Get-AzureStorageTableRowByColumnName -table $table -columnName "TimeStamp" -value "$compareDate" -operator LessThanOrEqual | Remove-AzureStorageTableRow -table $table

