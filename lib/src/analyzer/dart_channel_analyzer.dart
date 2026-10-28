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
  }
}

class ChannelVisitor extends RecursiveAstVisitor<void> {
  final Map<String, String> channels = {};
  final List<String> methodNames = [];

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
      final arguments = node.argumentList.arguments;

      if (arguments.isNotEmpty && arguments.first is StringLiteral) {
        final methodName = (arguments.first as StringLiteral).stringValue;

        if (methodName != null) {
          methodNames.add(methodName);
        }
      }
    }

    super.visitMethodInvocation(node);
  }
}