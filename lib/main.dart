import 'package:flutter/material.dart';
import 'package:ieltsai/app/ielts_ai_app.dart';
import 'package:ieltsai/config/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  runApp(const IeltsAiApp());
}
