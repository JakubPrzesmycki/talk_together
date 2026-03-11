import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talk_together/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('app bootstraps successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('pl'),
          Locale('es'),
          Locale('fr'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const TalkTogetherApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(TalkTogetherApp), findsOneWidget);
  });
}
