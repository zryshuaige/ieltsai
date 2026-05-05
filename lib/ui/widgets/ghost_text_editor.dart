import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ieltsai/editor/suggestion_text_editing_controller.dart';
import 'package:ieltsai/ui/widgets/glass_panel.dart';

class GhostTextEditor extends StatelessWidget {
  const GhostTextEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.suggestion,
    required this.onChanged,
    this.minLines = 14,
    this.maxLines,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String suggestion;
  final ValueChanged<String> onChanged;
  final int minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        theme.textTheme.bodyLarge?.copyWith(height: 1.58, fontSize: 18) ??
        const TextStyle(fontSize: 18, height: 1.58);

    if (controller is SuggestionTextEditingController) {
      final suggestionController =
          controller as SuggestionTextEditingController;
      suggestionController.setSuggestion(suggestion);
      suggestionController.setGhostColor(
        theme.colorScheme.onSurface.withValues(alpha: 0.33),
      );
    }

    return GlassPanel(
      radius: 26,
      padding: EdgeInsets.zero,
      child: TextField(
        key: const ValueKey('essay-body-field'),
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        inputFormatters: const [_AsciiOnlyFormatter()],
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        minLines: minLines,
        maxLines: maxLines,
        style: style.copyWith(color: theme.colorScheme.onSurface),
        cursorColor: theme.colorScheme.primary,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Write your IELTS essay here...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            fontSize: 17,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class _AsciiOnlyFormatter extends TextInputFormatter {
  const _AsciiOnlyFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final buffer = StringBuffer();
    var newBase = 0;
    var newExtent = 0;
    final baseOffset = newValue.selection.baseOffset;
    final extentOffset = newValue.selection.extentOffset;

    for (var i = 0; i < text.length; i++) {
      final mapped = _mapChar(text.codeUnitAt(i));
      if (i < baseOffset) {
        newBase += mapped.length;
      }
      if (i < extentOffset) {
        newExtent += mapped.length;
      }
      buffer.write(mapped);
    }

    final normalized = buffer.toString();
    final clampedBase = newBase.clamp(0, normalized.length);
    final clampedExtent = newExtent.clamp(0, normalized.length);

    return TextEditingValue(
      text: normalized,
      selection: newValue.selection.isValid
          ? TextSelection(baseOffset: clampedBase, extentOffset: clampedExtent)
          : TextSelection.collapsed(offset: normalized.length),
      composing: TextRange.empty,
    );
  }

  String _mapChar(int codeUnit) {
    if (codeUnit == 0x3000) {
      return ' ';
    }
    if (codeUnit >= 0xFF01 && codeUnit <= 0xFF5E) {
      return String.fromCharCode(codeUnit - 0xFEE0);
    }
    if (codeUnit <= 0x7F) {
      return String.fromCharCode(codeUnit);
    }
    return '';
  }
}
