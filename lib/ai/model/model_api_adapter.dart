import 'package:ieltsai/ai/models/ai_request.dart';

abstract class ModelApiAdapter {
  Stream<String> streamComplete(AiRequest request);
}
