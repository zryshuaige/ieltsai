import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ieltsai/ai/ai_assist_engine.dart';
import 'package:ieltsai/ai/ai_assist_preference.dart';
import 'package:ieltsai/ai/completion_mode_detector.dart';
import 'package:ieltsai/ai/context_extractor.dart';
import 'package:ieltsai/ai/debouncer.dart';
import 'package:ieltsai/ai/model/deepseek_adapter.dart';
import 'package:ieltsai/ai/post_processor.dart';
import 'package:ieltsai/ai/prompt_builder.dart';
import 'package:ieltsai/ai/trigger_policy.dart';
import 'package:ieltsai/editor/essay_editor_controller.dart';
import 'package:ieltsai/ui/widgets/glass_panel.dart';
import 'package:ieltsai/ui/widgets/ghost_text_editor.dart';
import 'package:ieltsai/ui/widgets/suggestion_bar.dart';
import 'package:path_provider/path_provider.dart';

class AcceptSuggestionIntent extends Intent {
  const AcceptSuggestionIntent();
}

class AcceptWordIntent extends Intent {
  const AcceptWordIntent();
}

class DismissSuggestionIntent extends Intent {
  const DismissSuggestionIntent();
}

class RegenerateSuggestionIntent extends Intent {
  const RegenerateSuggestionIntent();
}

class SelectPreviousSuggestionIntent extends Intent {
  const SelectPreviousSuggestionIntent();
}

class SelectNextSuggestionIntent extends Intent {
  const SelectNextSuggestionIntent();
}

class EssayEditorPage extends StatefulWidget {
  const EssayEditorPage({super.key});

  @override
  State<EssayEditorPage> createState() => _EssayEditorPageState();
}

class _EssayEditorPageState extends State<EssayEditorPage> {
  static const List<String> _targetBandOptions = ['7.5', '7.0', '6.5'];

  final TextEditingController _taskPromptController = TextEditingController(
    text:
        'Some people think governments should invest more in public transport than roads. Discuss both views and give your opinion.',
  );
  late final EssayEditorController _editorController;
  late final AiAssistEngine _assistEngine;

