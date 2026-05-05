import 'package:ieltsai/ai/completion_mode_detector.dart';
import 'package:ieltsai/ai/models/ai_request.dart';

enum ParagraphRole { introduction, body, conclusion, unknown }

class ParagraphFrameworkAnalysis {
  const ParagraphFrameworkAnalysis({
    required this.currentRole,
    required this.currentThemeHint,
    required this.suggestStartNewParagraph,
    required this.nextRoleHint,
  });

  final ParagraphRole currentRole;
  final String currentThemeHint;
  final bool suggestStartNewParagraph;
  final ParagraphRole nextRoleHint;
}

class ParagraphFrameworkAnalyzer {
  const ParagraphFrameworkAnalyzer();

  ParagraphFrameworkAnalysis analyze(AiRequest request) {
    final role = _guessRole(request);
    final themeHint = _extractThemeHint(request.currentParagraphFull);
    final suggestStartNewParagraph = _shouldStartNewParagraph(request, role);
    final nextRoleHint = _guessNextRole(request, role, suggestStartNewParagraph);
    return ParagraphFrameworkAnalysis(
      currentRole: role,
      currentThemeHint: themeHint,
      suggestStartNewParagraph: suggestStartNewParagraph,
      nextRoleHint: nextRoleHint,
    );
  }

  ParagraphRole _guessRole(AiRequest request) {
    final paragraphText = request.currentParagraphFull.toLowerCase();
    if (paragraphText.contains('in conclusion') ||
        paragraphText.contains('to conclude') ||
        paragraphText.contains('to sum up') ||
        paragraphText.contains('overall,')) {
      return ParagraphRole.conclusion;
    }
    if (request.paragraphIndex <= 1) {
      return ParagraphRole.introduction;
    }
    // In a typical 4-paragraph Task 2, paragraph 4 is the conclusion.
    if (request.paragraphIndex >= 4) {
      return ParagraphRole.conclusion;
    }
    return ParagraphRole.body;
  }

  ParagraphRole _guessNextRole(
    AiRequest request,
    ParagraphRole role,
    bool suggestStartNewParagraph,
  ) {
    if (!suggestStartNewParagraph) {
      return role;
    }
    switch (role) {
      case ParagraphRole.introduction:
        return ParagraphRole.body;
      case ParagraphRole.body:
        // Heuristic: after 2 body paragraphs, next is likely conclusion.
        if (request.paragraphIndex >= 3) {
          return ParagraphRole.conclusion;
        }
        return ParagraphRole.body;
      case ParagraphRole.conclusion:
        return ParagraphRole.conclusion;
      case ParagraphRole.unknown:
        return ParagraphRole.unknown;
    }
  }

  bool _shouldStartNewParagraph(AiRequest request, ParagraphRole role) {
    // Only consider starting a new paragraph when the current sentence is
    // complete. This avoids mid-sentence paragraph breaks.
    final trimmedLeft = request.leftContext.trimRight();
    final endsWithSentence = RegExp(r'[.!?]$').hasMatch(trimmedLeft);
    if (!endsWithSentence) {
      return false;
    }
    if (request.cursorAtParagraphStart) {
      return false;
    }
    if (role == ParagraphRole.conclusion) {
      return false;
    }

    // Avoid forcing paragraph breaks if user explicitly started a new
    // paragraph already.
    if (request.completionMode == CompletionMode.nextParagraph) {
      return false;
    }

    final wordCount = _wordCount(request.currentParagraphFull);
    final sentenceCount = _sentenceCount(request.currentParagraphFull);

    // Intro is usually short.
    if (role == ParagraphRole.introduction) {
      return wordCount >= 30 && sentenceCount >= 2;
    }
    // Body paragraphs are typically longer and have at least 3-5 sentences.
    return wordCount >= 70 || sentenceCount >= 4;
  }

  int _wordCount(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((t) => t.trim().isNotEmpty)
        .length;
  }

  int _sentenceCount(String text) {
    final matches = RegExp(r'[.!?]').allMatches(text);
    return matches.length;
  }

  String _extractThemeHint(String paragraph) {
    final trimmed = paragraph.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final firstSentence = _firstSentence(trimmed);
    // Keep it short; this is only a hint for the model.
    final words = firstSentence
        .replaceAll('’', "'")
        .replaceAll(RegExp(r"[^A-Za-z0-9\s\-']"), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return '';
    }
    final take = words.length > 12 ? 12 : words.length;
    return words.take(take).join(' ');
  }

  String _firstSentence(String text) {
    final match = RegExp(r'^(.+?[.!?])\s').firstMatch('$text ');
    if (match != null) {
      return (match.group(1) ?? text).trim();
    }
    return text.split('\n').first.trim();
  }
}
