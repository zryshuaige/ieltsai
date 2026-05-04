import 'package:ieltsai/ai/ai_assist_preference.dart';
import 'package:ieltsai/editor/document_snapshot.dart';

class TriggerPolicy {
  bool shouldAutoTrigger({
    required AssistLevel level,
    required DocumentSnapshot snapshot,
    required DateTime now,
    DateTime? lastRequestedAt,
    required bool hasSuggestion,
  }) {
    if (level == AssistLevel.manual || hasSuggestion) {
      return false;
    }
    if (snapshot.changeKind != DocumentChangeKind.insert) {
      return false;
    }
    if (!snapshot.isCursorAtEnd) {
      return false;
    }
    if (snapshot.text.trim().length < 12) {
      return false;
    }

    final minInterval = level == AssistLevel.frequent
        ? const Duration(milliseconds: 500)
        : const Duration(milliseconds: 1200);
    if (lastRequestedAt != null &&
        now.difference(lastRequestedAt) < minInterval) {
      return false;
    }

    final lastChar = snapshot.text.isEmpty
        ? ''
        : snapshot.text[snapshot.text.length - 1];
    final frequentChars = {' ', ',', '.', ';', ':'};
    final balancedChars = {'.', '?', '!', '\n'};
    final acceptedChars = level == AssistLevel.frequent
        ? frequentChars
        : balancedChars;
    return acceptedChars.contains(lastChar);
  }

  bool shouldManualTrigger({
    required DocumentSnapshot snapshot,
    required DateTime now,
    DateTime? lastRequestedAt,
  }) {
    if (!snapshot.isCursorAtEnd || snapshot.text.trim().isEmpty) {
      return false;
    }
    if (lastRequestedAt == null) {
      return true;
    }
    return now.difference(lastRequestedAt) > const Duration(milliseconds: 300);
  }
}
