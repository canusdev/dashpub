import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/bash.dart';

class CodeSyntaxHighlighter extends SyntaxHighlighter {
  final Map<String, TextStyle> _theme;

  CodeSyntaxHighlighter(this._theme);

  @override
  TextSpan format(String source) {
    return formatWithLanguage(source, null);
  }

  TextSpan formatWithLanguage(String source, String? language) {
    language ??= 'dart';
    // Handle 'sh' as bash
    if (language == 'sh' || language == 'shell') language = 'bash';

    try {
      var result = highlight.highlight.parse(source, language: language);
      return TextSpan(style: _theme['root'], children: _convert(result.nodes));
    } catch (e) {
      // Fallback to auto-detection or plain text if language not found
      var result = highlight.highlight.parse(source, autoDetection: true);
      return TextSpan(style: _theme['root'], children: _convert(result.nodes));
    }
  }

  List<TextSpan>? _convert(List<highlight.Node>? nodes) {
    if (nodes == null) return null;
    List<TextSpan> spans = [];
    for (var node in nodes) {
      if (node.value != null) {
        spans.add(TextSpan(text: node.value, style: _theme[node.className]));
      } else if (node.children != null) {
        spans.add(
          TextSpan(
            children: _convert(node.children),
            style: _theme[node.className],
          ),
        );
      }
    }
    return spans;
  }
}

void registerLanguages() {
  highlight.highlight.registerLanguage('dart', dart);
  highlight.highlight.registerLanguage('yaml', yaml);
  highlight.highlight.registerLanguage('json', json);
  highlight.highlight.registerLanguage('xml', xml);
  highlight.highlight.registerLanguage('bash', bash);
  // Add more languages as needed
}
