import 'dart:convert';
import 'dart:io';

import 'package:channel_guard/channel_guard.dart';

const _reset = '\x1B[0m';
const _lavender = '\x1B[38;5;141m';
const _mint = '\x1B[38;5;121m';
const _pink = '\x1B[38;5;218m';
const _yellow = '\x1B[38;5;221m';
const _muted = '\x1B[38;5;245m';

void main(List<String> arguments) {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln(
      'Usage: channel_guard [path] [--json] [--strict] [--no-color]',
    );
    stdout.writeln(
      'Scan a Dart file or directory (default: current directory).',
    );
    stdout.writeln('  --json       Print machine-readable JSON');
    stdout.writeln(
      '  --strict     Exit with code 1 if parsing errors are found',
    );
    stdout.writeln('  --no-color   Disable ANSI terminal colors');
    return;
  }
  final unknown = arguments
      .where(
        (a) =>
            a.startsWith('-') &&
            a != '--json' &&
            a != '--strict' &&
            a != '--no-color',
      )
      .toList();
  final paths = arguments.where((a) => !a.startsWith('-')).toList();
  if (unknown.isNotEmpty || paths.length > 1) {
    stderr.writeln('Invalid arguments. Use --help for usage.');
    exitCode = 64;
    return;
  }
  try {
    final report = DartChannelAnalyzer().analyze(
      paths.isEmpty ? '.' : paths.single,
    );
    if (arguments.contains('--json')) {
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(report.toJson()),
      );
    } else {
      final color =
          stdout.supportsAnsiEscapes &&
          !arguments.contains('--no-color') &&
          !Platform.environment.containsKey('NO_COLOR');
      String tint(String value, String ansi) =>
          color ? '$ansi$value$_reset' : value;
      stdout.writeln(
        tint('╭──────────────────────────────────────────────╮', _lavender),
      );
      stdout.writeln(
        tint('│  ✿  Channel Guard                           │', _lavender),
      );
      stdout.writeln(
        tint('│     your tiny MethodChannel guardian        │', _muted),
      );
      stdout.writeln(
        tint('╰──────────────────────────────────────────────╯', _lavender),
      );
      stdout.writeln();
      stdout.writeln(tint('  ◇  SCAN COMPLETE', _mint));
      stdout.writeln(
        tint('  ──────────────────────────────────────────', _muted),
      );
      stdout.writeln('  ✦  Files scanned       ${report.files}');
      stdout.writeln('  ✦  Channels found      ${report.channels.length}');
      stdout.writeln('  ✦  Method calls        ${report.calls.length}');
      stdout.writeln('  ✦  Issues detected     ${report.errors.length}');
      stdout.writeln();
      stdout.writeln(tint('  ♡  DISCOVERED CHANNELS', _pink));
      stdout.writeln(
        tint('  ──────────────────────────────────────────', _muted),
      );
      if (report.channels.isEmpty) {
        stdout.writeln('  No MethodChannel declarations found.');
      }
      for (var i = 0; i < report.channels.length; i++) {
        final channel = report.channels[i];
        final methods = report.calls
            .where((call) => call.channel == channel.name)
            .toList();
        stdout.writeln();
        stdout.writeln(
          tint(
            '  ${(i + 1).toString().padLeft(2, '0')}  ✿ ${channel.name}',
            _lavender,
          ),
        );
        stdout.writeln('      ├─ variable   ${channel.variable}');
        stdout.writeln('      ├─ location   ${channel.file}:${channel.line}');
        if (methods.isEmpty) {
          stdout.writeln(tint('      └─ no method calls found', _muted));
        } else {
          for (var j = 0; j < methods.length; j++) {
            final call = methods[j];
            final branch = j == methods.length - 1 ? '└' : '├';
            stdout.writeln(
              '      $branch─ ${tint('✧ ${call.method}()', _mint)}',
            );
            stdout.writeln(tint('         ${call.file}:${call.line}', _muted));
          }
        }
      }
      if (report.errors.isNotEmpty) {
        stdout.writeln();
        stdout.writeln(tint('  ⚠  ISSUES', _yellow));
        for (final error in report.errors) {
          stdout.writeln('  • $error');
        }
      }
      stdout.writeln();
      stdout.writeln(
        tint('  ──────────────────────────────────────────', _muted),
      );
      stdout.writeln(
        report.errors.isEmpty
            ? tint('  ✓  All done! Your channels look lovely. ✿', _mint)
            : tint(
                '  !  Scan finished with ${report.errors.length} issue(s).',
                _yellow,
              ),
      );
    }
    if (arguments.contains('--strict') && report.errors.isNotEmpty) {
      exitCode = 1;
    }
  } on FileSystemException catch (error) {
    stderr.writeln('Error: ${error.message}: ${error.path}');
    exitCode = 66;
  }
}
