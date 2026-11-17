#!/usr/bin/env pwsh
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Config = 'Release',

    [ValidateSet('win-x64', 'win-x86', 'linux-x64', 'linux-x86')]
    [string[]]$Targets = @('win-x64', 'win-x86', 'linux-x64', 'linux-x86'),

    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$root    = $PSScriptRoot
$buildRt = Join-Path $root 'build'
$distRt  = Join-Path $root 'dist'
$tcDir   = Join-Path $buildRt '_toolchains'
New-Item -ItemType Directory -Force -Path $tcDir | Out-Null

function Write-Toolchain([string]$name, [string]$content) {
    $path = Join-Path $tcDir "$name.cmake"
    Set-Content -Path $path -Value $content -Encoding utf8
    return $path
}

function Mingw-Toolchain([string]$triple, [string]$arch) {
    Write-Toolchain "win-$arch" @"
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR $arch)
set(CMAKE_C_COMPILER   $triple-gcc-posix)
set(CMAKE_CXX_COMPILER $triple-g++-posix)
set(CMAKE_RC_COMPILER  $triple-windres)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-static -static-libgcc -static-libstdc++")
"@
}

function Linux32-Toolchain {
    Write-Toolchain 'linux-x86' @"
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR i686)
set(CMAKE_C_FLAGS_INIT   "-m32")
set(CMAKE_CXX_FLAGS_INIT "-m32")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-m32 -static-libgcc -static-libstdc++")
"@
}

# name -> toolchain file (or $null for the native host build)
$toolchains = @{
    'win-x64'   = Mingw-Toolchain 'x86_64-w64-mingw32' 'x86_64'
    'win-x86'   = Mingw-Toolchain 'i686-w64-mingw32'   'i686'
    'linux-x86' = Linux32-Toolchain
    'linux-x64' = $null
}

$artifact = @{
    'win-x64'   = 'RmlUiNative.dll'
    'win-x86'   = 'RmlUiNative.dll'
    'linux-x64' = 'libRmlUiNative.so'
    'linux-x86' = 'libRmlUiNative.so'
}

$failed = @()

foreach ($t in $Targets) {
    Write-Host "`n=== Building $t ($Config) ===" -ForegroundColor Cyan
    $bdir = Join-Path $buildRt "$t-$Config"
    $out  = Join-Path $distRt  $t

    if ($Clean -and (Test-Path $bdir)) { Remove-Item -Recurse -Force $bdir }
    New-Item -ItemType Directory -Force -Path $out | Out-Null

    $cfg = @('-S', $root, '-B', $bdir, '-G', 'Ninja', "-DCMAKE_BUILD_TYPE=$Config")
    if ($toolchains[$t]) { $cfg += "-DCMAKE_TOOLCHAIN_FILE=$($toolchains[$t])" }

    cmake @cfg
    if ($LASTEXITCODE -ne 0) { $failed += $t; continue }

    cmake --build $bdir --config $Config --parallel
    if ($LASTEXITCODE -ne 0) { $failed += $t; continue }

    $found = Get-ChildItem -Path $root, $bdir -Recurse -Filter $artifact[$t] -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($found) {
        Copy-Item $found.FullName $out -Force
        Write-Host "-> $(Join-Path $out $found.Name)" -ForegroundColor Green
    } else {
        Write-Warning "Built $t but could not locate $($artifact[$t])"
        $failed += $t
    }
}

Write-Host ""
if ($failed.Count) {
    Write-Host "Failed: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "All targets built. Output in $distRt" -ForegroundColor Green