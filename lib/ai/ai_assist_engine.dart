import 'dart:async';

import 'package:ieltsai/ai/ai_assist_preference.dart';
import 'package:ieltsai/ai/completion_mode_detector.dart';
import 'package:ieltsai/ai/context_extractor.dart';
import 'package:ieltsai/ai/debouncer.dart';
import 'package:ieltsai/ai/model/model_api_adapter.dart';
import 'package:ieltsai/ai/post_processor.dart';
import 'package:ieltsai/ai/prompt_builder.dart';
import 'package:ieltsai/ai/trigger_policy.dart';
import 'package:ieltsai/editor/document_snapshot.dart';

typedef SuggestionListener = void Function(String suggestion, bool streaming);
typedef AssistErrorListener = void Function(String message);

class AiAssistEngine {
  AiAssistEngine({
    required ModelApiAdapter modelApiAdapter,
    required TriggerPolicy triggerPolicy,
    required CompletionModeDetector completionModeDetector,
    required ContextExtractor contextExtractor,
    required PromptBuilder promptBuilder,
    required PostProcessor postProcessor,
    required Debouncer debouncer,
  }) : _modelApiAdapter = modelApiAdapter,
       _triggerPolicy = triggerPolicy,
       _completionModeDetector = completionModeDetector,
       _contextExtractor = contextExtractor,
       _promptBuilder = promptBuilder,
       _postProcessor = postProcessor,
       _debouncer = debouncer;

  final ModelApiAdapter _modelApiAdapter;
  final TriggerPolicy _triggerPolicy;
  final CompletionModeDetector _completionModeDetector;
  final ContextExtractor _contextExtractor;
  final PromptBuilder _promptBuilder;
  final PostProcessor _postProcessor;
  final Debouncer _debouncer;

  DateTime? _lastRequestedAt;
  int _requestToken = 0;
  bool _apiUnavailable = false;

  void handleEditorChanged({
    required DocumentSnapshot snapshot,
    required AiAssistPreference preference,
    required bool hasSuggestion,
    required SuggestionListener onSuggestion,
    required AssistErrorListener onError,
  }) {
    if (preference.level == AssistLevel.manual || _apiUnavailable) {
      return;
    }

    final waitDuration = preference.level == AssistLevel.frequent
        ? const Duration(milliseconds: 600)
        : const Duration(milliseconds: 1500);
    _debouncer.run(waitDuration, () {
      _requestAutoSuggestion(
        snapshot: snapshot,
        preference: preference,
        hasSuggestion: hasSuggestion,
        onSuggestion: onSuggestion,
        onError: onError,
      );
    });
  }

  Future<void> requestManualSuggestion({
    required DocumentSnapshot snapshot,
    required AiAssistPreference preference,
    required SuggestionListener onSuggestion,
    required AssistErrorListener onError,
  }) async {
    if (_apiUnavailable) {
      onError(
        'DEEPSEEK_API_KEY is missing in .env. Please configure it before requesting suggestions.',
      );
      return;
    }
    final now = DateTime.now();
    if (!_triggerPolicy.shouldManualTrigger(
      snapshot: snapshot,
      now: now,
      lastRequestedAt: _lastRequestedAt,
    )) {
      return;
    }
    await _streamSuggestion(
      snapshot: snapshot,
      preference: preference,
      onSuggestion: onSuggestion,
      onError: onError,
    );
  }

  Future<void> _requestAutoSuggestion({
    required DocumentSnapshot snapshot,
    required AiAssistPreference preference,
    required bool hasSuggestion,
    required SuggestionListener onSuggestion,
    required AssistErrorListener onError,
  }) async {
    final now = DateTime.now();
    final shouldTrigger = _triggerPolicy.shouldAutoTrigger(
      level: preference.level,
      snapshot: snapshot,
      now: now,
      lastRequestedAt: _lastRequestedAt,
      hasSuggestion: hasSuggestion,
    );
    if (!shouldTrigger) {
      return;
    }
    await _streamSuggestion(
      snapshot: snapshot,
      preference: preference,
      onSuggestion: onSuggestion,
      onError: onError,
    );
  }

  Future<void> _streamSuggestion({
    required DocumentSnapshot snapshot,
    required AiAssistPreference preference,
    required SuggestionListener onSuggestion,
    required AssistErrorListener onError,
  }) async {
    _requestToken += 1;
    final currentToken = _requestToken;
    final leftText = snapshot.text.substring(0, snapshot.cursorOffset);
    final mode = _completionModeDetector.detect(leftText);
    final draftRequest = _contextExtractor.extract(
      snapshot: snapshot,
      completionMode: mode,
      prompt: '',
    );
    final request = _contextExtractor.extract(
      snapshot: snapshot,
      completionMode: mode,
      prompt: _promptBuilder.build(draftRequest),
    );

    final buffer = StringBuffer();
    try {
      await for (final chunk in _modelApiAdapter.streamComplete(request)) {
        if (currentToken != _requestToken) {
          return;
        }
        buffer.write(chunk);
        onSuggestion(_postProcessor.clean(buffer.toString()), true);
      }
    } on StateError catch (e) {
      final message = e.message.toString();
      if (message.contains('DEEPSEEK_API_KEY')) {
        _apiUnavailable = true;
      }
      onError(message);
      onSuggestion('', false);
      return;
    }

    if (currentToken != _requestToken) {
      return;
    }

    _lastRequestedAt = DateTime.now();
    onSuggestion(_postProcessor.clean(buffer.toString()), false);
  }

  void cancelActiveSuggestion() {
    _requestToken += 1;
  }

  void dispose() {
    _debouncer.dispose();
  }
}
