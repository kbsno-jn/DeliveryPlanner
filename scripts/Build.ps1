[CmdletBinding()]
param(
    [switch]$Tests,
    [string]$CompilerPath
)
$ErrorActionPreference = 'Stop'
$workspacePath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $CompilerPath) {
    $alExtension = Get-ChildItem -LiteralPath (Join-Path $env:USERPROFILE '.vscode\extensions') -Directory -Filter 'ms-dynamics-smb.al-*' |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $alExtension) { throw 'AL-utvidelsen for Visual Studio Code ble ikke funnet.' }
    $CompilerPath = Join-Path $alExtension.FullName 'bin\win32\alc.exe'
}
$analyzerPath = [System.IO.Path]::GetFullPath((Join-Path (Split-Path $CompilerPath) '..\Analyzers'))
$outputPath = Join-Path $workspacePath '.build'
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
$stagingPath = Join-Path ([System.IO.Path]::GetTempPath()) ('DeliveryPlannerBuild-' + [guid]::NewGuid().ToString('N'))
$appPath = Join-Path $stagingPath 'App'
New-Item -ItemType Directory -Path $appPath -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $workspacePath 'app.json') -Destination $appPath
Copy-Item -LiteralPath (Join-Path $workspacePath 'Src') -Destination $appPath -Recurse
$sourceTranslations = Join-Path $workspacePath 'Translations'
if (Test-Path -LiteralPath $sourceTranslations) { Copy-Item -LiteralPath $sourceTranslations -Destination $appPath -Recurse }
$appOutput = Join-Path $outputPath 'DeliveryPlanner.app'
$compilerArguments = @(
    "/project:$appPath",
    "/packagecachepath:$(Join-Path $workspacePath '.alpackages')",
    "/out:$appOutput",
    "/analyzer:$(Join-Path $analyzerPath 'Microsoft.Dynamics.Nav.CodeCop.dll')",
    "/analyzer:$(Join-Path $analyzerPath 'Microsoft.Dynamics.Nav.UICop.dll')",
    "/analyzer:$(Join-Path $analyzerPath 'Microsoft.Dynamics.Nav.PerTenantExtensionCop.dll')"
)
& $CompilerPath @compilerArguments 2>&1 | Tee-Object -FilePath (Join-Path $outputPath 'compile.log')
if ($LASTEXITCODE -ne 0) { throw "App-kompilering feilet ($LASTEXITCODE). Se .build/compile.log." }
if ($Tests) {
    $testPath = Join-Path $stagingPath 'Tests'
    $testCache = Join-Path $stagingPath 'TestPackages'
    New-Item -ItemType Directory -Path $testPath, $testCache -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $workspacePath 'Tests\app.json') -Destination $testPath
    Get-ChildItem -LiteralPath (Join-Path $workspacePath 'Tests') -Filter '*.al.test' -Recurse | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $testPath $_.Name.Substring(0, $_.Name.Length - 5))
    }
    Get-ChildItem -LiteralPath (Join-Path $workspacePath '.alpackages') -Filter '*.app' | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $testCache
    }
    Copy-Item -LiteralPath $appOutput -Destination $testCache
    $testArguments = @("/project:$testPath", "/packagecachepath:$testCache", "/out:$(Join-Path $outputPath 'DeliveryPlanner.Tests.app')")
    & $CompilerPath @testArguments 2>&1 | Tee-Object -FilePath (Join-Path $outputPath 'compile-tests.log')
    if ($LASTEXITCODE -ne 0) { throw "Testapp-kompilering feilet ($LASTEXITCODE). Se .build/compile-tests.log." }
}
Write-Output "Byggefiler: $outputPath"
Write-Output "Midlertidig kompilatorkilde: $stagingPath"
