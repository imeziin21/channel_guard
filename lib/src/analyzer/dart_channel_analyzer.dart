import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

class DartChannelAnalyzer {
  void analyze(String fileLink) {
    final file = File(fileLink);
    final source = file.readAsStringSync();

    final result = parseString(content: source);
    result.unit.accept(ChannelVisitor());
  }
}

class ChannelVisitor extends RecursiveAstVisitor<void> {
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    print("Instance creation detected: $node");
    super.visitInstanceCreationExpression(node);
  }
  @override
  void visitMethodInvocation(MethodInvocation node) {
    final nodeName = node.methodName.name;
    final nodeArgument = node.argumentList.arguments;

    if (nodeName == "MethodChannel") {
      print('MethodChannel detected: $node');
      print('Argument count : ${nodeArgument.length}');

      if (nodeArgument.isNotEmpty) {
        final firstArgument = nodeArgument.first;
        
        if (firstArgument is StringLiteral) {
          print("Channel name : ${firstArgument.stringValue}");
        }
      }
    }
    super.visitMethodInvocation(node);
  }
}