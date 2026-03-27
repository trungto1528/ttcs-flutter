import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:novel_app/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("user");
    setState(() {
      user = null;
    });
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString("user");

    if (userStr != null) {
      setState(() {
        user = jsonDecode(userStr);
      });
    }
  }

  void goLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("user", jsonEncode(result));

      setState(() {
        user = result;
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
              child: Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: baseAvatar + user!['avatarUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                    ),
                  )
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

          /// THEME
          RadioGroup<AppThemeMode>(
            groupValue: widget.currentMode,
            onChanged: (value) {
              if (value != null) {
                widget.onThemeChanged(value);
              }
            },
            child: Column(
              children: const [
                RadioListTile(value: AppThemeMode.light, title: Text("Sáng")),
                RadioListTile(value: AppThemeMode.dark, title: Text("Tối")),
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
