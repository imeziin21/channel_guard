import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

class DartChannelAnalyzer {
  void analyze(String fileLink) {
    final file = File(fileLink);
    final source = file.readAsStringSync();

    final result = parseString(content: source);
    
    final visitor = ChannelVisitor();
    result.unit.accept(visitor);
    print(visitor.channelName);
  }
}

class ChannelVisitor extends RecursiveAstVisitor<void> {
  final List<String> channelName = [];

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
          final name = firstArgument.stringValue;

          if (name != null) {
            channelName.add(name);
            print("Channel name : ${name}");
          }
        }
      }
    }
    super.visitMethodInvocation(node);
  }
}