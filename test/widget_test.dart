import 'package:flutter_test/flutter_test.dart';
import 'package:komunidad/main.dart';
import 'package:komunidad/login.dart';

void main() {
  testWidgets('Landing Page navigation test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // ✅ Check if "Sign Up" is visible
    expect(find.text('Sign Up'), findsOneWidget);

    // ✅ Check if "Login" is visible
    expect(find.text('Login'), findsOneWidget);

    // ✅ Check if Google button is visible
    expect(find.text('Continue with Google'), findsOneWidget);

    // ✅ Tap on Google button → should navigate to FirstPage
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.byType(FirsPage), findsOneWidget);

    // ✅ Go back to LandingPage
    await tester.pageBack();
    await tester.pumpAndSettle();

    // ✅ Tap on Login button → should navigate to LoginPage
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}

class FirsPage {}
