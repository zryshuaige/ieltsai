import 'package:ieltsai/ai/completion_mode_detector.dart';

class AiRequest {
  const AiRequest({
    required this.taskPrompt,
    required this.targetBand,
    required this.leftContext,
    required this.rightContext,
    required this.currentSentence,
    required this.currentParagraph,
    required this.completionMode,
    required this.prompt,
  });

  final String taskPrompt;
  final String targetBand;
  final String leftContext;
  final String rightContext;
  final String currentSentence;
  final String currentParagraph;
  final CompletionMode completionMode;
  final String prompt;
}
