import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studentski_asistent/auth/auth_controller.dart';
import 'package:studentski_asistent/main.dart';
import 'package:studentski_asistent/screens/auth_screen.dart';

void main() {
  testWidgets('App builds — prikaz prijave bez tokena', (tester) async {
    final auth = AuthController();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: const StudentskiAsistentApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
