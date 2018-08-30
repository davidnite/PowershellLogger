# Basic log settings
$logFile = "$PSScriptRoot\applog.log"
$logState = "DEBUG"
$logSize = 30kb
$logCount = 10
$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss:fff")

# Log functions
function New-LogMessage ($line) 
{
    Add-Content $logFile -Value $Line
    Write-Host $Line
}

# Write the log message
Function New-Log 
{
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True)][string]$Message,
    [Parameter(Mandatory=$False)][String]$State = "DEBUG"
    )

    $states = ("DEBUG","INFO","WARN","ERROR","FATAL")
    $logStatePos = [array]::IndexOf($states, $logState)
    $StatePos = [array]::IndexOf($states, $State)

    if ($logStatePos -lt 0)
    {
    New-LogMessage "$Stamp ERROR Wrong logLevel configuration [$logState]"
    }
    
    if ($StatePos -lt 0)
    {
        New-LogMessage "$Stamp ERROR Wrong log level parameter [$State]"
    }

    if ($StatePos -lt $logStatePos -and $StatePos -ge 0 -and $logStatePos -ge 0)
    {
        return
    }

    $LogLine = "$Stamp $State $Message"
    New-LogMessage $LogLine
}

# Roll log when size limit reached
function Roll-Log 
{  
    param([string]$fileToRoll, [int64]$filesize = 1mb , [int] $logcount = 5) 

    $rollStatus = $true 
    if(test-path $fileToRoll) 
    { 
        $file = Get-ChildItem $fileToRoll 
        if((($file).length) -ige $filesize) 
        { 
            $Dir = $file.Directory 
            $fileName = $file.name
            $files = Get-ChildItem $Dir | Where-Object{$_.name -like "$fileName*"} | Sort-Object lastwritetime 
            $filename = $file.fullname
            for ($i = ($files.count); $i -gt 0; $i--) {  
                $files = Get-ChildItem $Dir | Where-Object{$_.name -like "$fileName*"} | Sort-Object lastwritetime 
                $currentFile = $files | Where-Object{($_.name).trim($fileName) -eq $i} 
                if ($currentFile) 
                {
                    $currentFilenumber = ($files | Where-Object{($_.name).trim($fileName) -eq $i}).name.trim($fileName)
                } 
                else 
                {
                    $currentFilenumber = $null
                } 
                if(($currentFilenumber -eq $null) -and ($i -ne 1) -and ($i -lt $logcount)) 
                { 
                    $currentFilenumber = $i 
                    $newfilename = "$filename.$currentFilenumber" 
                    $currentFile = $files | Where-Object{($_.name).trim($fileName) -eq ($i-1)}  
                    move-item ($currentFile.FullName) -Destination $newfilename -Force 
                } 
                elseif($i -ge $logcount) 
                { 
                    if($currentFilenumber -eq $null) 
                    {  
                        $currentFilenumber = $i - 1 
                        $currentFile = $files | Where-Object{($_.name).trim($fileName) -eq $currentFilenumber} 
                    }  
                    remove-item ($currentFile.FullName) -Force 
                } 
                elseif($i -eq 1) 
                { 
                    $currentFilenumber = 1 
                    $newfilename = "$filename.$currentFilenumber"  
                    move-item $filename -Destination $newfilename -Force 
                } 
                else 
                { 
                    $currentFilenumber = $i +1  
                    $newfilename = "$filename.$currentFilenumber" 
                    $currentFile = $files | Where-Object{($_.name).trim($fileName) -eq ($i-1)}  
                    move-item ($currentFile.FullName) -Destination $newfilename -Force    
                } 
            } 
        } 
        else { $rollStatus = $false } 
    } 
    else { $rollStatus = $false } 
        $rollStatus 
} 

# Prevent output during log roll
$Null = @(
    Roll-Log -fileName $logFile -filesize $logSize -logcount $logCount
)