import 'package:flutter/material.dart';

class SafeMarkdownRenderer extends StatelessWidget {
  const SafeMarkdownRenderer({required this.content, super.key});

  final String content;

  @override
  Widget build(BuildContext context) {
    final List<Widget> blocks = _blocks(context, content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  List<Widget> _blocks(BuildContext context, String value) {
    final List<Widget> result = <Widget>[];
    final List<String> lines = value.replaceAll('\r\n', '\n').split('\n');
    final List<String> bullets = <String>[];
    void flushBullets() {
      if (bullets.isEmpty) return;
      result.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bullets
                .map(
                  (String item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('•  '),
                        Expanded(child: _inlineText(context, item)),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );
      bullets.clear();
    }

    for (final String line in lines) {
      if (line.startsWith('- ') || line.startsWith('* ')) {
        bullets.add(line.substring(2));
        continue;
      }
      flushBullets();
      if (line.isEmpty) {
        result.add(const SizedBox(height: 8));
      } else {
        result.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _inlineText(context, line),
          ),
        );
      }
    }
    flushBullets();
    return result;
  }

  Widget _inlineText(BuildContext context, String value) {
    final TextStyle baseStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final List<InlineSpan> spans = <InlineSpan>[];
    final RegExp token = RegExp(r'(\*\*|__)(.+?)(\*\*|__)|(\*|_)(.+?)(\*|_)');
    int cursor = 0;
    for (final RegExpMatch match in token.allMatches(value)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: value.substring(cursor, match.start)));
      }
      final String text = match.group(2) ?? match.group(5) ?? '';
      final bool bold = match.group(2) != null;
      spans.add(
        TextSpan(
          text: text,
          style: baseStyle.copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: bold ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < value.length) {
      spans.add(TextSpan(text: value.substring(cursor)));
    }
    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}
