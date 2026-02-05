import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:markdown/markdown.dart' as md;
import 'code_syntax_highlighter.dart';

class CodeBlockBuilder extends MarkdownElementBuilder {
  final CodeSyntaxHighlighter highlighter;

  CodeBlockBuilder({required this.highlighter});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    var language = '';

    if (element.children != null &&
        element.children!.isNotEmpty &&
        element.children!.first is md.Element) {
      final codeElement = element.children!.first as md.Element;
      if (codeElement.attributes.containsKey('class')) {
        language = codeElement.attributes['class'] ?? '';
        if (language.startsWith('language-')) {
          language = language.substring(9);
        }
      }
    }

    var text = element.textContent;
    if (text.isEmpty && element.children != null) {
      text = element.children!.map((e) => e.textContent).join();
    }
    final formatted = highlighter.formatWithLanguage(text, language);

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return _CodeBlockWidget(
      text: text,
      formatted: formatted,
      language: language,
    );
  }
}

class _CodeBlockWidget extends StatefulWidget {
  final String text;
  final TextSpan formatted;
  final String language;

  const _CodeBlockWidget({
    required this.text,
    required this.formatted,
    required this.language,
  });

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _hovering = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.text));
    showToast(
      context: context,
      builder: (context, overlay) => SurfaceCard(
        child: Basic(
          leading: Icon(BootstrapIcons.checkCircle, color: Colors.green),
          title: const Text('Copied to clipboard'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff1e1e1e), // Dark background for code
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withAlpha(10)),
            ),
            child: RichText(text: widget.formatted),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedOpacity(
              opacity: _hovering ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Button(
                style: ButtonStyle.secondary(size: ButtonSize.small),
                onPressed: _copyToClipboard,
                child: const Icon(BootstrapIcons.clipboard, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
