enum DocumentChangeKind { insert, delete, cursorMove, replace }

class DocumentSnapshot {
  const DocumentSnapshot({
    required this.taskPrompt,
    required this.targetBand,
    required this.text,
    required this.cursorOffset,
    required this.hasSelection,
    required this.changeKind,
    required this.changedAt,
  });

  final String taskPrompt;
  final String targetBand;
  final String text;
  final int cursorOffset;
  final bool hasSelection;
  final DocumentChangeKind changeKind;
  final DateTime changedAt;

  bool get isCursorAtEnd => !hasSelection && cursorOffset == text.length;
}
