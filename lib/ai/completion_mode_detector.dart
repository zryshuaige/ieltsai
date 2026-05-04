enum CompletionMode {
  finishCurrentSentence,
  nextSentence,
  nextParagraph,
  freeContinue,
}

class CompletionModeDetector {
  CompletionMode detect(String leftText) {
    final trimmed = leftText.trimRight();
    if (trimmed.isEmpty) {
      return CompletionMode.freeContinue;
    }
    if (leftText.endsWith('\n')) {
      return CompletionMode.nextParagraph;
    }
    if (RegExp(r'[.!?]$').hasMatch(trimmed)) {
      return CompletionMode.nextSentence;
    }
    return CompletionMode.finishCurrentSentence;
  }
}
