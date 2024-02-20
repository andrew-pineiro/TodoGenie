$Separator = [System.IO.Path]::DirectorySeparatorChar
$ModulePath = $env:ProgramFiles + $Separator + "WindowsPowerShell" + $Separator + "Modules"
$ModuleName = $PSScriptRoot.Split($Separator)[-1]
$ModulePathFull = $ModulePath + $Separator + $ModuleName + $Separator

if($ModulePath -notin $env:PSModulePath.Split(';')) {
    $ModulePath = $env:PSModulePath[0]
}

try {

    if(Test-Path $ModulePathFull) {
        Remove-Item $ModulePathFull -Recurse -Force -ErrorAction:Stop
    }
    New-Item $ModulePathFull -ItemType Directory | Out-Null
    Copy-Item .\src\* $ModulePathFull -Recurse -Force -ErrorAction:Stop

} catch {
    Write-Error $_
    break 1
}
