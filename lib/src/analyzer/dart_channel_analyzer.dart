import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

class ChannelInfo {
  const ChannelInfo(this.name, this.file, this.line, this.variable);
  final String name;
  final String file;
  final int line;
  final String variable;
  Map<String, Object> toJson() => {
    'name': name,
    'file': file,
    'line': line,
    'variable': variable,
  };
}

class ChannelCall {
  const ChannelCall(this.channel, this.method, this.file, this.line);
  final String channel;
  final String method;
  final String file;
  final int line;
  Map<String, Object> toJson() => {
    'channel': channel,
    'method': method,
    'file': file,
    'line': line,
  };
}

class AnalysisReport {
  const AnalysisReport(this.channels, this.calls, this.files, this.errors);
  final List<ChannelInfo> channels;
  final List<ChannelCall> calls;
  final int files;
  final List<String> errors;
  Map<String, Object> toJson() => {
    'filesScanned': files,
    'channels': channels.map((e) => e.toJson()).toList(),
    'calls': calls.map((e) => e.toJson()).toList(),
    'errors': errors,
  };
}

class DartChannelAnalyzer {
  AnalysisReport analyze(String path) {
    final kind = FileSystemEntity.typeSync(path);
    if (kind == FileSystemEntityType.notFound) {
      throw FileSystemException('Path does not exist', path);
    }
    final files = kind == FileSystemEntityType.file
        ? <File>[File(path)]
        : Directory(path)
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart') && !_excluded(f.path))
              .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    final root = kind == FileSystemEntityType.file
        ? p.dirname(p.absolute(path))
        : p.absolute(path);
    final units = <_Unit>[];
    final errors = <String>[];
    for (final file in files) {
      final absolute = p.normalize(file.absolute.path);
      final display = p.relative(absolute, from: root);
      try {
        final result = parseString(
          content: file.readAsStringSync(),
          path: absolute,
          throwIfDiagnostics: false,
        );
        units.add(_Unit(absolute, display, result.unit, result.lineInfo));
        for (final error in result.errors) {
          errors.add('$display: ${error.message}');
        }
      } on FileSystemException catch (error) {
        errors.add('$display: ${error.message}');
      } on FormatException catch (error) {
        errors.add('$display: ${error.message}');
      }
    }

    final declarations = <ChannelInfo>[];
    final exported = <String, Map<String, String>>{};
    for (final unit in units) {
      final collector = _DeclarationCollector(unit);
      unit.ast.accept(collector);
      declarations.addAll(collector.found);
      exported[unit.path] = collector.topLevel;
    }

    final calls = <ChannelCall>[];
    for (final unit in units) {
      final visible = <String, String>{...?exported[unit.path]};
      final prefixes = <String, Map<String, String>>{};
      final conflicts = <String>{};
      for (final directive in unit.ast.directives) {
        if (directive is! ImportDirective) continue;
        final uri = directive.uri.stringValue;
        if (uri == null ||
            !uri.endsWith('.dart') ||
            uri.startsWith('dart:') ||
            uri.startsWith('package:'))
          continue;
        final imported = p.normalize(
          p.join(p.dirname(unit.path), Uri.decodeFull(uri)),
        );
        final source = <String, String>{...?exported[imported]};
        // Combinators are respected for locally imported top-level symbols.
        for (final combinator in directive.combinators) {
          if (combinator is ShowCombinator) {
            final allowed = combinator.shownNames.map((e) => e.name).toSet();
            source.removeWhere((key, value) => !allowed.contains(key));
          } else if (combinator is HideCombinator) {
            final hidden = combinator.hiddenNames.map((e) => e.name).toSet();
            source.removeWhere((key, value) => hidden.contains(key));
          }
        }
        if (directive.prefix != null) {
          prefixes.putIfAbsent(directive.prefix!.name, () => {}).addAll(source);
        } else {
          for (final entry in source.entries) {
            if (visible.containsKey(entry.key) &&
                visible[entry.key] != entry.value) {
              conflicts.add(entry.key);
            } else {
              visible[entry.key] = entry.value;
            }
          }
        }
      }
      for (final name in conflicts) {
        visible.remove(name);
      }
      final collector = _CallCollector(unit, visible, prefixes);
      unit.ast.accept(collector);
      calls.addAll(collector.found);
    }
    return AnalysisReport(declarations, calls, files.length, errors);
  }

