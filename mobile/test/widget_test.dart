import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectx/main.dart';

void main() {
  testWidgets('Nexora app boots up successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NexoraApp()));
    
    // Allow the router to settle
    await tester.pumpAndSettle();
    
    // We expect to be on the login screen
    expect(find.text('Login'), findsWidgets);
  });
}
