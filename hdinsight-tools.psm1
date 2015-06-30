<#
.SYNOPSIS
    Copies a file to the primary storage of an HDInsight cluster.
.DESCRIPTION
    Copies a file from a local directory to the HDInsight cluster.
.EXAMPLE
    Add-WASB -localPath "C:\temp\data.txt"
        -wasbPath "/example/data/data.txt"
        -ClusterName "MyHDInsightCluster"
.EXAMPLE
    Add-WASB -localPath "C:\temp\data.txt"
        -wasbPath "wasb:///example/data/data.txt"
        -ClusterName "MyHDInsightCluster"
.EXAMPLE
    Add-WASB -localPath "C:\temp\data.txt"
        -wasbPath "wasb://container@storageaccount.blob.windows.net/example/data/data.txt"
        -ClusterName "MyHDInsightCluster"
#>

function Add-WASB {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        #The path to the local file.
        [Parameter(Mandatory = $true)]
        [String]$localPath,

        #The WASB destination path and file name
        [Parameter(Mandatory = $true)]
        [String]$wasbPath,

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

    # Parse the WASB path and return info
    # used by the storage call
    $wasb = ParseWASB $wasbPath $clusterName

    # Upload file to storage, overwriting existing files if -force was used.
    Set-AzureStorageBlobContent -File $localPath `
                                -Blob $wasb.resource `
                                -force:$force `
                                -Container $wasb.container `
                                -Context $wasb.context
}

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
    [Obsolete("The Add-HDInsightFile cmdlet is obsolete. Use the Add-WASB cmdlet instead.")]
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
    Removes files from the WASB storage of an HDInsight cluster.
.DESCRIPTION
    Removes a single file, or all files with the specified prefix,
    from WASB for the HDInsight cluster.
.EXAMPLE
    Remove-WASB -wasbPath "/example/data/data.txt"
        -clusterName "MyHDInsightCluster"
.EXAMPLE
    Remove-WASB -wasbPath "wasb:///example/data/data.txt"
        -clusterName "MyHDInsightCluster"
.EXAMPLE
    Remove-WASB -wasbPath "wasb://container@storageaccount.blob.windows.net/example/data/data.txt"
        -clusterName "MyHDInsightCluster"
#>
function Remove-WASB {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        #The destination path and file name
        [Parameter(Mandatory = $true)]
        [String]$wasbPath,

        #The name of the HDInsight cluster
        [Parameter(Mandatory = $true)]
        [String]$clusterName
    )

    Set-StrictMode -Version 3

    # Is the Azure module installed?
    FindAzure

    # Parse the WASB path and return info
    # used by the storage call
    $wasb = ParseWASB $wasbPath $clusterName

    # Remove the file
    Remove-AzureStorageBlob -Blob $wasb.resource `
                            -Container $wasb.container `
                            -Context $wasb.context
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
    [Obsolete("The Remove-HDInsightFile cmdlet is obsolete. Use the Remove-WASB cmdlet instead.")]
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
    Gets a file from HDInsight and saves it locally.
.DESCRIPTION
    Gets a file from HDInsight and saves it locally.
.EXAMPLE
    Get-WASB -wasbPath "/example/data/data.txt"
        -localPath "c:\myfiles\data.txt"
        -clusterName "MyHDInsightCluster"
.EXAMPLE
    Get-WASB -wasbPath "wasb:///example/data/data.txt"
        -localPath "c:\myfiles\data.txt"
        -clusterName "MyHDInsightCluster"
.EXAMPLE
    Get-WASB -wasbPath "wasb://container@storageaccount.blob.windows.net/example/data/data.txt"
        -localPath "c:\myfiles\data.txt"
        -clusterName "MyHDInsightCluster"