  AssistLevel _assistLevel = AssistLevel.balanced;
  String _targetBand = '7.0';
  List<String> _suggestionOptions = const [];
  int _selectedSuggestionIndex = 0;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _editorController = EssayEditorController();
    _assistEngine = AiAssistEngine(
      modelApiAdapter: DeepSeekAdapter(),
      triggerPolicy: TriggerPolicy(),
      completionModeDetector: CompletionModeDetector(),
      contextExtractor: const ContextExtractor(),
      promptBuilder: const PromptBuilder(),
      postProcessor: const PostProcessor(),
      debouncer: Debouncer(),
    );
    _editorController.bodyController.addListener(_onSelectionOrTextChanged);
  }

  @override
  void dispose() {
    _editorController.bodyController.removeListener(_onSelectionOrTextChanged);
    _editorController.dispose();
    _assistEngine.dispose();
    _taskPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FAFF), Color(0xFFE9F1FF), Color(0xFFF2ECFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C86FF).withValues(alpha: 0.08),
            blurRadius: 80,
            spreadRadius: 10,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6E87FF), Color(0xFF8E6DFF)],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'IETLS Writing Assistant',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.66),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6E87FF).withValues(alpha: 0.16),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_tab_rounded,
                        size: 14,
                        color: Color(0xFF5669C9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tab 接受补全',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.82,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.tab): AcceptSuggestionIntent(),
              SingleActivator(LogicalKeyboardKey.escape):
                  DismissSuggestionIntent(),
              SingleActivator(LogicalKeyboardKey.arrowUp):
                  SelectPreviousSuggestionIntent(),
              SingleActivator(LogicalKeyboardKey.arrowDown):
                  SelectNextSuggestionIntent(),
              SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
                  AcceptWordIntent(),
              SingleActivator(LogicalKeyboardKey.keyR, control: true):
                  RegenerateSuggestionIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                AcceptSuggestionIntent: CallbackAction<AcceptSuggestionIntent>(
                  onInvoke: (intent) => _acceptSuggestion(),
                ),
                AcceptWordIntent: CallbackAction<AcceptWordIntent>(
                  onInvoke: (intent) => _acceptOneWord(),
                ),
                DismissSuggestionIntent:
                    CallbackAction<DismissSuggestionIntent>(
                      onInvoke: (intent) => _dismissSuggestion(),
                    ),
                SelectPreviousSuggestionIntent:
                    CallbackAction<SelectPreviousSuggestionIntent>(
                      onInvoke: (intent) => _selectPreviousSuggestion(),
                    ),
                SelectNextSuggestionIntent:
                    CallbackAction<SelectNextSuggestionIntent>(
                      onInvoke: (intent) => _selectNextSuggestion(),
                    ),
                RegenerateSuggestionIntent:
                    CallbackAction<RegenerateSuggestionIntent>(
                      onInvoke: (intent) => _requestManualSuggestion(),
                    ),
              },
              child: Focus(
                autofocus: true,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1220),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSettingsPanel(),
                          const SizedBox(height: 14),
                          Expanded(
                            child: GhostTextEditor(
                              controller: _editorController.bodyController,
                              focusNode: _editorController.bodyFocusNode,
                              suggestion: _activeSuggestion,
                              onChanged: _onBodyTextChanged,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SuggestionBar(
                            suggestions: _suggestionOptions,
                            selectedIndex: _selectedSuggestionIndex,
                            streaming: _isStreaming,
                            onAccept: _acceptSuggestion,
                            onAcceptWord: _acceptOneWord,
                            onDismiss: _dismissSuggestion,
                            onRegenerate: _requestManualSuggestion,
                            onSelectIndex: _selectSuggestion,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return GlassPanel(
      radius: 20,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 620,
            child: TextFormField(
              controller: _taskPromptController,
              readOnly: true,
              maxLines: 2,
              onTap: _openTaskPromptEditor,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'IELTS 题目',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: '完整编辑',
                  onPressed: _openTaskPromptEditor,
                  icon: const Icon(Icons.open_in_full_rounded),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownMenu<String>(
              initialSelection: _targetBand,
              label: const Text('目标分数'),
              width: 150,
              dropdownMenuEntries: _targetBandOptions
                  .map(
                    (band) =>
                        DropdownMenuEntry<String>(value: band, label: band),
                  )
                  .toList(),
              onSelected: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _targetBand = newValue;
                  });
                }
              },
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownMenu<AssistLevel>(
              initialSelection: _assistLevel,
              label: const Text('AI 触发模式'),
              width: 180,
              dropdownMenuEntries: AssistLevel.values
                  .map(
                    (level) => DropdownMenuEntry<AssistLevel>(
                      value: level,
                      label: level.label,
                    ),
                  )
                  .toList(),
              onSelected: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _assistLevel = newValue;
                  });
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7A9BFF).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF7A9BFF).withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.key_rounded,
                  size: 18,
                  color: Color(0xFF4F63C7),
                ),
                const SizedBox(width: 8),
                const Text(
                  'API Key 从 .env 读取',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F52AE),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: _archiveCurrentDraft,
            icon: const Icon(Icons.archive_outlined),
            label: const Text('归档为 .md'),
          ),
        ],
      ),
    );
  }

  void _onSelectionOrTextChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _onBodyTextChanged(String _) {
    if (_activeSuggestion.isNotEmpty) {
      _assistEngine.cancelActiveSuggestion();
      setState(() {
        _suggestionOptions = const [];
        _selectedSuggestionIndex = 0;
        _isStreaming = false;
      });
    }
    final snapshot = _editorController.captureSnapshot(
      taskPrompt: _taskPromptController.text.trim(),
      targetBand: _targetBand,
    );
    _assistEngine.handleEditorChanged(
      snapshot: snapshot,
      preference: _buildPreference(),
      hasSuggestion: _suggestionOptions.isNotEmpty,
      onSuggestion: _onSuggestionUpdated,
      onError: _onAssistError,
    );
  }

  Future<void> _requestManualSuggestion() async {
    final snapshot = _editorController.captureSnapshot(
      taskPrompt: _taskPromptController.text.trim(),
      targetBand: _targetBand,
    );
    await _assistEngine.requestManualSuggestion(
      snapshot: snapshot,
      preference: _buildPreference(),
      onSuggestion: _onSuggestionUpdated,
      onError: _onAssistError,
    );
  }

  void _onSuggestionUpdated(String suggestion, bool streaming) {
    if (!mounted) {
      return;
    }
    final normalized = _normalizeSuggestionForPreview(suggestion);
    final options = _buildSuggestionOptions(normalized);
    final safeIndex = options.isEmpty
        ? 0
        : _selectedSuggestionIndex.clamp(0, options.length - 1);
    setState(() {
      _suggestionOptions = options;
      _selectedSuggestionIndex = safeIndex;
      _isStreaming = streaming;
    });
  }

  AiAssistPreference _buildPreference() {
    return AiAssistPreference(level: _assistLevel, targetBand: _targetBand);
  }

  String get _activeSuggestion {
    if (_suggestionOptions.isEmpty) {
      return '';
    }
    final index = _selectedSuggestionIndex.clamp(
      0,
      _suggestionOptions.length - 1,
    );
    return _suggestionOptions[index];
  }

  void _selectSuggestion(int index) {
    if (index < 0 || index >= _suggestionOptions.length) {
      return;
    }
    setState(() {
      _selectedSuggestionIndex = index;
    });
  }

  void _selectPreviousSuggestion() {
    if (_suggestionOptions.length < 2) {
      return;
    }
    setState(() {
      _selectedSuggestionIndex =
          (_selectedSuggestionIndex - 1 + _suggestionOptions.length) %
          _suggestionOptions.length;
    });
  }

  void _selectNextSuggestion() {
    if (_suggestionOptions.length < 2) {
      return;
    }
    setState(() {
      _selectedSuggestionIndex =
          (_selectedSuggestionIndex + 1) % _suggestionOptions.length;
    });
  }

  String _normalizeSuggestionForPreview(String suggestion) {
    final controller = _editorController.bodyController;
    final selection = controller.selection;
    if (!selection.isValid) {
      return _normalizeInsertion(
        raw: suggestion,
        before: controller.text,
        after: '',
      );
    }
    final start = selection.start.clamp(0, controller.text.length);
    final end = selection.end.clamp(0, controller.text.length);
    return _normalizeInsertion(
      raw: suggestion,
      before: controller.text.substring(0, start),
      after: controller.text.substring(end),
    );
  }

  List<String> _buildSuggestionOptions(String primary) {
    final p = primary.trimRight();
    if (p.isEmpty) {
      return const [];
    }
    final secondary = _buildSecondarySuggestion(p);
    if (secondary.isEmpty || secondary.toLowerCase() == p.toLowerCase()) {
      return [p];
    }
    return [p, secondary];
  }

  String _buildSecondarySuggestion(String primary) {
    final text = primary.trim();
    if (text.isEmpty || RegExp(r'^[A-Za-z]{1,6}$').hasMatch(text)) {
      return '';
    }

    const starters = <String, String>{
      'however,': 'moreover,',
      'moreover,': 'however,',
      'therefore,': 'consequently,',
      'for example,': 'for instance,',
      'in addition,': 'additionally,',
    };
    final lower = text.toLowerCase();
    for (final entry in starters.entries) {
      if (lower.startsWith(entry.key)) {
        return '${entry.value}${text.substring(entry.key.length)}'.trim();
      }
    }

    if (text.split(RegExp(r'\s+')).length >= 4) {
      final loweredFirst = _lowercaseFirst(text);
      return 'In addition, $loweredFirst';
    }
    return '';
  }

  String _lowercaseFirst(String text) {
    if (text.isEmpty) {
      return text;
    }
    return '${text[0].toLowerCase()}${text.substring(1)}';
  }

  void _onAssistError(String message) {
    if (!mounted) {
      return;
    }
    final text = message.contains('DEEPSEEK_API_KEY')
        ? '请在 .env 中填写 DEEPSEEK_API_KEY 后重启应用。'
        : message;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _archiveCurrentDraft() async {
    final prompt = _taskPromptController.text.trim();
    final body = _editorController.bodyController.text.trimRight();
    if (body.trim().isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前正文为空，无法归档。')));
      return;
    }

    final now = DateTime.now();
    final ts =
        '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final sep = Platform.pathSeparator;
      final archiveDir = Directory('${docDir.path}${sep}ieltsai_archives');
      if (!archiveDir.existsSync()) {
        archiveDir.createSync(recursive: true);
      }
      final path = '${archiveDir.path}${sep}essay_$ts.md';
      final file = File(path);
      final markdown =
          '''
# IELTS Essay Archive

- Archived At: ${now.toIso8601String()}
- Target Band: $_targetBand
- Assist Level: ${_assistLevel.label}

## IELTS Prompt

$prompt

## Essay Content

$body
''';
      await file.writeAsString(markdown, flush: true);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已归档到：$path')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('归档失败：$e')));
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _openTaskPromptEditor() async {
    final draftController = TextEditingController(
      text: _taskPromptController.text,
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑 IELTS 题目'),
          content: SizedBox(
            width: 860,
            child: TextField(
              controller: draftController,
              autofocus: true,
              maxLines: 12,
              style: const TextStyle(fontSize: 17, height: 1.5),
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                hintText: '请输入完整 IELTS Writing Task 2 题目...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (saved == true) {
      setState(() {
        _taskPromptController.text = draftController.text.trim();
      });
    }
    draftController.dispose();
  }

  void _acceptSuggestion() {
    final active = _activeSuggestion;
    if (active.trim().isEmpty) {
      return;
    }
    _insertText(active, normalizeForContext: true);
    _dismissSuggestion();
  }

  void _acceptOneWord() {
    final active = _activeSuggestion;
    if (active.trim().isEmpty) {
      return;
    }
    final match = RegExp(r'^\s*\S+\s*').firstMatch(active);
    if (match == null) {
      return;
    }
    final nextWord = match.group(0) ?? '';
    _insertText(nextWord, normalizeForContext: true);
    final remained = active.substring(nextWord.length).trimLeft();
    setState(() {
      if (remained.isEmpty) {
        _suggestionOptions = const [];
        _selectedSuggestionIndex = 0;
      } else {
        _suggestionOptions = _buildSuggestionOptions(remained);
        _selectedSuggestionIndex = 0;
      }
    });
    if (_suggestionOptions.isEmpty) {
      _dismissSuggestion();
    }
  }

  void _dismissSuggestion() {
    if (_suggestionOptions.isEmpty && !_isStreaming) {
      return;
    }
    _assistEngine.cancelActiveSuggestion();
    setState(() {
      _suggestionOptions = const [];
      _selectedSuggestionIndex = 0;
      _isStreaming = false;
    });
  }

  void _insertText(String text, {bool normalizeForContext = false}) {
    final controller = _editorController.bodyController;
    final selection = controller.selection;
    if (!selection.isValid) {
      final base = controller.text;
      final toInsert = normalizeForContext
          ? _normalizeInsertion(raw: text, before: base, after: '')
          : text;
      controller.value = TextEditingValue(
        text: '$base$toInsert',
        selection: TextSelection.collapsed(
          offset: base.length + toInsert.length,
        ),
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final before = controller.text.substring(0, start);
    final after = controller.text.substring(end);
    final toInsert = normalizeForContext
        ? _normalizeInsertion(raw: text, before: before, after: after)
        : text;
    final merged = '$before$toInsert$after';
    final cursor = before.length + toInsert.length;
    controller.value = TextEditingValue(
      text: merged,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  String _normalizeInsertion({
    required String raw,
    required String before,
    required String after,
  }) {
    var suggestion = raw.replaceAll('\r', '').replaceAll('\n', ' ').trim();
    if (suggestion.isEmpty) {
      return suggestion;
    }

    suggestion = _stripWordOverlapAtStart(
      before: before,
      suggestion: suggestion,
    );
    suggestion = _stripWordOverlapAtEnd(suggestion: suggestion, after: after);

    if (suggestion.isEmpty) {
      return suggestion;
    }

    final trailingToken = _trailingAlphaNumToken(before);
    final suggestionFirstToken = _leadingAlphaNumToken(suggestion);
    final tokenIsPartialContinuation =
        trailingToken.isNotEmpty &&
        suggestionFirstToken.isNotEmpty &&
        suggestionFirstToken.toLowerCase().startsWith(
          trailingToken.toLowerCase(),
        );
    final tokenLooksSuffixContinuation =
        trailingToken.length <= 3 &&
        suggestionFirstToken.isNotEmpty &&
        suggestionFirstToken.length <= 5 &&
        RegExp(r'^[A-Z][a-z]*$').hasMatch(trailingToken) &&
        RegExp(r'^[a-z]+$').hasMatch(suggestionFirstToken);
    final isWordContinuation =
        tokenIsPartialContinuation || tokenLooksSuffixContinuation;

    if (tokenIsPartialContinuation) {
      suggestion = suggestion.replaceFirst(
        RegExp('^\\s*${RegExp.escape(trailingToken)}', caseSensitive: false),
        '',
      );
    }

    if (suggestion.isEmpty) {
      return suggestion;
    }

    if (before.isNotEmpty && RegExp(r'\s$').hasMatch(before)) {
      suggestion = suggestion.replaceFirst(RegExp(r'^\s+'), '');
    }
    if (after.isNotEmpty && RegExp(r'^\s').hasMatch(after)) {
      suggestion = suggestion.replaceFirst(RegExp(r'\s+$'), '').trimRight();
    }

    if (suggestion.isEmpty) {
      return suggestion;
    }

    final firstChar = _firstNonSpaceChar(suggestion);
    final lastChar = _lastNonSpaceChar(suggestion);
    final beforeEndsWithSpace =
        before.isNotEmpty && RegExp(r'\s$').hasMatch(before);
    final afterStartsWithSpace =
        after.isNotEmpty && RegExp(r'^\s').hasMatch(after);
    final needsLeadingSpace =
        before.isNotEmpty &&
        !beforeEndsWithSpace &&
        !isWordContinuation &&
        firstChar != null &&
        !_isPunctuation(firstChar) &&
        !_isOpeningBracket(firstChar);
    final needsTrailingSpace =
        after.isNotEmpty &&
        !afterStartsWithSpace &&
        lastChar != null &&
        !_isPunctuation(lastChar) &&
        !_isClosingBracket(lastChar);

    if (needsLeadingSpace && !RegExp(r'^\s').hasMatch(suggestion)) {
      suggestion = ' $suggestion';
    }
    if (needsTrailingSpace && !RegExp(r'\s$').hasMatch(suggestion)) {
      suggestion = '$suggestion ';
    }
    return suggestion;
  }

  String _stripWordOverlapAtStart({
    required String before,
    required String suggestion,
  }) {
    final beforeWords = _normalizedWords(before);
    final rawSuggestionWords = suggestion.split(RegExp(r'\s+'));
    final suggestionWords = rawSuggestionWords
        .map(_normalizeWordForCompare)
        .where((word) => word.isNotEmpty)
        .toList();
    if (beforeWords.isEmpty || suggestionWords.isEmpty) {
      return suggestion;
    }

    final maxLen = beforeWords.length < suggestionWords.length
        ? beforeWords.length
        : suggestionWords.length;
    var overlapCount = 0;
    for (var len = maxLen; len > 0; len--) {
      final beforeSlice = beforeWords.sublist(beforeWords.length - len);
      final suggestionSlice = suggestionWords.sublist(0, len);
      if (_listEquals(beforeSlice, suggestionSlice)) {
        overlapCount = len;
        break;
      }
    }
    if (overlapCount == 0) {
      return suggestion;
    }
    if (overlapCount >= rawSuggestionWords.length) {
      return '';
    }
    return rawSuggestionWords.sublist(overlapCount).join(' ').trimLeft();
  }

  String _stripWordOverlapAtEnd({
    required String suggestion,
    required String after,
  }) {
    final rawSuggestionWords = suggestion.split(RegExp(r'\s+'));
    final suggestionWords = rawSuggestionWords
        .map(_normalizeWordForCompare)
        .where((word) => word.isNotEmpty)
        .toList();
    final afterWords = _normalizedWords(after);
    if (suggestionWords.isEmpty || afterWords.isEmpty) {
      return suggestion;
    }

    final maxLen = suggestionWords.length < afterWords.length
        ? suggestionWords.length
        : afterWords.length;
    var overlapCount = 0;
    for (var len = maxLen; len > 0; len--) {
      final suggestionSlice = suggestionWords.sublist(
        suggestionWords.length - len,
      );
      final afterSlice = afterWords.sublist(0, len);
      if (_listEquals(suggestionSlice, afterSlice)) {
        overlapCount = len;
        break;
      }
    }
    if (overlapCount == 0) {
      return suggestion;
    }
    final keepCount = rawSuggestionWords.length - overlapCount;
    if (keepCount <= 0) {
      return '';
    }
    return rawSuggestionWords.sublist(0, keepCount).join(' ').trimRight();
  }

  List<String> _normalizedWords(String text) {
    return text
        .split(RegExp(r'\s+'))
        .map(_normalizeWordForCompare)
        .where((word) => word.isNotEmpty)
        .toList();
  }

  String _normalizeWordForCompare(String word) {
    return word
        .toLowerCase()
        .replaceAll(RegExp(r'^[^a-z0-9]+|[^a-z0-9]+$'), '')
        .trim();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  bool _isPunctuation(String char) => RegExp(r'[.,!?;:\-]').hasMatch(char);

  bool _isOpeningBracket(String char) => RegExp(r'[\(\[\{"]').hasMatch(char);

  bool _isClosingBracket(String char) => RegExp(r'[\)\]\}"]').hasMatch(char);

  String _trailingAlphaNumToken(String text) {
    final match = RegExp(r'([A-Za-z0-9]+)$').firstMatch(text);
    return match?.group(1) ?? '';
  }

  String _leadingAlphaNumToken(String text) {
    final match = RegExp(r'^\s*([A-Za-z0-9]+)').firstMatch(text);
    return match?.group(1) ?? '';
  }

  String? _firstNonSpaceChar(String text) {
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (!RegExp(r'\s').hasMatch(char)) {
        return char;
      }
    }
    return null;
  }

  String? _lastNonSpaceChar(String text) {
    for (var i = text.length - 1; i >= 0; i--) {
      final char = text[i];
      if (!RegExp(r'\s').hasMatch(char)) {
        return char;
      }
    }
    return null;
  }
}
