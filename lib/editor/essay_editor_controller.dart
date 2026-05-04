import 'package:flutter/widgets.dart';
import 'package:ieltsai/editor/document_snapshot.dart';
import 'package:ieltsai/editor/suggestion_text_editing_controller.dart';

class EssayEditorController {
  EssayEditorController()
    : bodyController = SuggestionTextEditingController(),
      bodyFocusNode = FocusNode();

  final SuggestionTextEditingController bodyController;
  final FocusNode bodyFocusNode;

  String _lastText = '';
  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);

  DocumentSnapshot captureSnapshot({
    required String taskPrompt,
    required String targetBand,
  }) {
    final currentText = bodyController.text;
    final selection = bodyController.selection;
    final safeSelection = selection.isValid
        ? selection
        : TextSelection.collapsed(offset: currentText.length);
    final cursorOffset = safeSelection.extentOffset.clamp(
      0,
      currentText.length,
    );

    final changeKind = _resolveChangeKind(
      previousText: _lastText,
      currentText: currentText,
      previousSelection: _lastSelection,
      currentSelection: safeSelection,
    );

    _lastText = currentText;
    _lastSelection = safeSelection;

    return DocumentSnapshot(
      taskPrompt: taskPrompt,
      targetBand: targetBand,
      text: currentText,
      cursorOffset: cursorOffset,
      hasSelection: !safeSelection.isCollapsed,
      changeKind: changeKind,
      changedAt: DateTime.now(),
    );
  }

  void dispose() {
    bodyController.dispose();
    bodyFocusNode.dispose();
  }

  DocumentChangeKind _resolveChangeKind({
    required String previousText,
    required String currentText,
    required TextSelection previousSelection,
    required TextSelection currentSelection,
  }) {
    if (currentText.length > previousText.length) {
      return DocumentChangeKind.insert;
    }
    if (currentText.length < previousText.length) {
      return DocumentChangeKind.delete;
    }
    if (currentText != previousText) {
      return DocumentChangeKind.replace;
    }
    if (currentSelection != previousSelection) {
      return DocumentChangeKind.cursorMove;
    }
    return DocumentChangeKind.cursorMove;
  }
}
