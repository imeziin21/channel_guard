## 0.2.2

- Redesigned package documentation.
- Updated installation and usage instructions.
- Added diagnostic rule descriptions and CLI examples.
- Updated CLI version display.

## 0.2.1

- Added unused MethodChannel detection (CG002).
- Added duplicate channel name detection (CG003).
- Added dynamic method name detection (CG004).
- Added dynamic channel name detection (CG005).
- Added empty method name detection (CG006).
- Fixed incorrect method call attribution for duplicate channels.
- Improved tracking of dynamically named method calls.

## 0.2.0

- Added CG002: potentially unused channel declarations.
- Added CG003: repeated channel names (informational).
- Added CG004: dynamic method names.
- Added CG005: dynamic channel names.
- Added CG006: empty method names.
- Added structured `issues` to JSON output and CLI diagnostics.
- Existing `--strict` behavior remains limited to parse errors.

# Changelog

## 0.1.0 - 2026-11-05

### Added
- AST-based Flutter MethodChannel declaration detection.
- MethodChannel method call tracking.
- Support for invokeMethod, invokeListMethod, and invokeMapMethod.
- Cross-file channel reference analysis.
- JSON output support.
- Colorful CLI output with optional color disabling.
- Static analysis tests and sample fixtures.