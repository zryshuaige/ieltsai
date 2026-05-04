import 'package:ieltsai/ai/completion_mode_detector.dart';
import 'package:ieltsai/ai/models/ai_request.dart';
import 'package:ieltsai/editor/document_snapshot.dart';

class ContextExtractor {
  const ContextExtractor();

  AiRequest extract({
    required DocumentSnapshot snapshot,
    required CompletionMode completionMode,
    required String prompt,
  }) {
    final leftText = snapshot.text.substring(0, snapshot.cursorOffset);
    final rightText = snapshot.text.substring(snapshot.cursorOffset);
    final leftContext = _tail(leftText, 1000);
    final rightContext = _head(rightText, 300);

    return AiRequest(
      taskPrompt: snapshot.taskPrompt,
      targetBand: snapshot.targetBand,
      leftContext: leftContext,
      rightContext: rightContext,
      currentSentence: _extractCurrentSentence(leftText),
      currentParagraph: _extractCurrentParagraph(leftText),
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
