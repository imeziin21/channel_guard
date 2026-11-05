# Channel Guard

A Dart CLI tool for inspecting Flutter `MethodChannel` declarations and their statically identifiable method invocations.

## Setup

Requires Dart SDK >= 3.11.3.

```bash
dart pub get
```

## Run

```bash
dart run bin/channel_guard.dart lib/
dart run bin/channel_guard.dart lib/ --json
dart run bin/channel_guard.dart lib/ --strict
```

To install locally as a command:

```bash
dart pub global activate --source path .
channel_guard lib/
```

## Output

Reports each literal `MethodChannel('channel/name')` declaration, its file and line, and literal `invokeMethod`, `invokeListMethod`, or `invokeMapMethod` calls resolved to that channel in the same Dart file. JSON mode is suitable for CI and other tools. `--strict` returns a nonzero exit code when parser diagnostics are present.

## Limitations

This is a **static, best-effort source scanner**, not a full Dart type resolver. It does not evaluate dynamically computed channel or method names, resolve references across files, or verify native Android/iOS implementations. Variables with the same name in different lexical scopes may be conflated. Results should be reviewed before relying on them for correctness or security checks.

## Test

```bash
dart test
```
