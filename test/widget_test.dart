import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieltsai/app/ielts_ai_app.dart';

void main() {
  testWidgets('loads editor and accepts toolbar actions', (tester) async {
    await tester.pumpWidget(const IeltsAiApp());

    expect(find.text('IETLS Writing Assistant'), findsOneWidget);
    expect(find.text('AI 触发模式'), findsWidgets);
    expect(find.text('目标分数'), findsWidgets);
    expect(find.textContaining('No suggestion'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('essay-body-field')),
      'I agree with this view because ',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('essay-body-field')), findsOneWidget);
  });
}
