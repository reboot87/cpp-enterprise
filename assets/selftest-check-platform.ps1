#requires -Version 5.1
<#
.SYNOPSIS
    Self-test for check-platform.ps1.

.DESCRIPTION
    Builds temporary fixtures (one clean, several violating) and asserts the
    checker's exit codes. Run after editing the checker.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File selftest-check-platform.ps1
#>
param(
    [string]$Checker = (Join-Path $PSScriptRoot 'check-platform.ps1')
)

$ErrorActionPreference = 'Stop'
$script:failures = 0
$tempRoots = New-Object 'System.Collections.Generic.List[string]'

function New-FixtureDir {
    $d = Join-Path ([IO.Path]::GetTempPath()) ('cpp-enterprise-selftest-' + [guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($d) | Out-Null
    $tempRoots.Add($d)
    return $d
}

function Set-Fixture([string]$root, [string]$rel, [string]$content) {
    $p = Join-Path $root $rel
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p)) | Out-Null
    [IO.File]::WriteAllText($p, $content)
}

function Invoke-Checker([string]$root, [string[]]$extra) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Checker, '-Root', $root)
    if ($extra) { $argList += $extra }
    & powershell @argList | Out-Null
    return $LASTEXITCODE
}

function Test-Case([string]$name, [string]$root, [string[]]$extra, [int]$expected) {
    $code = Invoke-Checker $root $extra
    if ($code -eq $expected) {
        Write-Host "ok: $name"
    }
    else {
        Write-Host "FAIL selftest: $name (expected $expected, got $code)"
        $script:failures++
    }
}

$sentinelWin = "#ifndef _WIN32`n#  error wrong platform`n#endif`n"
$sentinelPosix = "#ifdef _WIN32`n#  error wrong platform`n#endif`n"

try {
    $a = New-FixtureDir
    Set-Fixture $a 'include/api.h' "#pragma once`nstruct Api {};`n"
    Set-Fixture $a 'include/api/platform/handle.h' "#pragma once`n#ifdef _WIN32`nusing SocketHandle = unsigned long long;`n#else`nusing SocketHandle = int;`n#endif`n"
    Set-Fixture $a 'src/core/impl.cpp' "int add(int a, int b) { return a + b; }`n"
    Set-Fixture $a 'src/adapters/vendor/lib.cpp' "#ifdef _MSC_VER`nint v() { return 1; }`n#endif`n"
    Set-Fixture $a 'src/platform/win32/net.cpp' ($sentinelWin + "void netInit() {}`n")
    Set-Fixture $a 'src/platform/posix/net.cpp' ($sentinelPosix + "void netInit() {}`n")
    Test-Case 'clean tree passes' $a @() 0

    $b = New-FixtureDir
    Set-Fixture $b 'include/bad.h' "#pragma once`n#include <windows.h>`n#ifdef _WIN32`n#endif`n"
    Test-Case 'OS header and platform macro rejected' $b @() 1

    $e = New-FixtureDir
    Set-Fixture $e 'include/api/platform/handle.h' "#pragma once`n#include <windows.h>`n"
    Test-Case 'OS header in platform header rejected' $e @() 1

    $f = New-FixtureDir
    Set-Fixture $f 'src/core/impl.cpp' "#ifdef _MSC_VER`nint f() { return 1; }`n#endif`n"
    Test-Case 'MSVC macro in core rejected' $f @() 1

    $g = New-FixtureDir
    Set-Fixture $g 'include/api/platform/extra.h' "#ifdef _WIN32`n#endif`n"
    Test-Case 'only handle.h is platform-aware' $g @() 1

    $c = New-FixtureDir
    Set-Fixture $c 'src/platform/win32/a.cpp' ($sentinelWin + "void a() {}`n")
    Set-Fixture $c 'src/platform/win32/b.cpp' ($sentinelWin + "void b() {}`n")
    Set-Fixture $c 'src/platform/posix/a.cpp' ($sentinelPosix + "void a() {}`n")
    Test-Case 'unpaired platform source rejected' $c @() 1
    Test-Case 'pairing can be skipped' $c @('-SkipPairing') 0

    $d = New-FixtureDir
    Set-Fixture $d 'src/platform/win32/x.cpp' "void x() {}`n"
    Set-Fixture $d 'src/platform/posix/x.cpp' "void x() {}`n"
    Test-Case 'missing sentinel rejected' $d @('-RequireSentinel') 1
}
finally {
    foreach ($dir in $tempRoots) {
        Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($script:failures -gt 0) {
    Write-Host "selftest: $($script:failures) failure(s)"
    exit 1
}
Write-Host 'selftest: OK'
exit 0
