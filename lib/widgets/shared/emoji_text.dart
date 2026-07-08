import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A [Text] widget that renders emoji using Noto Color Emoji on web/PWA,
/// giving a consistent Apple-style emoji appearance across all platforms.
///
/// On native (iOS/Android) the system emoji font is used as normal.
/// On web, [fontFamilyFallback] is set to ['Noto Color Emoji'] so the
/// browser uses the Google Fonts Noto Color Emoji instead of the OS default
/// (e.g. Segoe UI Emoji on Windows).
class EmojiText extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextStyle? style;

  const EmojiText(
    this.text, {
    super.key,
    this.fontSize = 18,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontFamilyFallback: kIsWeb ? const ['Noto Color Emoji'] : null,
    );
    final merged = style != null ? baseStyle.merge(style) : baseStyle;
    return Text(text, style: merged);
  }
}