#>
function Get-WASB {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        #The destination path and file name, relative to the root of the container.
        [Parameter(Mandatory = $true)]
        [String]$wasbPath,

        [Parameter(Mandatory = $true)]
        [String]$localPath,

        #The name of the HDInsight cluster
        [Parameter(Mandatory = $true)]
        [String]$clusterName
    )

    Set-StrictMode -Version 3

    # Is the Azure module installed?
    FindAzure

    # Parse the WASB path and return info
    # used by the storage call
    $wasb = ParseWASB $wasbPath $clusterName

    # Get the blob
    Get-AzureStorageBlobContent -Blob $wasb.resource `
                                -Destination $localPath `
                                -Container $wasb.container `
                                -Context $wasb.context
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
    [Obsolete("The Get-HDInsightFile cmdlet is obsolete. Use the Get-WASB cmdlet instead.")]
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
    Lists files stored on HDInsight
.DESCRIPTION
    Lists files stored on HDInsight
.EXAMPLE
    Find-WASB -wasbPath "example/data"
        -clusterName "MyHDInsightCluster"
.EXAMPLE
    Find-WASB -wasbPath "example*"
        -clusterName "MyHDInsightCluster"
#>
function Find-WASB {
[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        #The file name/path/prefix, if any
        [Parameter(Mandatory = $false)]
        [String]$wasbPath,

        #The name of the HDInsight cluster
        [Parameter(Mandatory = $true)]
        [String]$clusterName
    )

    Set-StrictMode -Version 3

    # Is the Azure module installed?
    FindAzure

    # Parse the WASB path and return info
    # used by the storage call
    $wasb = ParseWASB $wasbPath $clusterName

    # Get the blob
    Get-AzureStorageBlobContent -Blob $wasb.resource `
                                -Container $wasb.container `
                                -Context $wasb.context


    # Prefix, or specific blob?
    Get-AzureStorageBlob -Prefix $wasb.resource `
                         -Container $wasb.container `
                         -Context $wasb.context
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
[Obsolete("The Find-HDInsightFile cmdlet is obsolete. Use the Find-WASB cmdlet instead.")]
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
    $storage.storageAccounts | Format-List $labels
    Write-Host "Default account: ", $storage.context.StorageAccountName -ForegroundColor Green
    Write-Host "Default container: ", $storage.container -ForegroundColor Green

}


function FindAzure {
    # Is the Azure module installed?
    if (-not(Get-Module Azure))
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

function ParseWASB {
    param(
        [Parameter(Mandatory = $true)]
        [String]$destinationPath,

        [Parameter(Mandatory = $true)]
        [String]$clusterName
    )
    #Parse the wasb path
    if ($destinationPath.StartsWith("wasb:") -or $destinationPath.StartsWith("/"))
    {
        #Strip off wasb:, if it's there
        $path=$destinationPath.TrimStart('wasb:')
        #Default storage URI? Strip off ///
        if($path.StartsWith("///"))
        {
          $path=$path.TrimStart("///")
        }
        else
        {
            #Maybe it's //container@storage?
            if($path.StartsWith("//"))
            {
                $pathInfo=$path.TrimStart("//").Split("@")
                $container = $pathInfo[0]
                $fqdnAndPath = $pathInfo[1].Split("/",2)
                $storageAccountFQDN = $fqdnAndPath[0]
                $path = $fqdnAndPath[1]
            }
            else
            {
                #Maybe it's just a single /?
                if($path.StartsWith("/"))
                {
                    $path=$path.TrimStart("/")
                }
                # Ok, if it's not /, then let's assume
                # that it's a raw blob path, which is also fine.
            }
        }
    }
    # Should have a basic path at this point

    # Get current cloud environment name
    # because Mooncake and various other environments
    $cloudEnv=Get-AzureSubscription -Current
    $cloudEnvName=$cloudEnv.Environment

    # Get storage associated with this cluster
    $storage = GetWasbStorage -clusterName $clusterName

    #If a storage account and container was specified
    if(test-path variable:\storageAccountFQDN)
    {
        # Can the cluster access this storage?
        if(-not $storage.storageAccounts.Contains($storageAccountFQDN))
        {
            throw "Storage account $storageAccount is not associated with $clusterName."
        }
        # Set the storage account
        $storageAccount = $storageAccountFQDN
        # $container was set earlier, so we don't worry about it
    }
    else
    # Use default storage and container
    {
        #Get default storage info for the cluster
        $storageAccount = $storage.defaultStorageAccount
        $container = $storage.defaultContainer
    }

    # Get just the name out of the account FQDN
    $storageAccountName = $storageAccount.Split(".",2)[0]
    # Get the key for the account
    $storageAccountKey = $storage.storageAccounts[$storageAccount]

    # Get a context, given the storage account, key, and environment
    $context = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey -Environment $cloudEnvName

    $return = @{}
    $return.container = $container
    $return.context = $context
    $return.resource = $path

    return $return
}

function GetWASBStorage {
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
    $storageAccountName = $hdi.DefaultStorageAccount.StorageAccountName
    $storageAccountKey = $hdi.DefaultStorageAccount.StorageAccountKey
    # Build the hash of storage account name/keys
    $storageAccounts.Add($hdi.DefaultStorageAccount.StorageAccountName, $storageAccountKey)
    foreach($account in $hdi.StorageAccounts)
    {
        $storageAccounts.Add($account.StorageAccountName, $account.StorageAccountKey)
    }
    # Set the default account and container
    $return.defaultStorageAccount = $storageAccountName
    $return.defaultContainer = $hdi.DefaultStorageAccount.StorageContainerName
    # Return storage accounts to support finding all accounts for
    # a cluster
    $return.storageAccounts = $storageAccounts

    return $return
}

# Old, soon to be deprecated
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
    # Get current cloud environment name
    $cloudEnv=Get-AzureSubscription -Current
    $cloudEnvName=$cloudEnv.Environment
    # Get the storage context, as we can't depend
    # on using the default storage context
    $return.context = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey -Environment $cloudEnvName
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
