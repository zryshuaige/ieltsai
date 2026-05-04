import 'package:ieltsai/ai/completion_mode_detector.dart';

class AiRequest {
  const AiRequest({
    required this.taskPrompt,
    required this.targetBand,
    required this.leftContext,
    required this.rightContext,
    required this.currentSentence,
    required this.currentParagraph,
    required this.currentParagraphFull,
    required this.paragraphIndex,
    required this.totalParagraphs,
    required this.cursorAtParagraphStart,
    required this.cursorAtParagraphEnd,
    required this.completionMode,
    required this.prompt,
  });

  final String taskPrompt;
  final String targetBand;
  final String leftContext;
  final String rightContext;
  final String currentSentence;
  final String currentParagraph;
  final String currentParagraphFull;
  final int paragraphIndex;
  final int totalParagraphs;
  final bool cursorAtParagraphStart;
  final bool cursorAtParagraphEnd;
  final CompletionMode completionMode;
  final String prompt;
}
