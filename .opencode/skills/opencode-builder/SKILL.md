---
name: opencode-builder
description: |
  Build OpenCode desktop application and CLI tools from source. Use when the user wants to:
  (1) Compile OpenCode desktop GUI application (Tauri-based)
  (2) Build OpenCode CLI tool (Go-based)
  (3) Package the application for distribution
  (4) Set up build environment for OpenCode development

  Triggers: "build opencode", "compile opencode", "build desktop app", "build CLI tool", "package opencode", "tauri build"
---

# OpenCode Builder

Build OpenCode desktop application (Tauri + SolidJS) and CLI tool (Go) from source.

## Prerequisites

Before building, ensure these tools are installed:

| Tool | Version | Check Command     | Install                                   |
| ---- | ------- | ----------------- | ----------------------------------------- |
| Bun  | >= 1.0  | `bun --version`   | `irm bun.sh/install.ps1 \| iex`           |
| Go   | >= 1.21 | `go version`      | Download from go.dev                      |
| Rust | >= 1.70 | `rustc --version` | `irm https://win.rustup.rs/x86_64 \| iex` |
| Git  | >= 2.0  | `git --version`   | Download from git-scm.com                 |

### Rust Installation (Windows)

If Rust is not in PATH, it may still be installed. Check:

```bash
ls ~/.cargo/bin/rustc.exe
```

Add to PATH if needed:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

## Build Order

**Critical**: Build in this exact order due to dependencies:

1. **CLI Tool** → Required by Desktop app as sidecar
2. **Desktop App** → Embeds CLI tool

## Step 1: Build CLI Tool

The CLI is a Go application located in `packages/opencode/`.

```bash
cd packages/opencode
bun install --no-cache
bun run script/build.ts --single --skip-install
```

### Build Options

| Flag                 | Description                      |
| -------------------- | -------------------------------- |
| `--single`           | Build only current platform      |
| `--skip-install`     | Skip cross-platform dependencies |
| `--skip-postinstall` | Skip postinstall scripts         |

### Build Output

```
packages/opencode/dist/
├── opencode-windows-x64/
│   └── bin/
│       └── opencode.exe      # Windows executable (~160MB)
├── opencode-darwin-arm64/    # macOS ARM
├── opencode-darwin-x64/      # macOS Intel
└── opencode-linux-x64/       # Linux
```

## Step 2: Build Desktop Application

The desktop app is a Tauri application with SolidJS frontend.

### 2.1 Fix TypeScript Declaration (REQUIRED)

Before building, fix the custom-elements.d.ts issue:

```bash
cp packages/ui/src/custom-elements.d.ts packages/app/src/custom-elements.d.ts
```

### 2.2 Install Dependencies

```bash
cd packages/desktop
bun install --no-cache
```

### 2.3 Prepare Sidecar Binary

The desktop app requires the CLI as an embedded "sidecar" binary:

```bash
# Create sidecars directory and copy CLI
mkdir -p packages/desktop/src-tauri/sidecars
cp packages/opencode/dist/opencode-windows-x64/bin/opencode.exe packages/desktop/src-tauri/sidecars/opencode-cli.exe
cp packages/desktop/src-tauri/sidecars/opencode-cli.exe packages/desktop/src-tauri/sidecars/opencode-cli-x86_64-pc-windows-msvc.exe
```

### 2.4 Build Desktop App

```bash
cd packages/desktop
bun run tauri build
```

### Build Output

```
packages/desktop/src-tauri/target/release/
├── OpenCode.exe              # Main application (~31MB)
├── opencode-cli.exe          # Embedded CLI (~160MB)
└── bundle/
    └── nsis/
        └── OpenCode_*.exe    # NSIS installer (if bundled)
```

## Troubleshooting

### Error: "cargo not found"

Rust is installed but not in PATH:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

### Error: "sidecars\opencode-cli-\*.exe doesn't exist"

The CLI must be copied with the exact name Tauri expects:

- `opencode-cli.exe` (base name)
- `opencode-cli-x86_64-pc-windows-msvc.exe` (target triple)

### Build Hangs or Times Out

Tauri builds can take 5-15 minutes on first run. The Rust compilation is CPU-intensive. Monitor progress:

```bash
# Check if cargo is still running
ps aux | grep -E 'cargo|rustc'
```

## Quick Reference

```bash
# Full build from root (D:\GitRepo\MyOpenCode)

# 1. Build CLI
cd packages/opencode
bun install --no-cache
bun run script/build.ts --single --skip-install

# 2. Fix TypeScript declaration (REQUIRED)
cd ../..
cp packages/ui/src/custom-elements.d.ts packages/app/src/custom-elements.d.ts

# 3. Prepare sidecar
mkdir -p packages/desktop/src-tauri/sidecars
cp packages/opencode/dist/opencode-windows-x64/bin/opencode.exe packages/desktop/src-tauri/sidecars/opencode-cli.exe
cp packages/desktop/src-tauri/sidecars/opencode-cli.exe packages/desktop/src-tauri/sidecars/opencode-cli-x86_64-pc-windows-msvc.exe

# 4. Build desktop
cd packages/desktop
bun install --no-cache
bun run tauri build
```

## Platform-Specific Notes

### Windows

- Requires WebView2 (included in Windows 10/11)
- NSIS installer generated automatically
- Target triple: `x86_64-pc-windows-msvc`

### macOS

- Requires Xcode Command Line Tools
- Target triple: `aarch64-apple-darwin` (ARM) or `x86_64-apple-darwin` (Intel)

### Linux

- Requires `libwebkit2gtk-4.1-dev`, `build-essential`, etc.
- Target triple: `x86_64-unknown-linux-gnu`
