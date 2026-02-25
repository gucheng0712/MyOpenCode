# Build Troubleshooting Reference

## Common Errors and Solutions

### 1. Rust/Cargo Not Found

**Error:**

```
cargo : The term 'cargo' is not recognized
```

**Cause:** Rust is installed but not in PATH, or not installed.

**Solution:**

```powershell
# Check if Rust exists
Test-Path C:\Users\$env:USERNAME\.cargo\bin\cargo.exe

# Add to PATH
$env:PATH = "C:\Users\$env:USERNAME\.cargo\bin;" + $env:PATH

# If not installed, install Rust
irm https://win.rustup.rs/x86_64 | iex
```

---

### 2. Sidecar Binary Not Found

**Error:**

```
resource path `sidecars\opencode-cli-x86_64-pc-windows-msvc.exe` doesn't exist
```

**Cause:** Tauri requires the sidecar binary with a specific naming convention.

**Solution:**

```powershell
# Copy CLI to sidecars with both required names
cp packages/opencode/dist/opencode-windows-x64/bin/opencode.exe `
   packages/desktop/src-tauri/sidecars/opencode-cli.exe

cp packages/desktop/src-tauri/sidecars/opencode-cli.exe `
   packages/desktop/src-tauri/sidecars/opencode-cli-x86_64-pc-windows-msvc.exe
```

**Naming Convention:**

- Base: `opencode-cli.exe`
- Target triple: `opencode-cli-x86_64-pc-windows-msvc.exe`

---

### 3. TypeScript Declaration Error

**Error:**

```
error TS1128: Declaration or statement expected
../app/src/custom-elements.d.ts(1,1)
```

**Cause:** The custom-elements.d.ts is a symlink that doesn't resolve correctly.

**Solution:**

```powershell
cp packages/ui/src/custom-elements.d.ts packages/app/src/custom-elements.d.ts
```

---

### 4. Bun Install Permission Error

**Error:**

```
EPERM: operation not permitted
```

**Cause:** Running in Git Bash with permission restrictions.

**Solution:** Use PowerShell instead:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "bun install --no-cache"
```

---

### 5. Build Timeout

**Error:** Build appears to hang or timeout.

**Cause:** Tauri builds are CPU-intensive and can take 10-15 minutes.

**Solution:**

- Wait longer (first build is slowest)
- Monitor with: `Get-Process | Where-Object { $_.ProcessName -like '*rustc*' }`
- Use `--single` flag to build only current platform

---

### 6. Go Build Cross-Compilation Issues

**Error:**

```
build constraints exclude all Go files
```

**Cause:** Cross-platform build attempted without proper setup.

**Solution:** Use `--single` flag:

```powershell
bun run script/build.ts --single --skip-install
```

---

### 7. WebView2 Not Found (Runtime)

**Error:** Application fails to start, mentions WebView2.

**Cause:** Windows lacks WebView2 runtime.

**Solution:** WebView2 is included in Windows 10 (1803+) and Windows 11. For older systems, download from Microsoft.

---

## Environment Variables

| Variable     | Purpose                | Example                         |
| ------------ | ---------------------- | ------------------------------- |
| `CARGO_HOME` | Rust cargo directory   | `C:\Users\Administrator\.cargo` |
| `PATH`       | Executable search path | Must include `.cargo\bin`       |
| `GOCACHE`    | Go build cache         | `D:\go-cache`                   |

## Directory Structure

```
opencode/
├── packages/
│   ├── opencode/          # CLI (Go)
│   │   ├── dist/          # CLI output
│   │   └── script/
│   │       └── build.ts   # Build script
│   ├── desktop/           # Desktop (Tauri)
│   │   ├── dist/          # Frontend output
│   │   └── src-tauri/
│   │       ├── sidecars/  # Embedded CLI
│   │       └── target/    # Rust build output
│   ├── app/               # Shared frontend
│   └── ui/                # UI components
└── bun.lockb              # Bun lockfile
```

## Build Times (Approximate)

| Component        | First Build   | Incremental |
| ---------------- | ------------- | ----------- |
| CLI              | 2-5 min       | 30 sec      |
| Desktop Frontend | 1-2 min       | 10-30 sec   |
| Desktop Backend  | 5-15 min      | 1-3 min     |
| **Total**        | **10-25 min** | **2-5 min** |

## Platform Support Matrix

| Platform    | Target Triple              | CLI Name       | Desktop Name   |
| ----------- | -------------------------- | -------------- | -------------- |
| Windows x64 | `x86_64-pc-windows-msvc`   | `opencode.exe` | `OpenCode.exe` |
| macOS ARM   | `aarch64-apple-darwin`     | `opencode`     | `OpenCode.app` |
| macOS Intel | `x86_64-apple-darwin`      | `opencode`     | `OpenCode.app` |
| Linux x64   | `x86_64-unknown-linux-gnu` | `opencode`     | `opencode`     |
