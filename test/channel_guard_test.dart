import 'dart:io';
import 'package:channel_guard/channel_guard.dart';
import 'package:test/test.dart';

void main() {
  test('detects channel declarations and calls', () {
    final dir = Directory.systemTemp.createTempSync('channel_guard_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/sample.dart');
    file.writeAsStringSync('''
import 'package:flutter/services.dart';
class Example {
  static const channel = MethodChannel('app/battery');
  void check() {
    channel.invokeMethod('getBatteryLevel');
    channel.invokeListMethod('getHistory');
  }
}
''');
    final result = DartChannelAnalyzer().analyze(file.path);
    expect(result.files, 1);
    expect(result.channels.single.name, 'app/battery');
    expect(
      result.calls.map((e) => e.method),
      containsAll(['getBatteryLevel', 'getHistory']),
    );
  });

  test('does not report unrelated method calls', () {
    final dir = Directory.systemTemp.createTempSync('channel_guard_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/sample.dart');
    file.writeAsStringSync('''
class Other { void invokeMethod(String name) {} }
void test() { final other = Other(); other.invokeMethod('unrelated'); }
''');
    final result = DartChannelAnalyzer().analyze(file.path);
    expect(result.calls, isEmpty);
  });
  test('tracks calls across files and all supported invocation methods', () {
    final dir = Directory.systemTemp.createTempSync('channel_guard_multi_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File(
      '${dir.path}/declarations.dart',
    ).writeAsStringSync("const channel = MethodChannel('app/test');");
    File('${dir.path}/calls.dart').writeAsStringSync(
      '''import 'declarations.dart';
void run() {
  channel.invokeMethod('one');
  channel.invokeListMethod('two');
  channel.invokeMapMethod('three');
}
''',
    );
    final report = DartChannelAnalyzer().analyze(dir.path);
    expect(report.files, 2);
    expect(report.channels.single.name, 'app/test');
    expect(
      report.calls.map((e) => e.method),
      containsAll(['one', 'two', 'three']),
    );
  });

  test('does not associate channels from files without imports', () {
    final dir = Directory.systemTemp.createTempSync('channel_guard_isolation_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File(
      '${dir.path}/a.dart',
    ).writeAsStringSync("final channel = MethodChannel('one');");
    File(
      '${dir.path}/b.dart',
    ).writeAsStringSync("void run() => channel.invokeMethod('unrelated');");
    final report = DartChannelAnalyzer().analyze(dir.path);
    expect(report.calls, isEmpty);
  });

  test('does not guess ambiguous cross-file channel names', () {
    final dir = Directory.systemTemp.createTempSync('channel_guard_ambiguous_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File(
      '${dir.path}/a.dart',
    ).writeAsStringSync("final channel = MethodChannel('one');");
    File(
      '${dir.path}/b.dart',
    ).writeAsStringSync("final channel = MethodChannel('two');");
    File(
      '${dir.path}/c.dart',
    ).writeAsStringSync("void run() => channel.invokeMethod('unknown');");
    final report = DartChannelAnalyzer().analyze(dir.path);
    expect(report.calls, isEmpty);
  });

  test('reports paths relative to the scanned directory', () {
    final dir = Directory.systemTemp.createTempSync('channel_guard_paths_');
    addTearDown(() => dir.deleteSync(recursive: true));
    Directory('${dir.path}/src').createSync();
    File('${dir.path}/src/example.dart').writeAsStringSync(
      '''final channel = MethodChannel('example');
void call() => channel.invokeMethod('ping');
''',
    );
    final report = DartChannelAnalyzer().analyze(dir.path);
    expect(report.channels.single.file, 'src/example.dart');
    expect(report.calls.single.file, 'src/example.dart');
  });

  test('resolves prefixed relative imports', () {
    final dir = Directory.systemTemp.createTempSync('channel_guard_prefix_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File(
      '${dir.path}/channels.dart',
    ).writeAsStringSync("final battery = MethodChannel('app/battery');");
    File('${dir.path}/use.dart').writeAsStringSync(
      '''import 'channels.dart' as native;
void run() => native.battery.invokeMapMethod('status');
''',
    );
    final report = DartChannelAnalyzer().analyze(dir.path);
    expect(report.calls.single.channel, 'app/battery');
    expect(report.calls.single.method, 'status');
  });

  test('tracks locally declared channels and avoids shadowed variables', () {
    final dir = Directory.systemTemp.createTempSync('channel_guard_scope_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/sample.dart').writeAsStringSync("""
final channel = MethodChannel('top');
void run() {
  channel.invokeMethod('outer');
  {
    final channel = Other();
    channel.invokeMethod('notAChannel');
  }
  final local = MethodChannel('local');
  local.invokeMapMethod('inner');
}
""");
    final report = DartChannelAnalyzer().analyze(dir.path);
    expect(report.calls.map((e) => e.method), containsAll(['outer', 'inner']));
    expect(report.calls.map((e) => e.method), isNot(contains('notAChannel')));
  });

  test('honors show and hide on local imports', () {
    final dir = Directory.systemTemp.createTempSync(
      'channel_guard_combinators_',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/channels.dart').writeAsStringSync("""
final visible = MethodChannel('visible');
final hidden = MethodChannel('hidden');
""");
    File('${dir.path}/use.dart').writeAsStringSync("""
import 'channels.dart' show visible;
void run() {
  visible.invokeMethod('yes');
  hidden.invokeMethod('no');
}
""");
    final report = DartChannelAnalyzer().analyze(dir.path);
    expect(report.calls.map((e) => e.method), contains('yes'));
    expect(report.calls.map((e) => e.method), isNot(contains('no')));
  });

  test('tracks direct MethodChannel invocation', () {
    final dir = Directory.systemTemp.createTempSync('channel_guard_direct_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/sample.dart').writeAsStringSync(
      "void run() => MethodChannel('direct').invokeMethod('ping');",
    );
    final report = DartChannelAnalyzer().analyze(dir.path);
    expect(report.calls.single.channel, 'direct');
    expect(report.calls.single.method, 'ping');
  });
}

// Additional regression coverage for multi-file and alternative invocation APIs.
