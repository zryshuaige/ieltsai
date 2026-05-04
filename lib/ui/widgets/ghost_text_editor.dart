import 'package:flutter/material.dart';
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
