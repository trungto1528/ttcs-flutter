import 'package:flutter/material.dart';
import '../models/app_theme_mode.dart';
class ProfilePage extends StatelessWidget {
  final AppThemeMode currentMode;
  final Function(AppThemeMode) onThemeChanged;

  const ProfilePage({
    super.key,
    required this.currentMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tài khoản")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: RadioGroup<AppThemeMode>(
          groupValue: currentMode,
          onChanged: (value) {
            if (value != null) {
              onThemeChanged(value);
            }
          },
          child: Column(
            children: const [
              RadioListTile(
                value: AppThemeMode.light,
                title: Text("Light Mode"),
              ),
              RadioListTile(
                value: AppThemeMode.dark,
                title: Text("Dark Mode (Kindle)"),
              ),
              RadioListTile(
                value: AppThemeMode.system,
                title: Text("Theo hệ thống"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}