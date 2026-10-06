import 'package:demoapp/pages/intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authscreen.dart';
import 'homepage.dart';
import 'services/task_notification_service.dart';
//import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TaskNotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<Map<String, bool>> checkAppState() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'seenOnboarding': prefs.getBool('seenOnboarding') ?? false,
      'isLoggedIn': prefs.getBool('isLoggedIn') ?? false,
    };
  }

  ThemeMode themeMode = ThemeMode.light;

  void setLightTheme() {
    setState(() {
      themeMode = ThemeMode.light;
    });
  }

  void setDarkTheme() {
    setState(() {
      themeMode = ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      themeMode: themeMode,

      theme: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.light,

        primaryColor: const Color(0xFF332121),

        scaffoldBackgroundColor: Colors.grey.shade100,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),

        colorScheme: const ColorScheme.light(
          primary: Color(0xFF332121),
          secondary: Color(0xFF6B4F4F),
        ),
      ),

      darkTheme: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.dark,

        scaffoldBackgroundColor: Colors.black12,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black12,
          foregroundColor: Colors.black,
        ),

        colorScheme: const ColorScheme.dark(
          primary: Colors.white, //locked
          secondary: Colors.black12,
        ),
      ),

      home: FutureBuilder(
        future: checkAppState(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final result = snapshot.data as Map<String, bool>;

          if (!result['seenOnboarding']!) {
            return const OnboardingScreen();
          } else if (result['isLoggedIn']!) {
            return const HomePage();
          } else {
            return const AuthPage();
          }
        },
      ),
    );
  }
}
