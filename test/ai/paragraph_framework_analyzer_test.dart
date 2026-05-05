import 'package:flutter_test/flutter_test.dart';
import 'package:ieltsai/ai/completion_mode_detector.dart';
import 'package:ieltsai/ai/models/ai_request.dart';
import 'package:ieltsai/ai/paragraph_framework_analyzer.dart';

void main() {
  test('suggests new paragraph for a complete intro', () {
    const analyzer = ParagraphFrameworkAnalyzer();
    const request = AiRequest(
      taskPrompt: 'Some IELTS prompt',
      targetBand: '7',
      leftContext: 'It is widely argued that this is important. I agree.',
      rightContext: '',
      currentSentence: 'I agree.',
      currentParagraph: 'It is widely argued that this is important. I agree.',
      currentParagraphFull:
          'It is widely argued that this is important in modern societies, especially as economies become more knowledge-based. '
          'I agree that prioritising this area delivers long-term advantages for individuals and the wider community.',
      paragraphIndex: 1,
      totalParagraphs: 1,
      cursorAtParagraphStart: false,
      cursorAtParagraphEnd: true,
      completionMode: CompletionMode.nextSentence,
      prompt: '',
    );

    final analysis = analyzer.analyze(request);
    expect(analysis.currentRole, ParagraphRole.introduction);
    // Not necessarily true for every input, but should often be suggested once
    // intro is ~2 sentences.
    expect(analysis.suggestStartNewParagraph, isTrue);
    expect(analysis.nextRoleHint, ParagraphRole.body);
  });
}
