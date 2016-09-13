
Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:0

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $CsvPath,

        [parameter()]
        [System.Boolean]
        $force = $false
    )

   
    $fileExists = Test-Path $CsvPath
    if($fileExists -and (Test-TargetResource $CsvPath -force $force))
    {
        $returnValue = @{
            CsvPath = $CsvPath
        }

    }
    else
    {
        if (!($fileExists))
        {
            Write-Verbose ($localizedData.FileNotFound -f $CsvPath)
        }
        $returnValue = @{
            CsvPath = ''
        }

    }
    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $CsvPath,

        [parameter()]
        [System.Boolean]
        $force = $false
    )

    if(Test-Path $CsvPath)
    {
        
        #clear existing policy!!
        Write-Verbose "SETTING" 
        try
        {
            Invoke-SecurityCmdlet -Action "Import" -Path $CsvPath
            #Write-Verbose ($localizedData.ImportSucceed -f $CsvPath)
        }
        catch
        {
            Write-Verbose ($localizedData.ImportFailed -f $CsvPath)
        }


    }
    else
    {
        Write-Verbose ($localizedData.FileNotFound -f $CsvPath)
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $CsvPath,

        [parameter()]
        [System.Boolean]
        $force = $false
    )

    if(Test-Path $CsvPath)
    {
        #Question: Better way to create a temp file in SYSTEM context?
        $tempFile = "C:\Temp\test.CSV"
        if(! (Test-Path "c:\Temp"))
        {
            New-Item -ItemType Directory -path "c:\temp"
        }

        try
        {
            Invoke-SecurityCmdlet -Action "Export" -Path $tempFile
        }
        catch
        {
            Write-Verbose ($localizedData.ExportFailed -f $tempFile)
            return $false
        }

        #Ignore "Machine Name" since it will cause a failure if your CSV was generated on a different machine
        #then the one you're managing. This should not impact functionality in any way, but NEEDSREVIEW.
        $ActualSettings =  import-csv $tempFile | Select-Object -Property "Subcategory GUID", "Setting Value"
        $DesiredSettings =  import-csv $CsvPath | Select-Object -Property "Subcategory GUID", "Setting Value"
        
        #compare GUIDs and values to see if they are the same
        #options have no GUIDs, just object names...

        $result = Compare-Object $DesiredSettings $ActualSettings
        #only report items where selected items are present in desired state but NOT in actual state
        if (! ($result) )
        {
            return $true
        }
        else
        {
            #TODO: branch on $force
            foreach ($entry in $result)
            {
                Write-Verbose ($localizedData.testCsvFailed -f $entry.InputObject.Subcategory)
            }
            return $false
        }
    }

    else
    {
        Write-Verbose ($localizedData.FileNotFound -f $CsvPath)
        return $false
    }
    #this shouldn't get reached, but it is getting reached. 
    return $false
}

Export-ModuleMember -Function *-TargetResource
