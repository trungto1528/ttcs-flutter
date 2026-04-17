import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

class OtaService {
  final String api =
      "https://api.github.com/repos/trungto1528/ttcs-flutter/releases/latest";

  // ================= GET LOCAL VERSION (REAL APP VERSION) =================
  Future<Map<String, dynamic>> getLocalVersion() async {
    final info = await PackageInfo.fromPlatform();

    return {
      "versionName": info.version,
      "buildNumber": int.tryParse(info.buildNumber) ?? 0,
    };
  }

  // ================= PARSE GITHUB TAG =================
  Map<String, dynamic> _parseTag(String tag) {
    // v1.0.2+4
    final clean = tag.replaceFirst('v', '');
    final parts = clean.split('+');

    return {
      "versionName": parts[0],
      "buildNumber": parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    };
  }

  // ================= CHECK UPDATE =================
  Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      final res = await http.get(Uri.parse(api));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);

      final assets = data["assets"];
      if (assets == null || (assets as List).isEmpty) return null;

      final apk = (assets).firstWhere(
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

  // ================= COMPARE VERSION (SMART) =================
  bool _isNewer(Map remote, Map local) {
    try {
      final remoteV = Version.parse(remote["versionName"]);
      final localV = Version.parse(local["versionName"]);

      if (remoteV > localV) return true;
      if (remoteV == localV) {
        return remote["buildNumber"] > local["buildNumber"];
      }
      return false;
    } catch (_) {
      // fallback nếu parse lỗi
      return remote["buildNumber"] > local["buildNumber"];
    }
  }

  // ================= DOWNLOAD APK =================
  Future<String?> downloadApk(
    String url, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/update.apk";

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

  // ================= INSTALL APK =================
  Future<void> installApk(String path) async {
    final result = await OpenFile.open(path);
    print("Install result: ${result.type} - ${result.message}");
  }

  // ================= MAIN FLOW =================
  Future<void> checkAndUpdate(BuildContext context) async {
    final remote = await checkUpdate();
    if (remote == null) return;

    final local = await getLocalVersion();
    _showUpdateDialog(context, remote, local);
  }

  // ================= UI =================
  void _showUpdateDialog(BuildContext context, Map remote, Map local) {
    double progress = 0;
    bool isDownloading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            if (!_isNewer(remote, local)) {
              return AlertDialog(
                title: const Text("Không có bản cập nhật mới"),
                content: Text(
                  "Version hiện tại: ${local["versionName"]} (${local["buildNumber"]})",
                ),
              );
            }
            return AlertDialog(
              title: const Text("Cập nhật mới"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Hiện tại: "),
                      Text(
                        "${local["versionName"]} (${local["buildNumber"]})",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text("Mới: "),
                      Text(
                        "${remote["versionName"]} (${remote["buildNumber"]})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (isDownloading) ...[
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text("${(progress * 100).toStringAsFixed(0)}%"),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDownloading ? null : () => Navigator.pop(ctx),
                  child: const Text("Bỏ qua"),
                ),
                ElevatedButton(
                  onPressed: isDownloading
                      ? null
                      : () async {
                          setState(() => isDownloading = true);

                          final path = await downloadApk(
                            remote["url"],
                            onProgress: (p) {
                              setState(() => progress = p);
                            },
                          );

                          if (path != null) {
                            await installApk(path);
                          }

                          Navigator.pop(ctx);
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
