[CmdletBinding()]
param(

)
#Requires -RunAsAdministrator

if($Debug) {
    $DebugPreference = 'Continue'
}
$Timer = New-Object -TypeName 'System.Diagnostics.Stopwatch'
$Timer.Start()

$Separator = [System.IO.Path]::DirectorySeparatorChar
$ModulePath = $env:ProgramFiles + $Separator + "WindowsPowerShell" + $Separator + "Modules"
$ModuleName = $PSScriptRoot.Split($Separator)[-1]
$ModulePathFull = $ModulePath + $Separator + $ModuleName + $Separator
Write-Debug "Attempting to use $ModulePath as module directory"

if($ModulePath -notin $env:PSModulePath.Split(';')) {
    $ModulePath = $env:PSModulePath[0]
    Write-Debug "Original ModulePath not found in PSModulePath, reassigning to $ModulePath"
}

try {
    if(Test-Path $ModulePathFull) {
        Remove-Item $ModulePathFull -Recurse -Force -ErrorAction:Stop
        Write-Debug "Found and removed $ModulePathFull"
    }
    New-Item $ModulePathFull -ItemType Directory | Out-Null
    Write-Debug "Created $ModulePathFull"

    Copy-Item "$PSScriptRoot\src\*" $ModulePathFull -Recurse -Force -ErrorAction:Stop
    Write-Debug "$PSScriptRoot\src\* -> $ModulePathFull"

    $Timer.Stop()
    Write-Host "+ Build completed in $($Timer.Elapsed.TotalSeconds) seconds"
} catch {
    Write-Error "- $_"
    $Timer.Stop()
    break 1
}
