<#
.SYNOPSIS
    Copies a file to the primary storage of an HDInsight cluster.
.DESCRIPTION
    Copies a file from a local directory to the blob container for
    the HDInsight cluster.
.EXAMPLE
    Add-HDInsightFile -localPath "C:\temp\data.txt"
        -destinationPath "example/data/data.txt"
        -ClusterName "MyHDInsightCluster"
.EXAMPLE
    Add-HDInsightFile -localPath "C:\temp\data.txt"
        -destinationPath "example/data/data.txt"
        -ClusterName "MyHDInsightCluster"
        -Container "MyContainer"
#>

function Add-HDInsightFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        #The path to the local file.
        [Parameter(Mandatory = $true)]
        [String]$localPath,

        #The destination path and file name, relative to the root of the container.
        [Parameter(Mandatory = $true)]
        [String]$destinationPath,

        #The name of the HDInsight cluster
        [Parameter(Mandatory = $true)]
        [String]$clusterName,

        #If specified, overwrites existing files without prompting
        [Parameter(Mandatory = $false)]
        [Switch]$force
    )

    Set-StrictMode -Version 3

    # Is the Azure module installed?
    FindAzure

    # Does the local path exist?
    if (-not (Test-Path $localPath))
    {
        throw "Source path '$localPath' does not exist."
    }

    # Get the primary storage container
    $storage = GetStorage -clusterName $clusterName

    # Upload file to storage, overwriting existing files if -force was used.
    Set-AzureStorageBlobContent -File $localPath -Blob $destinationPath -force:$force `
                                -Container $storage.container `
                                -Context $storage.context
}

<#
.SYNOPSIS
    Removes files from the primary storage of an HDInsight cluster.
.DESCRIPTION
    Removes a single file, or all files with the specified prefix,
    from the blob container for the HDInsight cluster.
.EXAMPLE
    Remove-HDInsightFile -Path "example/data/data.txt"
        -clusterName "MyHDInsightCluster"
#>
function Remove-HDInsightFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        #The destination path and file name, relative to the root of the container.
        [Parameter(Mandatory = $true)]
        [String]$path,

        #The name of the HDInsight cluster
        [Parameter(Mandatory = $true)]
        [String]$clusterName
    )

    Set-StrictMode -Version 3

    # Is the Azure module installed?
    FindAzure

    # Get the storage info
    $storage = GetStorage -clusterName $clusterName

    # Remove the file
    Remove-AzureStorageBlob -Blob $path `
                            -Container $storage.container `
                            -Context $storage.context
}

<#
.SYNOPSIS
    Gets a file from HDInsight primary storage and saves it locally.
.DESCRIPTION
    Gets a file from HDInsight primary storage and saves it locally.
.EXAMPLE
    Get-HDInsightFile -remotePath "example/data/data.txt"
        -localPath "c:\myfiles\data.txt"
        -clusterName "MyHDInsightCluster"
#>
function Get-HDInsightFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        #The destination path and file name, relative to the root of the container.
        [Parameter(Mandatory = $true)]
        [String]$remotePath,

        [Parameter(Mandatory = $true)]
        [String]$localPath,

        #The name of the HDInsight cluster
        [Parameter(Mandatory = $true)]
        [String]$clusterName
    )

    Set-StrictMode -Version 3

    # Is the Azure module installed?
    FindAzure

    # Get the storage info
    $storage = GetStorage -clusterName $clusterName
    Get-AzureStorageBlobContent -Blob $remotePath -Destination $localPath `
                                -Container $storage.container `
                                -Context $storage.context
}

<#
.SYNOPSIS
    Lists files stored in the HDInsight cluster primary storage
.DESCRIPTION
    Lists files stored in the HDInsight cluster primary storage
.EXAMPLE
    Find-HDInsightFile -Path "example/data/data.txt"
        -clusterName "MyHDInsightCluster"
.EXAMPLE
    Find-HDInsightFile -Prefix "example*"
        -clusterName "MyHDInsightCluster"
#>
function Find-HDInsightFile {
[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        #The file name/path/prefix, if any
        [Parameter(Mandatory = $false)]
        [String]$path,

        #The name of the HDInsight cluster
        [Parameter(Mandatory = $true)]
        [String]$clusterName
    )

    Set-StrictMode -Version 3

    # Is the Azure module installed?
    FindAzure

    # Get storage info
    $storage = GetStorage -clusterName $clusterName
    # Get the listing
    Get-AzureStorageBlob -Blob $path `
                         -Container $storage.container `
                         -Context $storage.context
}

<#
.SYNOPSIS
    Gets all storage and keys associated with the cluster
.DESCRIPTION
    Gets all storage and keys associated with the cluster
.EXAMPLE
    Get-HDInsightStorage -clusterName "MyHDInsightCluster"

#>
function Get-HDInsightStorage {
[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        #The name of the HDInsight cluster
        [Parameter(Mandatory = $true)]
        [String]$clusterName
    )

    Set-StrictMode -Version 3

    # Is the Azure module installed?
    FindAzure

    # Labels for formatted list
    $labels =  @{Expression={$_.Name};Label="Storage Account"}, `
              @{Expression={$_.Value};Label="Account Key"}

    # Get storage info
    $storage = GetStorage -clusterName $clusterName
    # display storage
    #$storage.defaultStorage  | Format-List
    $storage.storageAccounts | Format-List $labels
    Write-Host "Default account: ", $storage.context.StorageAccountName -ForegroundColor Green
    Write-Host "Default container: ", $storage.container -ForegroundColor Green

}


function FindAzure {
    # Is the Azure module installed?
    if (-not(Get-Module -ListAvailable Azure))
    {
        throw "Windows Azure PowerShell not found! For help, see http://www.windowsazure.com/en-us/documentation/articles/install-configure-powershell/"
    }

    # Is there an active Azure subscription?
    $sub = Get-AzureSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        throw "No active Azure subscription found! If you have a subscription, use the Add-AzureAccount or Import-PublishSettingsFile cmdlets to make the Azure account available to Windows PowerShell."
    }
}
function GetStorage {
    param(
        [Parameter(Mandatory = $true)]
        [String]$clusterName
    )
    $hdi = Get-AzureHDInsightCluster -name $clusterName
    # Does the cluster exist?
    if (!$hdi)
    {
        throw "HDInsight cluster '$clusterName' does not exist."
    }
    # Create a return object for context & container
    $return = @{}
    $storageAccounts = @{}
    # Get the primary storage account information
    $storageAccountName = $hdi.DefaultStorageAccount.StorageAccountName.Split(".",2)[0]
    $storageAccountKey = $hdi.DefaultStorageAccount.StorageAccountKey
    # Build the hash of storage account name/keys
    $storageAccounts.Add($hdi.DefaultStorageAccount.StorageAccountName, $storageAccountKey)
    foreach($account in $hdi.StorageAccounts)
    {
        $storageAccounts.Add($account.StorageAccountName, $account.StorageAccountKey)
    }
    # Get the storage context, as we can't depend
    # on using the default storage context
    $return.context = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
    # Get the container, so we know where to
    # find/store blobs
    $return.container = $hdi.DefaultStorageAccount.StorageContainerName
    # Return storage accounts to support finding all accounts for
    # a cluster
    $return.storageAccounts = $storageAccounts

    return $return
}
# Only export the verb-phrase things
export-modulemember *-*