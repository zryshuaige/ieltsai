import 'package:ieltsai/ai/completion_mode_detector.dart';
import 'package:ieltsai/ai/models/ai_request.dart';
import 'package:ieltsai/editor/document_snapshot.dart';

class ContextExtractor {
  const ContextExtractor();

  static const int _maxLeftContextChars = 2600;
  static const int _maxRightContextChars = 1100;
  static const int _maxCurrentParagraphFullChars = 1400;

  AiRequest extract({
    required DocumentSnapshot snapshot,
    required CompletionMode completionMode,
    required String prompt,
  }) {
    final leftText = snapshot.text.substring(0, snapshot.cursorOffset);
    final rightText = snapshot.text.substring(snapshot.cursorOffset);
    final leftContext = _tail(leftText, _maxLeftContextChars);
    final rightContext = _head(rightText, _maxRightContextChars);

    final paragraphIndex = _computeParagraphIndex(leftText);
    final totalParagraphs = _computeTotalParagraphs(snapshot.text);
    final cursorAtParagraphStart = _isCursorAtParagraphStart(leftText);
    final cursorAtParagraphEnd = _isCursorAtParagraphEnd(rightText);

    final currentParagraph = _extractCurrentParagraph(leftText);
    final paragraphTail = _extractParagraphTail(leftText);
    final paragraphHead = _extractParagraphHead(rightText);
    final currentParagraphFull = _tail(
      '${paragraphTail}${paragraphHead.isEmpty ? '' : '\n$paragraphHead'}'
          .trim(),
      _maxCurrentParagraphFullChars,
    );

    return AiRequest(
      taskPrompt: snapshot.taskPrompt,
      targetBand: snapshot.targetBand,
      leftContext: leftContext,
      rightContext: rightContext,
      currentSentence: _extractCurrentSentence(leftText),
      currentParagraph: currentParagraph,
      currentParagraphFull: currentParagraphFull,
      paragraphIndex: paragraphIndex,
      totalParagraphs: totalParagraphs,
      cursorAtParagraphStart: cursorAtParagraphStart,
      cursorAtParagraphEnd: cursorAtParagraphEnd,
      completionMode: completionMode,
      prompt: prompt,
    );
  }

  String _extractCurrentSentence(String leftText) {
    final parts = leftText.split(RegExp(r'(?<=[.!?])\s+|\n'));
    return parts.isEmpty ? '' : parts.last.trim();
  }

  String _extractCurrentParagraph(String leftText) {
    final parts = leftText.split(RegExp(r'\n\s*\n'));
    return parts.isEmpty ? '' : parts.last.trim();
  }

  int _computeParagraphIndex(String leftText) {
    if (leftText.trim().isEmpty) {
      return 1;
    }
    final matches = RegExp(r'\n\s*\n').allMatches(leftText);
    return matches.length + 1;
  }

  int _computeTotalParagraphs(String fullText) {
    final trimmed = fullText.trim();
    if (trimmed.isEmpty) {
      return 1;
    }
    final parts = trimmed
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.isEmpty ? 1 : parts.length;
  }

  bool _isCursorAtParagraphStart(String leftText) {
    if (leftText.isEmpty) {
      return true;
    }
    if (RegExp(r'\n\s*\n\s*$').hasMatch(leftText)) {
      return true;
    }
    final lastParagraph = leftText.split(RegExp(r'\n\s*\n')).last;
    return lastParagraph.trim().isEmpty;
  }

  bool _isCursorAtParagraphEnd(String rightText) {
    if (rightText.isEmpty) {
      return true;
    }
    return RegExp(r'^\s*\n\s*\n').hasMatch(rightText);
  }

  String _extractParagraphTail(String leftText) {
    final parts = leftText.split(RegExp(r'\n\s*\n'));
    if (parts.isEmpty) {
      return '';
    }
    return parts.last.trimRight();
  }

  String _extractParagraphHead(String rightText) {
    final parts = rightText.split(RegExp(r'\n\s*\n'));
    if (parts.isEmpty) {
      return '';
    }
    return parts.first.trimLeft();
  }

  String _tail(String text, int maxChars) {
    if (text.length <= maxChars) {
      return text;
    }
    return text.substring(text.length - maxChars);
  }

  String _head(String text, int maxChars) {
    if (text.length <= maxChars) {
      return text;
    }
    return text.substring(0, maxChars);
  }
}
