import 'package:channel_guard/src/analyzer/dart_channel_analyzer.dart';

void main() {
  final analyzer = DartChannelAnalyzer();

  analyzer.analyze('fixtures/sample_channel.dart');
}
