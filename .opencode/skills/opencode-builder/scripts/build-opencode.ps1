# OpenCode Builder Script
# Usage: ./build-opencode.ps1 [-CliOnly] [-DesktopOnly] [-SkipCli] [-Clean]

param(
    [switch]$CliOnly,
    [switch]$DesktopOnly,
    [switch]$SkipCli,
    [switch]$Clean,
    [string]$RepoRoot = $PSScriptRoot
)

# Find repo root
if (-not (Test-Path "$RepoRoot/packages")) {
    $RepoRoot = Split-Path $PSScriptRoot -Parent
    while ($RepoRoot -and -not (Test-Path "$RepoRoot/packages")) {
        $RepoRoot = Split-Path $RepoRoot -Parent
    }
}

if (-not $RepoRoot) {
    Write-Error "Cannot find repository root. Run from repo directory."
    exit 1
}

Write-Host "Repository root: $RepoRoot" -ForegroundColor Cyan

# Setup Rust PATH
$cargoBin = "$env:USERPROFILE\.cargo\bin"
if (Test-Path $cargoBin) {
    $env:CARGO_HOME = "$env:USERPROFILE\.cargo"
    $env:PATH = "$cargoBin;$env:PATH"
    Write-Host "Rust found at: $cargoBin" -ForegroundColor Green
} else {
    Write-Warning "Rust not found. Install from https://rustup.rs"
}

# Check prerequisites
$prereqs = @(
    @{Name="bun"; Command="bun --version"},
    @{Name="go"; Command="go version"},
    @{Name="rust"; Command="rustc --version"}
)

foreach ($prereq in $prereqs) {
    try {
        Invoke-Expression $prereq.Command | Out-Null
        Write-Host "[OK] $($prereq.Name)" -ForegroundColor Green
    } catch {
        Write-Host "[MISSING] $($prereq.Name)" -ForegroundColor Red
    }
}

# Clean if requested
if ($Clean) {
    Write-Host "`nCleaning previous builds..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "$RepoRoot/packages/opencode/dist" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "$RepoRoot/packages/desktop/dist" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "$RepoRoot/packages/desktop/src-tauri/target" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "$RepoRoot/packages/desktop/src-tauri/sidecars" -ErrorAction SilentlyContinue
}

# Build CLI
if (-not $DesktopOnly -and -not $SkipCli) {
    Write-Host "`n========== Building CLI ==========" -ForegroundColor Cyan
    
    Push-Location "$RepoRoot/packages/opencode"
    
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    bun install --no-cache
    
    Write-Host "Building CLI..." -ForegroundColor Yellow
    bun run script/build.ts --single --skip-install
    
    Pop-Location
    
    $cliExe = "$RepoRoot/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe"
    if (Test-Path $cliExe) {
        $cliSize = (Get-Item $cliExe).Length / 1MB
        Write-Host "[OK] CLI built: $cliExe ($([math]::Round($cliSize, 1)) MB)" -ForegroundColor Green
    } else {
        Write-Error "CLI build failed!"
        exit 1
    }
}

if ($CliOnly) {
    Write-Host "`nCLI build complete!" -ForegroundColor Green
    exit 0
}

# Prepare sidecar for desktop build
if (-not $SkipCli) {
    Write-Host "`n========== Preparing Sidecar ==========" -ForegroundColor Cyan
    
    $sidecarsDir = "$RepoRoot/packages/desktop/src-tauri/sidecars"
    New-Item -ItemType Directory -Force -Path $sidecarsDir | Out-Null
    
    $cliSrc = "$RepoRoot/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe"
    $cliDest1 = "$sidecarsDir/opencode-cli.exe"
    $cliDest2 = "$sidecarsDir/opencode-cli-x86_64-pc-windows-msvc.exe"
    
    Copy-Item $cliSrc $cliDest1 -Force
    Copy-Item $cliSrc $cliDest2 -Force
    
    Write-Host "[OK] Sidecar prepared" -ForegroundColor Green
}

# Build Desktop
if (-not $CliOnly) {
    Write-Host "`n========== Building Desktop App ==========" -ForegroundColor Cyan
    
    Push-Location "$RepoRoot/packages/desktop"
    
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    bun install --no-cache
    
    Write-Host "Building Tauri application..." -ForegroundColor Yellow
    Write-Host "This may take 5-15 minutes..." -ForegroundColor DarkGray
    
    bun run tauri build
    
    Pop-Location
    
    $desktopExe = "$RepoRoot/packages/desktop/src-tauri/target/release/OpenCode.exe"
    if (Test-Path $desktopExe) {
        $desktopSize = (Get-Item $desktopExe).Length / 1MB
        Write-Host "[OK] Desktop built: $desktopExe ($([math]::Round($desktopSize, 1)) MB)" -ForegroundColor Green
    } else {
        Write-Error "Desktop build failed!"
        exit 1
    }
}

# Summary
Write-Host "`n========== Build Summary ==========" -ForegroundColor Cyan

$cliExe = "$RepoRoot/packages/opencode/dist/opencode-windows-x64/bin/opencode.exe"
$desktopExe = "$RepoRoot/packages/desktop/src-tauri/target/release/OpenCode.exe"

if (Test-Path $cliExe) {
    $cliSize = (Get-Item $cliExe).Length / 1MB
    Write-Host "CLI:        $cliExe ($([math]::Round($cliSize, 1)) MB)" -ForegroundColor Green
}

if (Test-Path $desktopExe) {
    $desktopSize = (Get-Item $desktopExe).Length / 1MB
    Write-Host "Desktop:    $desktopExe ($([math]::Round($desktopSize, 1)) MB)" -ForegroundColor Green
}

Write-Host "`nBuild complete!" -ForegroundColor Green
