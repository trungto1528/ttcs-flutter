import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Auth {
  Future<String> login(String username, String password) async {
    final res = await http.post(
      Uri.parse("http://140.245.45.167:7777/api/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    if (res.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("user", res.body);
      return "Logged In";
    } else {
      return res.body;
    }
  }

  Future<String> register(
    String username,
    String password,
    String displayName,
  ) async {
    final res = await http.post(
      Uri.parse("http://140.245.45.167:7777/api/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
        'displayName': displayName,
      }),
    );
    if (res.statusCode == 200) {
      return "OK";
    } else {
      return res.body;
    }
  }

  Future<String> changePassword(
    String username,
    String oldPass,
    String newPass,
  ) async {
    final uri =
        Uri.parse(
          "http://140.245.45.167:7777/api/users/change-password",
        ).replace(
          queryParameters: {
            "username": username,
            "oldPassword": oldPass,
            "newPassword": newPass,
          },
        );

    final res = await http.post(uri);

    return res.body;
  }

  Future<String> fetchUser(int userId) async {
    final res = await http.get(
      Uri.parse("http://140.245.45.167:7777/api/auth/fetch/$userId"),
    );
    return res.body;
  }
  Future<String> updateDisplayName(int userId, String newName) async {
    try {
      final response = await http.post(
        Uri.parse("http://140.245.45.167:7777/api/users/$userId/displayName"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "displayName": newName,
        }),
      );

      if (response.statusCode == 200) {
        return "OK";
      } else {
        return jsonDecode(response.body)["message"] ?? "Lỗi server";
      }
    } catch (e) {
      return "Lỗi kết nối";
    }
  }
}
