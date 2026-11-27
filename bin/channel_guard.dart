import 'dart:convert';
import 'dart:io';

import 'package:channel_guard/channel_guard.dart';

const _reset = '\x1B[0m';
const _bold = '\x1B[1m';

const _green = '\x1B[38;5;46m';
const _softGreen = '\x1B[38;5;114m';
const _white = '\x1B[38;5;255m';
const _gray = '\x1B[38;5;245m';
const _yellow = '\x1B[38;5;220m';
const _red = '\x1B[38;5;196m';

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

      String paint(String text, String code, {bool bold = false}) {
        if (!color) return text;
        return '${bold ? _bold : ''}$code$text$_reset';
      }

      void out([String text = '']) => stdout.writeln(text);

      void rule() {
        out(
          paint(
            '  ────────────────────────────────────────────────────────',
            _gray,
          ),
        );
      }

      void heading(String title) {
        out();
        out(paint('  [ $title ]', _green, bold: true));
        rule();
      }

      String location(String file, int line) => '$file:$line';

      final totalIssues = report.issues.length + report.errors.length;

      // HEADER

      out();
      out(
        paint(
          '  root@channel-guard:~# ./channel_guard --scan',
          _green,
          bold: true,
        ),
      );
      out();

      out(
        paint(
          '  ██████╗██╗  ██╗ █████╗ ███╗   ██╗███╗   ██╗███████╗██╗',
          _softGreen,
        ),
      );
      out(
        paint(
          ' ██╔════╝██║  ██║██╔══██╗████╗  ██║████╗  ██║██╔════╝██║',
          _softGreen,
        ),
      );
      out(
        paint(
          ' ██║     ███████║███████║██╔██╗ ██║██╔██╗ ██║█████╗  ██║',
          _softGreen,
        ),
      );
      out(
        paint(
          ' ██║     ██╔══██║██╔══██║██║╚██╗██║██║╚██╗██║██╔══╝  ██║',
          _softGreen,
        ),
      );
      out(
        paint(
          ' ╚██████╗██║  ██║██║  ██║██║ ╚████║██║ ╚████║███████╗███████╗',
          _softGreen,
        ),
      );
      out(
        paint(
          '  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚══════╝',
          _softGreen,
        ),
      );

      out();
      out(
        '  ${paint('CHANNEL GUARD', _white, bold: true)}'
        '  ${paint('v0.2.1', _gray)}',
      );
      out(paint('  MethodChannel Static Analysis Utility', _gray));

      // SYSTEM LOGS

      heading('SYSTEM');

      out(
        '  ${paint('[ OK ]', _green)} '
        'Source discovery completed',
      );
      out(
        '  ${paint('[ OK ]', _green)} '
        'Channel declarations collected',
      );
      out(
        '  ${paint('[ OK ]', _green)} '
        'Method invocations resolved',
      );

      // SCAN REPORT

      heading('SCAN REPORT');

      out(
        '  ${paint('FILES', _gray)}         '
        '${paint('${report.files}', _white, bold: true)}',
      );
      out(
        '  ${paint('CHANNELS', _gray)}      '
        '${paint('${report.channels.length}', _white, bold: true)}',
      );
      out(
        '  ${paint('METHOD CALLS', _gray)}  '
        '${paint('${report.calls.length}', _white, bold: true)}',
      );
      out(
        '  ${paint('DIAGNOSTICS', _gray)}   '
        '${paint('$totalIssues', totalIssues == 0 ? _green : _yellow, bold: true)}',
      );

      // CHANNEL REGISTRY

      heading('CHANNEL REGISTRY');

      if (report.channels.isEmpty) {
        out(paint('  No MethodChannel declarations found.', _gray));
      }

      for (var i = 0; i < report.channels.length; i++) {
        final channel = report.channels[i];

        final methods = report.calls
            .where(
              (call) =>
                  call.channel == channel.name &&
                  (call.variable == null ||
                      call.file != channel.file ||
                      call.variable == channel.variable),
            )
            .toList();

        final active = methods.isNotEmpty;

        out();
        out(
          '  ${paint('[${(i + 1).toString().padLeft(2, '0')}]', _gray)} '
          '${paint(channel.name, _green, bold: true)}'
          '  ${paint(active ? '[RESOLVED]' : '[NO CALLS]', active ? _softGreen : _yellow)}',
        );

        out(
          '       ${paint('VAR', _gray)}  '
          '${paint(channel.variable, _white)}',
        );

        out(
          '       ${paint('AT', _gray)}   '
          '${paint(location(channel.file, channel.line), _gray)}',
        );

        if (methods.isEmpty) {
          out(paint('       └── No statically resolved method calls', _gray));
        } else {
          out(paint('       └── INVOCATIONS', _gray));

          for (final call in methods) {
            final method = call.method == '<dynamic>'
                ? '<dynamic>'
                : "'${call.method}'";

            final invocation =
                '${call.variable ?? channel.variable}.invokeMethod($method)';

            out(
              '           ${paint('>', _green)} '
              '${paint(invocation, _white, bold: true)}',
            );
            out('             ${paint(location(call.file, call.line), _gray)}');
          }
        }
      }

      // DIAGNOSTICS

      heading('DIAGNOSTICS');

      if (totalIssues == 0) {
        out();
        out(paint('  [ PASS ] No diagnostics detected.', _green, bold: true));
      }

      for (final issue in report.issues) {
        out();

        out(
          '  ${paint('[ WARN ]', _yellow, bold: true)} '
          '${paint(issue.code, _yellow, bold: true)}',
        );

        out(
          '  ${paint('LOCATION', _gray)} '
          '${paint(location(issue.file, issue.line), _white)}',
        );

        out(
          '  ${paint('MESSAGE', _gray)}  '
          '${paint(issue.message, _white)}',
        );
      }

      for (final error in report.errors) {
        out();
        out(
          '  ${paint('[ ERROR ]', _red, bold: true)} '
          '${paint(error, _white)}',
        );
      }

      // FINAL STATUS

      out();
      rule();
      out();

      final status = report.errors.isNotEmpty
          ? 'SCAN COMPLETED WITH PARSE ERRORS'
          : report.issues.isNotEmpty
          ? 'SCAN COMPLETED WITH WARNINGS'
          : 'SCAN COMPLETED SUCCESSFULLY';

      final statusColor = report.errors.isNotEmpty
          ? _red
          : report.issues.isNotEmpty
          ? _yellow
          : _green;

      out(
        '  ${paint('STATUS', _gray)}  '
        '${paint(status, statusColor, bold: true)}',
      );

      out(
        '  ${paint('RESULT', _gray)}  '
        '${paint('$totalIssues diagnostic(s)', statusColor)}',
      );

      out();
      out(paint('  root@channel-guard:~# _', _green));
      out();
    }

    if (arguments.contains('--strict') && report.errors.isNotEmpty) {
      exitCode = 1;
    }
  } on FileSystemException catch (error) {
    stderr.writeln('Error: ${error.message}: ${error.path}');
    exitCode = 66;
  }
}
