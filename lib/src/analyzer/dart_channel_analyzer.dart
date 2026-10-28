import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class DartChannelAnalyzer {
  void analyze(String fileLink) {
    final file = File(fileLink);
    final source = file.readAsStringSync();
    final result = parseString(content: source);

    final visitor = ChannelVisitor();
    result.unit.accept(visitor);

    print('Channels: ${visitor.channels}');
    print('Methods: ${visitor.methodNames}');
    print('Channel methods: ${visitor.channelsMethods}');
  }
}

class ChannelVisitor extends RecursiveAstVisitor<void> {
  final Map<String, String> channels = {};
  final List<String> methodNames = [];
  final Map<String, List<String>> channelsMethods = {};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;

    if (initializer is MethodInvocation &&
        initializer.methodName.name == 'MethodChannel') {
      final arguments = initializer.argumentList.arguments;

      if (arguments.isNotEmpty && arguments.first is StringLiteral) {
        final channelName = (arguments.first as StringLiteral).stringValue;

        if (channelName != null) {
          channels[node.name.lexeme] = channelName;
        }
      }
    }

    super.visitVariableDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'invokeMethod') {
      final target = node.target;

      if (target is SimpleIdentifier) {
        final variableName = target.toSource();
        final channelName = channels[variableName];
        print('Channel variable: $variableName');
        print('Resolved channel: $channelName');
        final arguments = node.argumentList.arguments;
        print(node.target);

        if (arguments.isNotEmpty && arguments.first is StringLiteral) {
          final methodName = (arguments.first as StringLiteral).stringValue;

          if (methodName != null) {
            methodNames.add(methodName);

            if (channelName != null) {
              channelsMethods.putIfAbsent(channelName, () => []).add(methodName);
            }
          }
        }
      }
    }

    super.visitMethodInvocation(node);
  }
}