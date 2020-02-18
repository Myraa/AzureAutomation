<#
.SYNOPSIS
   Remove blobs older than X days old in one container in a storage account.
.DESCRIPTION 
   This script will run through a container in a single Azure storage account and delete all blobs older than X days.

.EXAMPLE
    .\Remove-BlobsXDaysOld.ps1 -ResourceGroupName "resourcegroupname" -StorageAccountName "storageaccountname" -StorageContainer "storagecontainer" -DaysOld 30
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # Resource Group name for StorageAccount
    [Parameter(Mandatory = $true)] 
    [string]$ResourceGroupName,

    # StorageAccount name for BLOB deletion
    [Parameter(Mandatory = $true)] 
    [string]$StorageAccountName,

    # Remove blobs from specified container.
    [Parameter(Mandatory = $true)]
    [string]$StorageContainer,

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

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Context
$blobs = Get-AzureStorageBlob -Container "$StorageContainer" -Context $saContext

$compareDate = (Get-Date).AddDays(-$DaysOld)
Write-Output ("Removing blobs modified before {0}." -f $compareDate)
if ($blobs -ne $null)
{
    $blobsremovedincontainer = 0
    foreach ($blob in $blobs)
    {
        $lastModified = $blob.LastModified
        if ($lastModified -ne $null)
        {
            if ($lastModified.DateTime -lt $compareDate)
            {
                Remove-AzureStorageBlob -Blob $blob.Name -Container "$StorageContainer" -Context $saContext
                $blobsremovedincontainer += 1
            }
        }
    }

    Write-Output ("{0} blobs removed from container {1}." -f $blobsremovedincontainer, $StorageContainer)
}
