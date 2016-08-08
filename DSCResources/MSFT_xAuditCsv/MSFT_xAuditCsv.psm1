
Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:0

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $CsvPath
    )

   
    $fileExists = Test-Path $CsvPath
    if($fileExists -and (Test-TargetResource $CsvPath))
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
        $CsvPath
    )

    if(Test-Path $CsvPath)
    {
        
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
        $CsvPath
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
        #only report items where selected items are present in desired state but NOT in actual state

        $ActualSettings =  import-csv $tempFile | Select-Object -ExcludeProperty "Machine Name" -Property * 
        $DesiredSettings =  import-csv $CsvPath | Select-Object -ExcludeProperty "Machine Name" -Property * 
        $result = Compare-Object $DesiredSettings $ActualSettings

        if (! ($result) )
        {
            return $true
        }
        else
        {
            foreach ($entry in $result)
            {
                Write-Verbose ($localizedData.testCsvFailed -f $entry.InputObject)
            }
            return $false
        }
    }

    else
    {
        Write-Verbose ($localizedData.FileNotFound -f $CsvPath)
        return $false
    }

    return $return
}

Export-ModuleMember -Function *-TargetResource
