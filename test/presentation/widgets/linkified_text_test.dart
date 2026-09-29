import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edusync/presentation/widgets/linkified_text.dart';

void main() {
  group('splitLinks', () {
    test('detects liblink URL inside message text', () {
      final segments = splitLinks('Formularz: https://liblink.pl/v7wZksJCEe proszę wypełnić.');
      expect(segments, const [
        LinkSegment('Formularz: '),
        LinkSegment('https://liblink.pl/v7wZksJCEe', 'https://liblink.pl/v7wZksJCEe'),
        LinkSegment(' proszę wypełnić.'),
      ]);
    });

    test('strips trailing sentence punctuation', () {
      final segments = splitLinks('Zobacz https://example.com/a.');
      expect(segments.last, const LinkSegment('.'));
      expect(segments[1].url, 'https://example.com/a');
    });

    test('keeps balanced parentheses, drops unbalanced closing one', () {
      expect(splitLinks('https://pl.wikipedia.org/wiki/X_(Y)')[0].url,
          'https://pl.wikipedia.org/wiki/X_(Y)');
      expect(splitLinks('(https://a.pl/b)')[1].url, 'https://a.pl/b');
    });

    test('www. gets https scheme', () {
      final segments = splitLinks('www.librus.pl');
      expect(segments.single.url, 'https://www.librus.pl');
      expect(segments.single.text, 'www.librus.pl');
    });

    test('plain text without URLs is a single segment', () {
      expect(splitLinks('Brak linków tutaj'), const [LinkSegment('Brak linków tutaj')]);
    });

    test('multiple URLs and newlines', () {
      final segments = splitLinks('a http://x.pl\nb https://y.pl/z?q=1&r=2');
      final urls = segments.where((s) => s.isLink).map((s) => s.url).toList();
      expect(urls, ['http://x.pl', 'https://y.pl/z?q=1&r=2']);
    });
  });

  testWidgets('tapping link opens it via handler', (tester) async {
    String? opened;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LinkifiedSelectableText(
          'https://liblink.pl/v7wZksJCEe',
          onOpenLink: (u) => opened = u,
        ),
      ),
    ));

    final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
    final root = selectable.textSpan!;
    final linkSpan = root.children!
        .whereType<TextSpan>()
        .firstWhere((s) => s.recognizer != null);
    expect(linkSpan.recognizer, isNotNull);
    (linkSpan.recognizer! as dynamic).onTap!();
    expect(opened, 'https://liblink.pl/v7wZksJCEe');
    expect(linkSpan.mouseCursor, SystemMouseCursors.click);
  });
}
