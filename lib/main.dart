import 'package:flutter/material.dart';
import 'package:novel_app/route_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';
import 'models/app_theme_mode.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final index = prefs.getInt('themeMode') ?? 2;

  runApp(MyApp(initialMode: AppThemeMode.values[index]));
}
class MyApp extends StatefulWidget {
  final AppThemeMode initialMode;

  const MyApp({super.key, required this.initialMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppThemeMode _themeMode = AppThemeMode.system;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialMode;
  }

  // Future<void> _loadTheme() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final index = prefs.getInt('themeMode') ?? 2;
  //   setState(() {
  //     _themeMode = AppThemeMode.values[index];
  //   });
  // }

  Future<void> _saveTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  void _changeTheme(AppThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    _saveTheme(mode);
  }

  ThemeMode get _flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      themeMode: _flutterThemeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
        ),
        cardColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF121212),
        ),
      ),
      home: MainScreen(
        currentMode: _themeMode,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}
