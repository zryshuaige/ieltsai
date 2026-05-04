enum AssistLevel { frequent, balanced, manual }

extension AssistLevelX on AssistLevel {
  String get label {
    switch (this) {
      case AssistLevel.frequent:
        return '频繁';
      case AssistLevel.balanced:
        return '较少';
      case AssistLevel.manual:
        return '手动';
    }
  }
}

class AiAssistPreference {
  const AiAssistPreference({required this.level, required this.targetBand});

  final AssistLevel level;
  final String targetBand;
}
