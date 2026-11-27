<div align="center">

# CHANNEL GUARD

**Inspect channels. Trace calls. Detect issues.**

A lightweight Dart CLI for analyzing Flutter `MethodChannel` declarations, tracing method invocations, and detecting potential issues through static analysis.

[![Dart](https://img.shields.io/badge/Dart-CLI-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-MethodChannel-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![pub.dev](https://img.shields.io/pub/v/channel_guard?label=pub.dev&color=green)](https://pub.dev/packages/channel_guard)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-181717?logo=github&logoColor=white)](https://github.com/imeziin21/channel_guard)

</div>

---

## Overview

**Channel Guard** is a lightweight command-line static analysis tool designed to inspect Flutter platform-channel usage.

It scans Dart source files, identifies `MethodChannel` declarations, tracks statically identifiable method invocations, and reports potential issues with file locations and diagnostic codes.

Channel Guard provides a terminal-based interface for developers who want to inspect platform-channel usage without running their Flutter application.

### Key Features

- **Channel Detection** — Identifies literal `MethodChannel` declarations.
- **Method Tracking** — Tracks `invokeMethod`, `invokeListMethod`, and `invokeMapMethod` calls.
- **Static Diagnostics** — Detects potentially unused channels, duplicate declarations, dynamic names, and empty method names.
- **Source Locations** — Reports file paths and line numbers.
- **Recursive Scanning** — Analyzes individual Dart files or entire directories.
- **Terminal Interface** — Provides a colorized CLI report with channel information and diagnostics.
- **JSON Export** — Generates machine-readable reports for external tools.
- **Strict Mode** — Supports nonzero exit codes when parsing errors are detected.

---

## Installation

### Install from pub.dev

Install Channel Guard globally:

```bash
dart pub global activate channel_guard
```

Run the analyzer:

```bash
channel_guard .
```

If the command is not recognized, ensure the Dart global executable directory is included in your system's `PATH`.

### Install from source

Clone the repository:

```bash
git clone https://github.com/imeziin21/channel_guard.git
cd channel_guard
dart pub get
```

Run the included example:

```bash
dart run bin/channel_guard.dart fixtures/
```

### Requirements

- Dart SDK **3.11.3 or later**
- Flutter is not required to execute the CLI itself.

---

## Terminal Preview

Channel Guard features a terminal interface with color-coded status indicators, channel information, and diagnostic reports.

### Example Output

```text
root@channel-guard:~# ./channel_guard --scan

██████╗██╗  ██╗ █████╗ ███╗   ██╗███╗   ██╗███████╗██╗
██╔════╝██║  ██║██╔══██╗████╗  ██║████╗  ██║██╔════╝██║
██║     ███████║███████║██╔██╗ ██║██╔██╗ ██║█████╗  ██║
██║     ██╔══██║██╔══██║██║╚██╗██║██║╚██╗██║██╔══╝  ██║
╚██████╗██║  ██║██║  ██║██║ ╚████║██║ ╚████║███████╗███████╗
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚══════╝

CHANNEL GUARD  v0.2.2
MethodChannel Static Analysis Utility

[ SYSTEM ]
────────────────────────────────────────────────────────
[ OK ] Source discovery completed
[ OK ] Channel declarations collected
[ OK ] Method invocations resolved

[ SCAN REPORT ]
────────────────────────────────────────────────────────
FILES         6
CHANNELS      4
METHOD CALLS  2
DIAGNOSTICS   3

[ CHANNEL REGISTRY ]
────────────────────────────────────────────────────────

[01] test/native  [NO CALLS]
     VAR  channel
     AT   fixtures/sample_channel.dart:8
     └── No statically resolved method calls

[02] app/battery  [RESOLVED]
     VAR  battery
     AT   fixtures/sample_channel.dart:9
     └── INVOCATIONS
         > battery.invokeMethod('getBatteryLevel')
           fixtures/sample_channel.dart:14
         > battery.invokeMethod('getBatteryStatus')
           fixtures/sample_channel.dart:15

[03] app/camera  [NO CALLS]
     VAR  camera
     AT   fixtures/sample_channel.dart:10
     └── No statically resolved method calls

[04] app/location  [NO CALLS]
     VAR  location
     AT   fixtures/sample_channel.dart:11
     └── No statically resolved method calls

[ DIAGNOSTICS ]
────────────────────────────────────────────────────────

[ WARN ] CG002
LOCATION fixtures/sample_channel.dart:8
MESSAGE  No statically resolved calls found for "test/native".

[ WARN ] CG002
LOCATION fixtures/sample_channel.dart:10
MESSAGE  No statically resolved calls found for "app/camera".

[ WARN ] CG002
LOCATION fixtures/sample_channel.dart:11
MESSAGE  No statically resolved calls found for "app/location".

────────────────────────────────────────────────────────

STATUS  SCAN COMPLETED WITH WARNINGS
RESULT  3 diagnostic(s)

root@channel-guard:~# _
```

> **Note:** The output above is illustrative. Actual results depend on the scanned project. ANSI colors are displayed in supported terminals.

---

## Diagnostic Rules

Channel Guard reports potential issues using diagnostic codes.

| Code | Diagnostic | Description |
|------|------------|-------------|
| `CG002` | Unused Channel | No statically resolved method calls were found for a declared channel. |
| `CG003` | Duplicate Channel | Multiple declarations use the same channel name. |
| `CG004` | Dynamic Method Name | A method name is not a string literal. |
| `CG005` | Dynamic Channel Name | A channel name is not a string literal. |
| `CG006` | Empty Method Name | A method invocation uses an empty method name. |

### Diagnostic Behavior

Diagnostics are intended to highlight potentially problematic patterns.

They do not necessarily indicate runtime failures.

For example:

- `CG002` may be reported when a channel is used through dynamically resolved calls.
- `CG003` may identify duplicate channel names that are intentionally shared.
- `CG004` and `CG005` indicate values that cannot be determined directly from string literals.
- `CG006` identifies method invocations with empty method names.

Channel Guard uses static analysis heuristics and does not execute the inspected application.

---

## Usage

### Scan the Current Directory

```bash
channel_guard .
```

### Scan a Flutter Project

```bash
channel_guard /path/to/flutter_project/lib
```

### Scan a Single File

```bash
channel_guard lib/services/battery_service.dart
```

### Disable Terminal Colors

```bash
channel_guard lib/ --no-color
```

### Export JSON

```bash
channel_guard lib/ --json
```

### Save a JSON Report

```bash
channel_guard lib/ --json > channels.json
```

### Enable Strict Mode

```bash
channel_guard lib/ --strict
```

Strict mode exits with status code `1` when parsing errors are reported.

Diagnostic warnings such as `CG002`–`CG006` do not independently cause a nonzero exit code.

---

## CLI Options

| Option | Description |
|--------|-------------|
| `[path]` | Dart file or directory to scan. Defaults to the current directory. |
| `--json` | Print machine-readable JSON. |
| `--strict` | Exit with status code 1 if parsing errors are found. |
| `--no-color` | Disable ANSI terminal colors. |
| `--help`, `-h` | Display usage information. |

---

## JSON Output

Channel Guard supports structured JSON reports for scripts, development tools, and automated workflows.

Run:

```bash
channel_guard lib/ --json
```

Example:

```json
{
  "filesScanned": 1,
  "channels": [
    {
      "name": "app/battery",
      "file": "sample_channel.dart",
      "line": 9,
      "variable": "battery"
    }
  ],
  "calls": [
    {
      "channel": "app/battery",
      "method": "getBatteryLevel",
      "file": "sample_channel.dart",
      "line": 14
    }
  ],
  "issues": [],
  "errors": []
}
```

The JSON report includes:

- `filesScanned` — Number of Dart files scanned.
- `channels` — Discovered channel declarations.
- `calls` — Statically identified method invocations.
- `issues` — Diagnostic findings.
- `errors` — Parsing errors.

---

## Scope and Limitations

Channel Guard is a **best-effort static source scanner**, not a complete Dart semantic analyzer.

### Supported Analysis

- Literal `MethodChannel` declarations.
- Statically identifiable method invocations.
- Source file and line-number reporting.
- Selected cross-file references and imports.
- Diagnostic detection for supported patterns.

### Limitations

- Dynamically computed channel or method names may not be fully resolved.
- Complex aliases, imports, and scope relationships may affect analysis accuracy.
- Native platform implementations are not inspected.
- Kotlin, Java, Swift, and Objective-C code are outside the analysis scope.
- A successful scan does not guarantee correct runtime behavior.

**Channel Guard is intended as a development aid, not a security or runtime correctness guarantee.**

---

## Development

Clone the repository:

```bash
git clone https://github.com/imeziin21/channel_guard.git
cd channel_guard
dart pub get
```

### Static Analysis

```bash
dart analyze
```

### Run Tests

```bash
dart test
```

### Format Source Code

```bash
dart format .
```

### Validate Before Publishing

```bash
dart pub publish --dry-run
```

---

## Project Information

Channel Guard is built with Dart and the [`analyzer`](https://pub.dev/packages/analyzer) package.

| | |
|---|---|
| **Language** | Dart |
| **Framework Support** | Flutter |
| **Type** | Command-line static analysis tool |
| **Current Version** | 0.2.2 |
| **Dependencies** | `analyzer`, `path` |

**Repository:** https://github.com/imeziin21/channel_guard

**pub.dev:** https://pub.dev/packages/channel_guard

---

<div align="center">

### CHANNEL GUARD

**INSPECT · TRACE · DETECT**

A lightweight static analysis tool for Flutter MethodChannels.

</div>