import 'package:flutter/material.dart';
import 'package:novel_app/screens/login_screen.dart';

import '../models/app_theme_mode.dart';

class ProfilePage extends StatefulWidget {
  final AppThemeMode currentMode;
  final Function(AppThemeMode) onThemeChanged;

  const ProfilePage({
    super.key,
    required this.currentMode,
    required this.onThemeChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user; //  null = chưa login
  final baseAvatar = "http://140.245.45.167:7778/avatar";

  void logout() {
    setState(() {
      user = null;
    });
  }

  void goLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (result != null) {
      setState(() {
        user = result; // 🔥 nhận user từ login
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tài khoản")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user == null) ...[
            const Icon(Icons.person, size: 80),
            const SizedBox(height: 10),
            const Text("Chưa đăng nhập", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: goLogin, child: const Text("Đăng nhập")),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: CircleAvatar(
                radius:100,
              child: SizedBox(
                height: 400,
                width: 400,
                // child:
                // ClipRRect(
                //   borderRadius: BorderRadius.circular(50),
                  child: Image.network(
                    baseAvatar+user!['avatarUrl'],
                    fit: BoxFit.scaleDown,
                  ),
                // ),
              ),
            ),
            ),
            const SizedBox(height: 10),
            Text(
              user!["username"],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: logout, child: const Text("Đăng xuất")),
          ],

          const SizedBox(height: 30),

          /// 🎨 THEME
          RadioGroup<AppThemeMode>(
            groupValue: widget.currentMode,
            onChanged: (value) {
              if (value != null) {
                widget.onThemeChanged(value);
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
        ],
      ),
    );
  }
}
