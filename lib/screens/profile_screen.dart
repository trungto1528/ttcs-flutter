import 'dart:convert';
import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:novel_app/screens/login_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/User.dart';
import '../models/app_theme_mode.dart';
import '../services/auth.dart';
import 'change_password.dart';

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

class _EditDisplayNameDialog extends StatefulWidget {
  final String currentName;

  const _EditDisplayNameDialog({required this.currentName});

  @override
  State<_EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<_EditDisplayNameDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.currentName);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Đổi tên hiển thị"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: "Tên hiển thị"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // huỷ
          child: const Text("Huỷ"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text), // lưu
          child: const Text("Lưu"),
        ),
      ],
    );
  }
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Giao diện",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

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
                      title: Text("Sáng"),
                    ),
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
      },
    );
  }

  Future<void> _changeAvatar(
    BuildContext context,
    String username,
    Function(String newUrl) _onUpdated,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final imageBytes = await pickedFile.readAsBytes();
    final cropController = CropController();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text("Chỉnh avatar"),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  cropController.crop();
                },
              ),
            ],
          ),
          body: Crop(
            controller: cropController,
            image: imageBytes,
            aspectRatio: 1,
            withCircleUi: true,
            onCropped: (croppedData) async {
              Navigator.pop(context);

              final tempDir = await getTemporaryDirectory();
              final tempFile = File('${tempDir.path}/avatar.png');
              await tempFile.writeAsBytes(croppedData);

              try {
                var request = http.MultipartRequest(
                  'POST',
                  Uri.parse(
                    "http://140.245.45.167:7777/api/users/upload-avatar",
                  ),
                );
                request.fields['username'] = username;
                request.files.add(
                  await http.MultipartFile.fromPath('file', tempFile.path),
                );

                var response = await request.send();

                if (response.statusCode == 200) {
                  final resBody = await response.stream.bytesToString();
                  _onUpdated(resBody);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đổi avatar thành công")),
                  );
                  _loadUser();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Upload thất bại")),
                  );
                }
              } finally {
                if (await tempFile.exists()) {
                  await tempFile.delete();
                }
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
        title: const Text("Tài khoản"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user == null) ...[
            const Icon(Icons.person, size: 80),
            const SizedBox(height: 10),
            const Text("Chưa đăng nhập", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _goLogin, child: const Text("Đăng nhập")),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipOval(
                    child: Image.network(
                      "$baseAvatar${user!.avatarUrl}?t=${DateTime.now().millisecondsSinceEpoch}",
                      key: UniqueKey(),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error);
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user!.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final newName = await showDialog<String>(
                        context: context,
                        builder: (context) => _EditDisplayNameDialog(
                          currentName: user!.displayName,
                        ),
                      );
                      if (newName != null && newName.isNotEmpty) {
                        final result = await Auth().updateDisplayName(
                          user!.id,
                          newName,
                        );
                        if (result == "OK") {
                          setState(() {
                            user!.displayName = newName;
                          });
                        } else {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(result)));
                        }
                      }
                    },
                    child: const Icon(Icons.edit, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("Đổi mật khẩu"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Theme.of(context).cardColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChangePasswordScreen(username: user!.username),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text("Đổi avatar"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Theme.of(context).cardColor,
              onTap: () {
                _changeAvatar(context, user!.username, (newUrl) async {
                  setState(() {
                    user!.avatarUrl = newUrl;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString("user", jsonEncode(user!.toJson()));
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: logout, child: const Text("Đăng xuất")),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
