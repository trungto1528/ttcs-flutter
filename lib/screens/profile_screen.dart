import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/User.dart';
import '../models/app_theme_mode.dart';
import '../services/ota.dart';
import 'admin_management.dart';
import 'change_password.dart';
import 'crawl_screen.dart';
import 'login_screen.dart';
import 'my_stories.dart';
import 'story_chapter_create.dart';

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

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case "ADMIN":
        return Colors.green;
      default:
        return Colors.blueGrey;
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
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                "Cài đặt",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              //  DARK / LIGHT MODE
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text("Giao diện"),
                trailing: DropdownButton<AppThemeMode>(
                  value: widget.currentMode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: AppThemeMode.light,
                      child: Text("Sáng"),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.dark,
                      child: Text("Tối"),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.system,
                      child: Text("Hệ thống"),
                    ),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      widget.onThemeChanged(mode);
                    }
                  },
                ),
              ),

              //  ĐỔI MẬT KHẨU
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Đổi mật khẩu"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChangePasswordScreen(username: user!.username),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text("Kiểm tra cập nhật"),
                onTap: () {
                  Navigator.pop(context);
                  OtaService().checkAndUpdate(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final file = File(picked.path);

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("http://140.245.45.167:7777/api/users/upload-avatar"),
      );

      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      request.fields["username"] = user!.username;

      var response = await request.send();

      if (response.statusCode == 200) {
        final fileName = await response.stream.bytesToString();

        setState(() {
          user!.avatarUrl = "/$fileName";
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("user", jsonEncode(user));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật avatar thành công")),
        );
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lỗi upload avatar")));
    }
  }

  Future<void> _changeName() async {
    final controller = TextEditingController(text: user!.displayName);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đổi tên"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Lưu"),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty) return;

    try {
      final res = await http.post(
        Uri.parse(
          "http://140.245.45.167:7777/api/users/${user!.id}/displayName",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"displayName": newName}),
      );

      if (res.statusCode == 200) {
        setState(() {
          user!.displayName = newName;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("user", jsonEncode(user));

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đổi tên thành công")));
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _changeAvatar,
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: "$baseAvatar${user!.avatarUrl}",
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox(
                width: 72,
                height: 72,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => const Icon(Icons.person, size: 72),
            ),
          ),
        ),
        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      user!.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _changeName,
                    child: const Icon(Icons.edit, size: 18),
                  ),
                ],
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "@${user!.username}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user!.role),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user!.role,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Nút logout
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: logout,
        ),
      ],
    );
  }

  bool get isAdmin => user?.role.toUpperCase() == "ADMIN";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tài khoản"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user == null) ...[
            const SizedBox(height: 40),
            const Icon(Icons.person, size: 80),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: _goLogin,
                child: const Text("Đăng nhập"),
              ),
            ),
          ] else ...[
            _buildHeader(),
            const SizedBox(height: 20),

            // ================= COMMON =================
            _tile(Icons.add_box, "Đăng nội dung", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoryChapterScreen()),
              );
            }),

            _tile(Icons.menu_book, "Truyện của tôi", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyStoriesScreen(userId: user!.id),
                ),
              );
            }),

            // ================= ADMIN ONLY =================
            if (isAdmin)
              _tile(Icons.admin_panel_settings, "Quản lý tất cả truyện", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminStoryManagerScreen(adminId: user!.id),
                  ),
                );
              }),
            if (isAdmin)
              _tile(Icons.cloud_download, "Nettrom Simulator🐧🐧🐧", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CrawlScreen(userId:user!.id),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}
