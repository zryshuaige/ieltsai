import 'package:flutter_test/flutter_test.dart';
import 'package:ieltsai/ai/post_processor.dart';

void main() {
  group('PostProcessor.clean', () {
    test('parses JSON: leadingSpace=false yields sentinel-prefixed insertion', () {
      const raw = '{"text":"ed","leadingSpace":false,"paragraphBreak":false}';
      const processor = PostProcessor();
      final cleaned = processor.clean(raw);
      expect(cleaned.startsWith('\u0001'), isTrue);
      expect(cleaned.replaceFirst('\u0001', ''), 'ed');
    });

    test('parses JSON: leadingSpace=true prefixes a single space', () {
      const raw =
          '{"text":"however, this overlooks key costs","leadingSpace":true,"paragraphBreak":false}';
      const processor = PostProcessor();
      final cleaned = processor.clean(raw);
      expect(cleaned.startsWith(' '), isTrue);
      expect(cleaned.trimLeft(), startsWith('however'));
    });

    test('parses JSON: paragraphBreak=true prefixes \"\\n\\n\" and no space', () {
      const raw =
          '{"text":"In conclusion, governments should act decisively.","leadingSpace":true,"paragraphBreak":true}';
      const processor = PostProcessor();
      final cleaned = processor.clean(raw);
      expect(cleaned.startsWith('\n\n'), isTrue);
      expect(cleaned.startsWith('\n\n '), isFalse);
    });

    test('streams partial JSON preview returns only text', () {
      const raw = '{"text":"Improve';
      const processor = PostProcessor();
      final cleaned = processor.clean(raw);
      expect(cleaned, 'Improve');
    });

    test('parses loose JSON with trailing comma', () {
      const raw =
          '{"text":"ed","leadingSpace":false,"paragraphBreak":false,}';
      const processor = PostProcessor();
      final cleaned = processor.clean(raw);
      expect(cleaned.startsWith('\u0001'), isTrue);
      expect(cleaned.replaceFirst('\u0001', ''), 'ed');
    });

    test('preserves a single paragraph break', () {
      const raw = 'This is the end of a paragraph.\n\nThis is the next one.';
      const processor = PostProcessor();
      final cleaned = processor.clean(raw);
      expect(cleaned.contains('\n\n'), isTrue);
      expect(cleaned.split('\n\n').length, 2);
    });

    test('flattens extra paragraph breaks to at most one', () {
      const raw =
          'Para1 ends here.\n\nPara2 starts.\n\nPara3 starts too.';
      const processor = PostProcessor();
      final cleaned = processor.clean(raw);
      expect(RegExp(r'\n\n').allMatches(cleaned).length, 1);
    });

    test('keeps word limit while allowing paragraph break token', () {
      final raw =
          'First sentence ends here.\n\n' +
          List<String>.generate(40, (i) => 'word$i').join(' ');
      const processor = PostProcessor();
      final cleaned = processor.clean(raw);
      final tokens = cleaned.replaceAll('\n\n', ' ').split(RegExp(r'\s+'));
      final words = tokens.where((t) => t.trim().isNotEmpty).toList();
      expect(words.length, lessThanOrEqualTo(25));
    });
  });
}
