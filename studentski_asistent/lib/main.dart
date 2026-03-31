import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';
import 'config/api_config.dart';
import 'data/student_repository.dart';
import 'screens/admin_shell.dart';
import 'screens/auth_screen.dart';
import 'screens/student_home_shell.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthController();
  await auth.loadFromStorage();
  runApp(
    ChangeNotifierProvider<AuthController>.value(
      value: auth,
      child: const StudentskiAsistentApp(),
    ),
  );
  // Provera sesije na mreži posle prvog frejma — ne blokira prazan ekran ako backend ne odgovara.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(auth.validateStoredSession());
  });
}

class StudentskiAsistentApp extends StatelessWidget {
  const StudentskiAsistentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studentski asistent',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('sr', 'RS'),
        Locale('en', 'US'),
      ],
      home: Consumer<AuthController>(
        builder: (context, auth, _) {
          if (auth.isSessionResolving) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!auth.isAuthenticated) {
            return const AuthScreen();
          }
          final repo = StudentRepository(
            baseUrl: resolveGatewayUrl(),
            getToken: auth.getToken,
          );
          if (auth.isAdmin) {
            return AdminShell(getToken: auth.getToken);
          }
          return StudentHomeShell(repo: repo, getToken: auth.getToken);
        },
      ),
    );
  }
}
