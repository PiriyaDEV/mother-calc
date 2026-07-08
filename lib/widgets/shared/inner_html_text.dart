import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class InnerHTMLText extends StatelessWidget {
  final String innerHtml;
  final TextAlign textAlign;
  final TextStyle? textStyle;

  const InnerHTMLText({
    super.key,
    required this.innerHtml,
    this.textAlign = TextAlign.left,
    this.textStyle,
  });

  static const _alignMap = {
    TextAlign.left: 'left',
    TextAlign.right: 'right',
    TextAlign.center: 'center',
    TextAlign.justify: 'justify',
  };

  static String _unescapeJson(String raw) => raw
      .replaceAll('\\n', '\n')
      .replaceAll('\\r', '\r')
      .replaceAll('\\t', '\t');

  static String _toHtml(String text) => text
      .replaceAll('\r\n', '<br>')
      .replaceAll('\n', '<br>')
      .replaceAll('\r', '<br>')
      .replaceAll('\t', '&nbsp;&nbsp;&nbsp;&nbsp;');

  String get _html {
    final align = _alignMap[textAlign] ?? 'left';
    final content = _toHtml(_unescapeJson(innerHtml));
    return '<div style="text-align: $align;">$content</div>';
  }

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      _html,
      textStyle: textStyle ?? const TextStyle(fontSize: 14),
    );
  }
}
