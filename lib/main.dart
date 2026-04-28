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

      // TÔNG SÁNG: Xám nhạt & Xanh Blue
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Nền xám cực nhẹ
      ),

      // TÔNG TỐI: Sửa từ Đen sang Xám Đậm (Charcoal)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // Nền chính xám tối (Dark Grey) giúp giảm hiện tượng nhòe màn hình
        scaffoldBackgroundColor: const Color(0xFF121212),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),

        // Màu của các khung (Card/Container) xám nhẹ hơn nền để tạo khối
        cardColor: const Color(0xFF1E1E1E),

        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,    // Màu nhấn cho các nút
          surface: Color(0xFF1E1E1E),    // Màu các thành phần bề mặt
          onSurface: Colors.white70,     // Màu chữ trên bề mặt
          secondary: Colors.grey,
        ),

        // Tùy chỉnh text để không bị quá sáng (đỡ mỏi mắt)
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
          bodyMedium: TextStyle(color: Color(0xFFBDBDBD)),
        ),
      ),

      home: MainScreen(
        currentMode: _themeMode,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}