  bool _excluded(String path) => path
      .replaceAll('\\', '/')
      .split('/')
      .any((part) => {'.dart_tool', 'build', '.git', '.idea'}.contains(part));
}

class _Unit {
  const _Unit(this.path, this.displayPath, this.ast, this.lines);
  final String path;
  final String displayPath;
  final CompilationUnit ast;
  final LineInfo lines;
  int line(AstNode node) => lines.getLocation(node.offset).lineNumber;
}

ArgumentList? _channelArguments(Expression? expression) {
  if (expression is InstanceCreationExpression &&
      expression.constructorName.type.name.lexeme == 'MethodChannel') {
    return expression.argumentList;
  }
  if (expression is MethodInvocation &&
      expression.target == null &&
      expression.methodName.name == 'MethodChannel') {
    return expression.argumentList;
  }
  return null;
}

String? _literal(Argument argument) =>
    argument is StringLiteral ? argument.stringValue : null;

class _DeclarationCollector extends RecursiveAstVisitor<void> {
  _DeclarationCollector(this.unit);
  final _Unit unit;
  final found = <ChannelInfo>[];
  final topLevel = <String, String>{};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final args = _channelArguments(node.initializer)?.arguments;
    if (args != null && args.isNotEmpty) {
      final name = _literal(args.first);
      if (name != null) {
        final variable = node.name.lexeme;
        found.add(
          ChannelInfo(name, unit.displayPath, unit.line(node), variable),
        );
        // Only actual top-level variables are importable by other libraries.
        if (node.parent?.parent is TopLevelVariableDeclaration &&
            !variable.startsWith('_')) {
          topLevel[variable] = name;
        }
      }
    }
    super.visitVariableDeclaration(node);
  }
}

class _CallCollector extends RecursiveAstVisitor<void> {
  _CallCollector(this.unit, this.imported, this.prefixes);
  final _Unit unit;
  final Map<String, String> imported;
  final Map<String, Map<String, String>> prefixes;
  final found = <ChannelCall>[];
  final scopes = <Map<String, String?>>[];

  String? _resolve(String name) {
    for (final scope in scopes.reversed) {
      if (scope.containsKey(name)) return scope[name];
    }
    return imported[name];
  }

  void _enter(AstNode node, void Function() visit) {
    scopes.add(<String, String?>{});
    try {
      visit();
    } finally {
      scopes.removeLast();
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _enter(node, () => super.visitCompilationUnit(node));
  }

  @override
  void visitBlock(Block node) {
    _enter(node, () => super.visitBlock(node));
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _enter(node, () => super.visitClassDeclaration(node));
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final args = _channelArguments(node.initializer)?.arguments;
    final name = args != null && args.isNotEmpty ? _literal(args.first) : null;
    if (scopes.isNotEmpty) {
      scopes.last[node.name.lexeme] = name;
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    const methods = {'invokeMethod', 'invokeListMethod', 'invokeMapMethod'};
    if (methods.contains(node.methodName.name) && node.target != null) {
      final target = node.target!;
      String? channel;
      if (target is SimpleIdentifier) {
        channel = _resolve(target.name);
      } else if (target is PrefixedIdentifier) {
        channel = prefixes[target.prefix.name]?[target.identifier.name];
      } else if (target is PropertyAccess &&
          target.target is SimpleIdentifier) {
        final prefix = (target.target! as SimpleIdentifier).name;
        channel = prefixes[prefix]?[target.propertyName.name];
        // Do not guess arbitrary object fields based on matching names.
      } else {
        final args = _channelArguments(target)?.arguments;
        if (args != null && args.isNotEmpty) channel = _literal(args.first);
      }
      final args = node.argumentList.arguments;
      if (channel != null && args.isNotEmpty) {
        final method = _literal(args.first);
        if (method != null) {
          found.add(
            ChannelCall(channel, method, unit.displayPath, unit.line(node)),
          );
        }
      }
    }
    super.visitMethodInvocation(node);
  }
}
