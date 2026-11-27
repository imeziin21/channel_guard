import 'dart:io';
import 'package:channel_guard/channel_guard.dart';
import 'package:test/test.dart';

void main() {
  test('reports new diagnostics', () {
    final dir = Directory.systemTemp.createTempSync('cg_v020_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/main.dart').writeAsStringSync("""final unused = MethodChannel('unused');
final duplicateA = MethodChannel('duplicate');
final duplicateB = MethodChannel('duplicate');
final dynamicChannel = MethodChannel(getName());
void go() {
  duplicateA.invokeMethod('');
  duplicateB.invokeMethod(getMethod());
}
""");
    final report = DartChannelAnalyzer().analyze(dir.path);
    final codes = report.issues.map((e) => e.code).toSet();
    expect(codes, containsAll(['CG002', 'CG003', 'CG004', 'CG005', 'CG006']));
    expect(report.toJson()['issues'], isNotEmpty);
    final duplicateCalls = report.calls.where((c) => c.channel == 'duplicate').toList();
    expect(duplicateCalls.map((c) => c.variable), containsAll(['duplicateA', 'duplicateB']));
  });
}

// Regression: same-name channels must not inherit each other's calls.
