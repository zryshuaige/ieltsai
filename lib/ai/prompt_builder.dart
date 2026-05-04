import 'package:ieltsai/ai/models/ai_request.dart';

class PromptBuilder {
  const PromptBuilder();

  String build(AiRequest request) {
    return '''
System:
You are an inline autocomplete engine for IELTS Writing Task 2.
Return only the continuation text that should be inserted at cursor.
Do not use markdown. Do not explain. Do not repeat existing words.
Keep style academic and natural. Keep completion under 25 words.

User:
IELTS Question:
${request.taskPrompt}

Target Band:
${request.targetBand}

Text before cursor:
${request.leftContext}

Current sentence:
${request.currentSentence}

Text after cursor:
${request.rightContext}

Instruction:
Continue the essay at cursor based on completion mode: ${request.completionMode.name}.
''';
  }
}
