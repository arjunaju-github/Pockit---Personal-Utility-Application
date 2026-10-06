import 'package:flutter/material.dart';
import 'homepage.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

      theme: ThemeData(fontFamily: 'Poppins', brightness: Brightness.light),

      darkTheme: ThemeData(fontFamily: 'Poppins', brightness: Brightness.dark),

      home: const HomePage(),
    );
  }
}
