// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskova_shopkeeper/auth/login.dart';
import 'package:taskova_shopkeeper/language/language_provider.dart';
import 'package:taskova_shopkeeper/language/language_selection_screen.dart';
import 'package:taskova_shopkeeper/main.dart';



void main() {
  testWidgets('App shows LanguageSelectionScreen when language not selected', 
      (WidgetTester tester) async {
    // Mock hasSelectedLanguage as false
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppLanguage(),
        child: const MyApp(hasSelectedLanguage: false),
      ),
    );

    // Verify that LanguageSelectionScreen is shown
    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    expect(find.byType(Login), findsNothing);
  });

  testWidgets('App shows Login when language is already selected', 
      (WidgetTester tester) async {
    // Mock hasSelectedLanguage as true
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppLanguage(),
        child: const MyApp(hasSelectedLanguage: true),
      ),
    );

    // Verify that Login screen is shown
    expect(find.byType(Login), findsOneWidget);
    expect(find.byType(LanguageSelectionScreen), findsNothing);
  });
}