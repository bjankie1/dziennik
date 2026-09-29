import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/utils/calendar_browser_helper_stub.dart'
    if (dart.library.js_interop) '../../core/utils/calendar_browser_helper_web.dart';

/// A segment of text: either plain text or a detected URL.
class LinkSegment {
  final String text;

  /// Normalized URL to open (null for plain text).
  final String? url;

  const LinkSegment(this.text, [this.url]);

  bool get isLink => url != null;

  @override
  bool operator ==(Object other) =>
      other is LinkSegment && other.text == text && other.url == url;

  @override
  int get hashCode => Object.hash(text, url);

  @override
  String toString() => isLink ? 'Link($text -> $url)' : 'Text($text)';
}

// http(s)://... or www.... up to whitespace / angle brackets / quotes.
final RegExp _urlPattern = RegExp(
  r'''((?:https?://|www\.)[^\s<>"'`]+)''',
  caseSensitive: false,
);

// Characters that commonly end a sentence right after a URL.
const String _trailingPunctuation = '.,;:!?)]}»”’…';

/// Splits [input] into plain-text and URL segments.
List<LinkSegment> splitLinks(String input) {
  final segments = <LinkSegment>[];
  var cursor = 0;

  for (final match in _urlPattern.allMatches(input)) {
    var raw = match.group(0)!;

    // Strip trailing punctuation, keeping balanced closing parentheses.
    while (raw.isNotEmpty && _trailingPunctuation.contains(raw[raw.length - 1])) {
      final last = raw[raw.length - 1];
      if (last == ')' &&
          '('.allMatches(raw).length >= ')'.allMatches(raw).length) {
        break;
      }
      raw = raw.substring(0, raw.length - 1);
    }
    // Bare scheme/prefix without host is not a link.
    final hostPart = raw.replaceFirst(RegExp(r'^(https?://|www\.)', caseSensitive: false), '');
    if (hostPart.isEmpty || !hostPart.contains(RegExp(r'[A-Za-z0-9]'))) continue;

    final start = match.start;
    final end = start + raw.length;
    if (start > cursor) segments.add(LinkSegment(input.substring(cursor, start)));

    final url = raw.toLowerCase().startsWith('www.') ? 'https://$raw' : raw;
    segments.add(LinkSegment(raw, url));
    cursor = end;
  }

  if (cursor < input.length) segments.add(LinkSegment(input.substring(cursor)));
  return segments;
}

/// Selectable text that renders URL-looking fragments as hyperlinks which
/// always open in a new browser tab/window.
class LinkifiedSelectableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;

  /// Overridable for tests; defaults to opening a new browser tab.
  final void Function(String url)? onOpenLink;

  const LinkifiedSelectableText(
    this.text, {
    super.key,
    this.style,
    this.linkStyle,
    this.onOpenLink,
  });

  @override
  State<LinkifiedSelectableText> createState() => _LinkifiedSelectableTextState();
}

class _LinkifiedSelectableTextState extends State<LinkifiedSelectableText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _open(String url) {
    final handler = widget.onOpenLink;
    if (handler != null) {
      handler(url);
    } else {
      openUrlInBrowser(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final linkStyle = widget.linkStyle ??
        (widget.style ?? const TextStyle()).copyWith(
          color: const Color(0xFF2563EB),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFF2563EB),
        );

    final spans = splitLinks(widget.text).map<InlineSpan>((segment) {
      if (!segment.isLink) return TextSpan(text: segment.text);
      final recognizer = TapGestureRecognizer()..onTap = () => _open(segment.url!);
      _recognizers.add(recognizer);
      return TextSpan(
        text: segment.text,
        style: linkStyle,
        recognizer: recognizer,
        mouseCursor: SystemMouseCursors.click,
        semanticsLabel: segment.text,
      );
    }).toList();

    return SelectableText.rich(
      TextSpan(style: widget.style, children: spans),
    );
  }
}
