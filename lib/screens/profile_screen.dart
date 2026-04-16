import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/User.dart';
import '../models/app_theme_mode.dart';
import '../services/auth.dart';
import '../services/ota.dart';

import 'admin_management.dart';
import 'change_password.dart';
import 'create_chapter_screen.dart';
import 'create_story_screen.dart';
import 'login_screen.dart';
import 'my_stories.dart';

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
  User? user;

  final baseAvatar = "http://140.245.45.167:7778/avatar";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString("user");

    if (userStr != null) {
      setState(() {
        user = User.fromJson(jsonDecode(userStr));
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("user");
    setState(() => user = null);
  }

  Future<void> _goLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (result == true) {
      await _loadUser();
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          const Text("Giao diện",
              style: TextStyle(fontWeight: FontWeight.bold)),
          RadioGroup<AppThemeMode>(
            groupValue: widget.currentMode,
            onChanged: (value) {
              if (value != null) widget.onThemeChanged(value);
            },
            child: const Column(
              children: [
                RadioListTile(value: AppThemeMode.light, title: Text("Sáng")),
                RadioListTile(value: AppThemeMode.dark, title: Text("Tối")),
                RadioListTile(
                    value: AppThemeMode.system,
                    title: Text("Theo hệ thống")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkUpdate() async {
    await OtaService().checkAndUpdate(context);
  }

  Future<void> _changeName() async {
    if (user == null) return;

    final controller = TextEditingController(text: user!.displayName);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đổi tên"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Huỷ")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Lưu")),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final res = await Auth().updateDisplayName(user!.id, newName);

      if (res == "OK") {
        setState(() => user!.displayName = newName);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("user", jsonEncode(user!.toJson()));
      }
    }
  }

  Future<void> _changeAvatar() async {
    if (user == null) return;

    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final controller = CropController();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text("Cắt ảnh"),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => controller.crop(),
              )
            ],
          ),
          body: Crop(
            controller: controller,
            image: bytes,
            aspectRatio: 1,
            withCircleUi: true,
            onCropped: (data) async {
              Navigator.pop(context);

              final dir = await getTemporaryDirectory();
              final file = File("${dir.path}/avatar.png");
              await file.writeAsBytes(data);

              var request = http.MultipartRequest(
                'POST',
                Uri.parse(
                    "http://140.245.45.167:7777/api/users/upload-avatar"),
              );

              request.fields['username'] = user!.username;
              request.files
                  .add(await http.MultipartFile.fromPath('file', file.path));

              final res = await request.send();

              if (res.statusCode == 200) {
                final body = await res.stream.bytesToString();

                setState(() => user!.avatarUrl = body);

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString("user", jsonEncode(user!.toJson()));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Theme.of(context).cardColor,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tài khoản"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user == null) ...[
            const Icon(Icons.person, size: 80),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _goLogin, child: const Text("Đăng nhập")),
          ] else ...[
            Center(
              child: GestureDetector(
                onTap: _changeAvatar,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: "$baseAvatar${user!.avatarUrl}",
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user!.displayName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: _changeName),
              ],
            ),

            const SizedBox(height: 20),

            _tile(Icons.add_box, "Đăng truyện",
                    () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateStoryScreen()))),

            _tile(Icons.post_add, "Đăng chương",
                    () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateChapterScreen()))),

            _tile(Icons.menu_book, "Truyện của tôi",
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MyStoriesScreen(userId: user!.id)))),

            if (user!.role == "ADMIN")
              _tile(Icons.admin_panel_settings, "Quản lý truyện",
                      () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AdminStoryManagerScreen(adminId: user!.id)))),

            _tile(Icons.lock, "Đổi mật khẩu",
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ChangePasswordScreen(username: user!.username)))),

            _tile(Icons.system_update, "Kiểm tra cập nhật", _checkUpdate),

            _tile(Icons.logout, "Đăng xuất", logout),
          ]
        ],
      ),
    );
  }
}