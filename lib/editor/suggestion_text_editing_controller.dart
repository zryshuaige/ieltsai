import 'package:flutter/material.dart';

class SuggestionTextEditingController extends TextEditingController {
  String _suggestion = '';
  Color _ghostColor = const Color(0x66000000);

  void setSuggestion(String value) {
    if (_suggestion == value) {
      return;
    }
    _suggestion = value;
  }

  void setGhostColor(Color value) {
    if (_ghostColor == value) {
      return;
    }
    _ghostColor = value;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    if (_suggestion.trim().isEmpty ||
        !selection.isValid ||
        !selection.isCollapsed) {
      return TextSpan(style: baseStyle, text: text);
    }

    final cursorOffset = selection.extentOffset.clamp(0, text.length);
    final before = text.substring(0, cursorOffset);
    final after = text.substring(cursorOffset);
    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: before),
        TextSpan(
          text: _suggestion,
          style: baseStyle.copyWith(color: _ghostColor),
        ),
        TextSpan(text: after),
      ],
    );
  }
}
