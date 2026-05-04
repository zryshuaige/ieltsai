import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get deepSeekApiKey =>
      dotenv.env['DEEPSEEK_API_KEY']?.trim() ?? '';

  static bool get hasDeepSeekApiKey => deepSeekApiKey.isNotEmpty;
}
