import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class OtaService {
  final String api =
      "https://api.github.com/repos/trungto1528/ttcs-flutter/releases/latest";

  // ================= PARSE VERSION =================
  Map<String, dynamic> _parseTag(String tag) {
    // v1.0.2+4
    final clean = tag.replaceFirst('v', '');
    final parts = clean.split('+');

    final versionName = parts[0];
    final buildNumber = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return {
      "versionName": versionName,
      "buildNumber": buildNumber,
    };
  }

  // ================= GET LOCAL VERSION =================
  Future<Map<String, dynamic>> getLocalVersion() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "versionName": prefs.getString("versionName") ?? "0.0.0",
      "buildNumber": prefs.getInt("buildNumber") ?? 0,
    };
  }

  Future<void> saveLocalVersion(String version, int build) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("versionName", version);
    await prefs.setInt("buildNumber", build);
  }

  // ================= CHECK =================
  Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      final res = await http.get(Uri.parse(api));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);

      final assets = data["assets"];
      if (assets == null || assets.isEmpty) return null;

      final apk = (assets as List).firstWhere(
            (e) => e["name"].toString().endsWith(".apk"),
        orElse: () => null,
      );

      if (apk == null) return null;

      final parsed = _parseTag(data["tag_name"]);

      return {
        "tag": data["tag_name"],
        "versionName": parsed["versionName"],
        "buildNumber": parsed["buildNumber"],
        "url": apk["browser_download_url"],
      };
    } catch (e) {
      debugPrint("OTA error: $e");
      return null;
    }
  }

  // ================= COMPARE VERSION =================
  bool _isNewer(Map remote, Map local) {
    final remoteBuild = remote["buildNumber"];
    final localBuild = local["buildNumber"];

    return remoteBuild > localBuild;
  }

  // ================= DOWNLOAD =================
  Future<String?> downloadApk(
      String url, {
        Function(double progress)? onProgress,
      }) async {
    try {
      final dir = await getExternalStorageDirectory();
      final path = "${dir!.path}/update.apk";

      await Dio().download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      return path;
    } catch (e) {
      debugPrint("Download error: $e");
      return null;
    }
  }

  // ================= INSTALL =================
  Future<void> installApk(String path) async {
    await OpenFile.open(path);
  }

  // ================= MAIN FLOW =================
  Future<void> checkAndUpdate(BuildContext context) async {
    final remote = await checkUpdate();
    if (remote == null) return;

    final local = await getLocalVersion();

    if (!_isNewer(remote, local)) return;

    _showUpdateDialog(context, remote);
  }

  // ================= UI =================
  void _showUpdateDialog(BuildContext context, Map data) {
    double progress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text("Cập nhật mới"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Version: ${data["versionName"]}"),
                  const SizedBox(height: 10),
                  if (progress > 0)
                    LinearProgressIndicator(value: progress),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Bỏ qua"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final path = await downloadApk(
                      data["url"],
                      onProgress: (p) {
                        setState(() => progress = p);
                      },
                    );

                    if (path != null) {
                      await installApk(path);

                      await saveLocalVersion(
                        data["versionName"],
                        data["buildNumber"],
                      );
                    }
                  },
                  child: const Text("Cập nhật"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}