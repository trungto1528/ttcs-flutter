import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String? error;
  bool isLoading = false;

  Future<void> register() async {
    setState(() {
      error = null;
    });

    // ✅ validate cơ bản
    if (usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        error = "Vui lòng nhập đầy đủ thông tin";
      });
      return;
    }

    if (passwordController.text != confirmController.text) {
      setState(() {
        error = "Mật khẩu không khớp";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final res = await http.post(
        Uri.parse("http://140.245.45.167:7777/api/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text,
          "password": passwordController.text,
        }),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        setState(() {
          error = res.body;
        });
      }
    } catch (e) {
      setState(() {
        error = "Lỗi kết nối server";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 20),

            const Text(
              "Tạo tài khoản",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: isLoading ? null : register,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Đăng ký"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context); // quay lại login
              },
              child: const Text("Đã có tài khoản? Đăng nhập"),
            ),
          ],
        ),
      ),
    );
  }
}