#requires -Version 5.1
<#
.SYNOPSIS
    cpp-enterprise platform rules check.

.DESCRIPTION
    Fails on:
      1. OS headers in portable code (public headers, core, tests).
      2. Platform macros outside the platform layer.
      3. Public/core code depending on a concrete platform backend.
      4. Missing #error sentinel in platform sources (-RequireSentinel).
      5. Unpaired platform sources: win32/ and posix/ must ship the same .cpp
         set; darwin/ may override a subset (-SkipPairing to disable).

    Exempt by design: src/platform/**, src/adapters/** (platform/vendor code),
    include/<ns>/platform/handle.h, and -MacroExempt paths.
    Any other header under include/<ns>/platform/ is not exempt.

    Synced from the cpp-enterprise skill. Update the skill first, then re-copy.

.PARAMETER ReportOnly
    Print findings but always exit 0. Use while paying down legacy debt.

.EXAMPLE
    powershell -File scripts/check-platform.ps1 -ReportOnly
#>
[CmdletBinding()]
param(
    [string]$Root = ".",
    [string]$PlatformDir = "src/platform",
    [string]$CoreDir = "src",
    [string]$IncludeDir = "include",
    [string]$AdapterDir = "src/adapters",
    [string[]]$MacroExempt = @("tests"),
    [switch]$RequireSentinel,
    [switch]$SkipPairing,
    [switch]$ReportOnly
)

$ErrorActionPreference = "Stop"

$rootPath = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\', '/')
$skipDirs = @('.git', 'build', 'bin', 'obj', 'out', 'node_modules', 'third_party', 'vendor', 'external', '_deps')
$exts = @('.h', '.hpp', '.hh', '.hxx', '.c', '.cc', '.cpp', '.cxx', '.inl', '.ipp')
$findings = New-Object 'System.Collections.Generic.List[string]'

$osHeaderRx = '#[ \t]*include[ \t]*[<"](windows\.h|winsock2\.h|ws2tcpip\.h|unistd\.h|pthread\.h|dlfcn\.h|io\.h|direct\.h|process\.h|tchar\.h|netdb\.h|poll\.h|syslog\.h|termios\.h|sys/|netinet/|arpa/|mach/|linux/|android/)'
$platformMacroRx = '\b(_WIN32|_WIN64|_MSC_VER|__linux__|__linux|__unix__|__unix|__APPLE__|__MACH__|__FreeBSD__|__CYGWIN__|__ANDROID__|_POSIX_VERSION)\b'
$backendRx = 'platform/(win32|posix|darwin)/'
$platformHeaderRx = '(^|/)include/(?:[^/]+/)?platform/handle\.h$'

function Get-RelPath([string]$path) {
    $rel = $path.Substring($rootPath.Length)
    return (($rel -replace '^[\\/]+', '') -replace '\\', '/')
}

function Test-Under([string]$rel, [string]$dir) {
    $d = $dir.Trim('/').Replace('\', '/')
    if ([string]::IsNullOrEmpty($d)) { return $false }
    return ($rel -eq $d) -or $rel.StartsWith($d + '/', [System.StringComparison]::Ordinal)
}

function Test-Skip([string]$full) {
    $rel = Get-RelPath $full
    foreach ($d in $skipDirs) {
        if (Test-Under $rel $d) { return $true }
    }
    return $false
}

function Add-Finding([string]$rel, [string]$text, [int]$index, [string]$message) {
    $line = ([regex]::Matches($text.Substring(0, $index), "`n")).Count + 1
    $findings.Add("${rel}:${line}: $message")
}

$platformPath = Join-Path $rootPath $PlatformDir
if (-not (Test-Path -LiteralPath $platformPath)) {
    Write-Host "warn: platform directory not found: $PlatformDir (adoption pending)" -ForegroundColor Yellow
}
elseif (-not $SkipPairing) {
    # win32/ and posix/ must expose the same .cpp set; darwin/ may override a subset.
    $osFiles = @{}
    foreach ($os in @('win32', 'posix', 'darwin')) {
        $osDir = Join-Path $platformPath $os
        if (Test-Path -LiteralPath $osDir) {
            $osFiles[$os] = @(Get-ChildItem -LiteralPath $osDir -Filter *.cpp -File |
                ForEach-Object { $_.Name })
        }
    }
    if ($osFiles.ContainsKey('win32') -and $osFiles.ContainsKey('posix')) {
        foreach ($n in $osFiles['win32']) {
            if ($osFiles['posix'] -notcontains $n) {
                $findings.Add("$PlatformDir/win32/${n}: missing pair in posix/")
            }
        }
        foreach ($n in $osFiles['posix']) {
            if ($osFiles['win32'] -notcontains $n) {
                $findings.Add("$PlatformDir/posix/${n}: missing pair in win32/")
            }
        }
    }
    if ($osFiles.ContainsKey('darwin')) {
        $posixFiles = if ($osFiles.ContainsKey('posix')) { $osFiles['posix'] } else { @() }
        foreach ($n in $osFiles['darwin']) {
            if ($posixFiles -notcontains $n) {
                $findings.Add("$PlatformDir/darwin/${n}: no matching posix source")
            }
        }
    }
}

$files = @(Get-ChildItem -LiteralPath $rootPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $exts -contains $_.Extension.ToLowerInvariant() -and -not (Test-Skip $_.FullName) })

foreach ($f in $files) {
    $rel = Get-RelPath $f.FullName
    $isPlatform = Test-Under $rel $PlatformDir
    $isAdapter = Test-Under $rel $AdapterDir
    $isPlatformHeader = $rel -match $platformHeaderRx
    $isMacroExempt = $false
    foreach ($d in $MacroExempt) {
        if (Test-Under $rel $d) { $isMacroExempt = $true; break }
    }

    $text = Get-Content -LiteralPath $f.FullName -Raw
    if ($null -eq $text) { $text = '' }

    if (-not $isPlatform -and -not $isAdapter -and -not $isMacroExempt) {
        foreach ($m in [regex]::Matches($text, $osHeaderRx, 'IgnoreCase')) {
            Add-Finding $rel $text $m.Index "OS header in portable code ($($m.Value))"
        }
    }

    if (-not $isPlatform -and -not $isAdapter -and -not $isPlatformHeader -and -not $isMacroExempt) {
        foreach ($m in [regex]::Matches($text, $platformMacroRx)) {
            Add-Finding $rel $text $m.Index "platform macro outside platform layer ($($m.Value))"
        }
    }

    $inPublic = Test-Under $rel $IncludeDir
    $inCore = (Test-Under $rel $CoreDir) -and (-not $isAdapter)
    if ((-not $isPlatform) -and ($inPublic -or $inCore)) {
        foreach ($m in [regex]::Matches($text, $backendRx)) {
            Add-Finding $rel $text $m.Index "dependency on a concrete platform backend ($($m.Value))"
        }
    }

    if ($RequireSentinel -and $isPlatform -and -not (Test-Under $rel "$PlatformDir/common")) {
        if ($text -notmatch '#[ \t]*error') {
            $findings.Add("${rel}: missing sentinel #error")
        }
    }
}

if ($findings.Count -eq 0) {
    Write-Host "platform checks: OK ($($files.Count) files scanned)"
    exit 0
}

foreach ($item in $findings) {
    Write-Host "FAIL $item"
}
Write-Host "platform checks: $($findings.Count) finding(s) in $($files.Count) files"

if ($ReportOnly) {
    Write-Host "report-only mode: exit 0"
    exit 0
}
exit 1
