<div align="center">

# ✿ Channel Guard

**Your tiny MethodChannel guardian.**

A lightweight Dart CLI that finds Flutter `MethodChannel` declarations and maps statically identifiable method calls — with a little terminal charm. 🌷

[![Dart](https://img.shields.io/badge/Dart-CLI-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-MethodChannel-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)

</div>

## ✨ What it does

- 🔎 Finds literal `MethodChannel` declarations in Dart source files.
- 🧩 Maps calls to `invokeMethod`, `invokeListMethod`, and `invokeMapMethod` where the channel can be identified statically.
- 📍 Reports source file paths and line numbers.
- 🌿 Scans a Dart file or a directory recursively.
- 🎀 Shows a friendly, colorized terminal report (or plain text with `--no-color`).
- 📦 Exports machine-readable JSON with `--json`.
- ⚠️ Supports `--strict` to exit with code 1 when parser errors are reported.

## 🛠 Requirements

- Dart SDK **3.11.3 or later** (as declared in `pubspec.yaml`)

## 🚀 Quick start

Clone the repository and install dependencies:

```bash
git clone https://github.com/imeziin21/channel_guard.git
cd channel_guard
dart pub get
```

Scan the included example:

```bash
dart run bin/channel_guard.dart fixtures/
```

Scan a Flutter project's Dart source directory from the Channel Guard repository:

```bash
dart run bin/channel_guard.dart /path/to/flutter_project/lib
```

Or scan a single file:

```bash
dart run bin/channel_guard.dart /path/to/file.dart
```

## 🌸 Terminal preview

```text
╭──────────────────────────────────────────────╮
│  ✿  Channel Guard                           │
│     your tiny MethodChannel guardian        │
╰──────────────────────────────────────────────╯

  ◇  SCAN COMPLETE
  ──────────────────────────────────────────
  ✦  Files scanned       1
  ✦  Channels found      1
  ✦  Method calls        2
  ✦  Issues detected     0

  ♡  DISCOVERED CHANNELS
  ──────────────────────────────────────────

  01  ✿ app/battery
      ├─ variable   battery
      ├─ location   sample_channel.dart:9
      ├─ ✧ getBatteryLevel()
      └─ ✧ getBatteryStatus()

  ──────────────────────────────────────────
  ✓  All done! Your channels look lovely. ✿
```

*Illustrative output; actual file paths and formatting depend on the scanned project.*

## ⌨️ CLI options

| Option | Description |
| --- | --- |
| `[path]` | Dart file or directory to scan; defaults to the current directory. |
| `--json` | Print JSON instead of the decorative report. |
| `--strict` | Exit with status 1 if parser errors are found. |
| `--no-color` | Disable ANSI colors in human-readable output. |
| `--help`, `-h` | Display usage information. |

```bash
dart run bin/channel_guard.dart fixtures/ --json
dart run bin/channel_guard.dart fixtures/ --no-color
dart run bin/channel_guard.dart fixtures/ --strict
```

## 🧾 JSON example

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
  "errors": []
}
```

Save a report to a file:

```bash
dart run bin/channel_guard.dart /path/to/flutter_project/lib --json > channels.json
```

## 🧪 Development checks

```bash
dart analyze
dart test
```

## ⚠️ Scope and limitations

Channel Guard is a **best-effort static source scanner**, not a full Dart semantic analyzer. It works best with literal channel and method names. Dynamically computed names and some complex aliases, imports, or scope relationships may not be resolved correctly. It **does not validate Kotlin/Java or Swift/Objective-C native implementations**, and a clean scan does not guarantee correct platform-channel behavior at runtime.

Use the results as a development aid, not as a security or correctness guarantee.

## 💜 Project

Built with Dart and the [`analyzer`](https://pub.dev/packages/analyzer) package.

Repository: https://github.com/imeziin21/channel_guard
