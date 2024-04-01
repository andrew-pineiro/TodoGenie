<#
   Global Module Variables
#>
$DirectorySeparator = [System.IO.Path]::DirectorySeparatorChar
if ($env:OS -eq 'Windows_NT') {
    $SecretsPath = $Env:USERPROFILE + $DirectorySeparator + ".todogenie"
} else {
    $SecretsPath = $Env:HOME + $DirectorySeparator + ".todogenie"
}
$SecretsFile = "secrets.json"
$SecretsFileFullPath = ($SecretsPath + $DirectorySeparator + $SecretsFile)

<#
    Local Module Variables
#>
$moduleName = $PSScriptRoot.Split($DirectorySeparator)[-1]
$moduleManifest = $PSScriptRoot + $DirectorySeparator + $moduleName + '.psd1'
$publicFunctionsPath = $PSScriptRoot + $DirectorySeparator + 'Public' + $DirectorySeparator
$privateFunctionsPath = $PSScriptRoot + $DirectorySeparator + 'Private' + $DirectorySeparator
$currentManifest = Test-ModuleManifest $moduleManifest
$publicFunctions = Get-ChildItem -Path $publicFunctionsPath | Where-Object {$_.Extension -eq '.ps1'}
$privateFunctions = Get-ChildItem -Path $privateFunctionsPath | Where-Object {$_.Extension -eq '.ps1'}
$publicFunctions | ForEach-Object { . $_.FullName }
$privateFunctions | ForEach-Object { . $_.FullName }
$aliases = @()

$publicFunctions | ForEach-Object { # Export all of the public functions from this module

    # The command has already been sourced in above. Query any defined aliases.
    $alias = Get-Alias -Definition $_.BaseName -ErrorAction SilentlyContinue
    if ($alias) {
        $aliases += $alias
        Export-ModuleMember -Function $_.BaseName -Alias $alias
    }
    else {
        Export-ModuleMember -Function $_.BaseName
    }

}

$functionsAdded = $publicFunctions | Where-Object {$_.BaseName -notin $currentManifest.ExportedFunctions.Keys}
$functionsRemoved = $currentManifest.ExportedFunctions.Keys | Where-Object {$_ -notin $publicFunctions.BaseName}
$aliasesAdded = $aliases | Where-Object {$_ -notin $currentManifest.ExportedAliases.Keys}
$aliasesRemoved = $currentManifest.ExportedAliases.Keys | Where-Object {$_ -notin $aliases}

if ($functionsAdded -or $functionsRemoved -or $aliasesAdded -or $aliasesRemoved) {

    try {
         $updateModuleManifestParams = @{}
         $updateModuleManifestParams.Add('Path', $moduleManifest)
         if ($aliases.Count -gt 0) { $updateModuleManifestParams.Add('AliasesToExport', $aliases) }
         if ($publicFunctions.Count -gt 0) { $updateModuleManifestParams.Add('FunctionsToExport', $publicFunctions.BaseName) }

         Update-ModuleManifest @updateModuleManifestParams

     }
     catch {
         Write-Error $_
     }

}

if(-not(Test-Path $SecretsPath)) {
    try {
            New-Item $SecretsPath -ItemType:Directory -ErrorAction:SilentlyContinue
            New-Item $secretsFileFullPath -ErrorAction:Stop
        
            Write-Host "Enter Github ApiKey: " -NoNewline
            $apikey = Read-Host -AsSecureString
            $encryptedKey = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(
                [System.RunTime.InteropServices.Marshal]::PtrToStringAuto(
                    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apikey))))

            if($apiKey.Length -le 0) {
                Write-Error "invalid apiKey entered"
                break 1
            }
                
            $jsonData = @{
                "GithubApiKey" = $encryptedKey
            } | ConvertTo-Json
        
            $jsonData > $SecretsFileFullPath
    }
    catch {
        Write-Error $_
        break 1
    }
}

