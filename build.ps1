[CmdletBinding()]
param(
    [ValidateSet('List', 'Prune', 'Create')]
    [string[]] $SubCommands = ('List', 'Prune', 'Create'),
    [switch] $RunTests,
    [switch] $NoNewSession,
    [string] $ModulePath,
    [string] $ApiKey = ""
)
#Requires -RunAsAdministrator

if($Debug) {
    $DebugPreference = 'Continue'
}
$Timer = New-Object -TypeName 'System.Diagnostics.Stopwatch'
$Timer.Start()

$Separator = [System.IO.Path]::DirectorySeparatorChar
$ModuleName = $PSScriptRoot.Split($Separator)[-1]
$PSEnvironment = (Get-Process -Id $PID).ProcessName
if ($env:OS -eq 'Windows_NT') {
    $SecretsPath = $Env:USERPROFILE + $Separator + ".todogenie"
} else {
    $SecretsPath = $Env:HOME + $Separator + ".todogenie"
}
$secretsFile = "secrets.json"

if($ModulePath.Length -le 0) {
    $ModulePath = $env:ProgramFiles + $Separator + "WindowsPowerShell" + $Separator + "Modules"
    if($ModulePath -notin $env:PSModulePath.Split(';')) {
        $ModulePath = $env:PSModulePath[0]
        Write-Debug "Original ModulePath not found in PSModulePath, reassigning to $ModulePath"
    }
}
Write-Debug "Attempting to use $ModulePath as module directory"

$ModulePathFull = $ModulePath + $Separator + $ModuleName + $Separator
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
    $FirstTimerTotal = $($Timer.Elapsed.TotalSeconds)
    Write-Host "+ Build completed in $FirstTimerTotal seconds"
} catch {
    Write-Error "- $_"
    $Timer.Stop()
    break 1
}

if($RunTests) {
    if(-not(Get-Module -name $ModuleName -ListAvailable)) {
        Write-Host "- $ModuleName not found; skipped tests."
    }

    if($ApiKey -ne "") {
        if(Test-Path $SecretsPath) {
            Remove-Item $SecretsPath -Recurse -Force
        }
        New-Item $SecretsPath -ItemType:Directory > $null
        New-Item $($SecretsPath + $Separator + $secretsFile) > $null
        $EncryptedKey = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ApiKey))
        $JsonData = @{
            "GithubApiKey" = $EncryptedKey
        } | ConvertTo-Json
        
        $JsonData > $($SecretsPath + $directorySeparator + $secretsFile)
        Write-Debug "Wrote ApiKey to $($SecretsPath + $Separator + $secretsFile)"
    }

    try {
        Write-Debug "Starting tests..."
        $Timer.Reset()
        $Timer.Start()
        if($NoNewSession) {
            Import-Module TodoGenie
            Invoke-Genie $SubCommands -TestMode -ErrorAction:Stop -Debug:$Debug
        } else {
            Invoke-Command {& "$PSEnvironment.exe" -NoLogo -NoProfile -Command {
                Set-Location ($PWD).Path
                Invoke-Genie $SubCommands -TestMode -ErrorAction:Stop -Debug:$Debug
            }} -ErrorAction:Stop
        }
        if($LASTEXITCODE -ne 0) {
            break $LASTEXITCODE
        }
        Write-Host "+ PASSED" -f Green
        $Timer.Stop()
        $SecondTimerTotal = $($Timer.Elapsed.TotalSeconds)
    } catch {
        Write-Error "- $_"
        $Timer.Stop()
        break 1
    }
}
[System.ConsoleColor] $OutputColor = 
    switch($FirstTimerTotal + $SecondTimerTotal) {
        {$_ -gt 15} { "Red" }
        {$_ -ge 10 -and $_ -le 15} { "Yellow" }
        default { "Green" }
    }   
Write-Host "+ Total elapsed time: " -NoNewline
Write-Host "$($FirstTimerTotal + $SecondTimerTotal) " -ForegroundColor $OutputColor -NoNewline
Write-Host "seconds"
