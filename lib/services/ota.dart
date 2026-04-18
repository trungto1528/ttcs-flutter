import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pub_semver/pub_semver.dart';

class OtaService {
  final String api =
      "https://api.github.com/repos/trungto1528/ttcs-flutter/releases/latest";

  /// ================== VERSION ==================
  Future<Map<String, dynamic>> getLocalVersion() async {
    final info = await PackageInfo.fromPlatform();
    return {
      "versionName": info.version,
      "buildNumber": int.tryParse(info.buildNumber) ?? 0,
    };
  }

  Map<String, dynamic> _parseTag(String tag) {
    final clean = tag.replaceFirst('v', '');
    final parts = clean.split('+');
    return {
      "versionName": parts[0],
      "buildNumber": parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    };
  }

  Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      final res = await http.get(Uri.parse(api));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final assets = data["assets"] as List;

      final apk = assets.firstWhere(
        (e) => e["name"].toString().endsWith(".apk"),
        orElse: () => null,
      );

      if (apk == null) return null;

      final parsed = _parseTag(data["tag_name"]);

      return {
        "versionName": parsed["versionName"],
        "buildNumber": parsed["buildNumber"],
        "url": apk["browser_download_url"],
      };
    } catch (e) {
      debugPrint("Check update error: $e");
      return null;
    }
  }

  bool _isNewer(Map remote, Map local) {
    try {
      final r = Version.parse(remote["versionName"]);
      final l = Version.parse(local["versionName"]);

      if (r > l) return true;
      if (r == l) return remote["buildNumber"] > local["buildNumber"];
      return false;
    } catch (_) {
      return remote["buildNumber"] > local["buildNumber"];
    }
  }

  /// ================== MAIN ==================
  Future<void> checkAndUpdate(BuildContext context) async {
    final remote = await checkUpdate();
    final local = await getLocalVersion();

    if (!context.mounted) return;

    if (remote == null || !_isNewer(remote, local)) {
      _showNoUpdateDialog(context, local);
      return;
    }

    _showUpdateDialog(context, remote, local);
  }

  /// ================== UI ==================
  void _showNoUpdateDialog(BuildContext context, Map local) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Đã mới nhất"),
          ],
        ),
        content: Text(
          "Phiên bản hiện tại: ${local["versionName"]} (${local["buildNumber"]})",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, Map remote, Map local) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        double progress = 0;
        bool downloading = false;
        String error = "";

        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Có bản cập nhật mới"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hiện tại: ${local["versionName"]} (${local["buildNumber"]})"),
                  Text(
                    "Mới: ${remote["versionName"]} (${remote["buildNumber"]})",
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  if (downloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Center(
                        child: Text("${(progress * 100).toStringAsFixed(0)}%")),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(error, style: const TextStyle(color: Colors.red)),
                  ]
                ],
              ),
              actions: [
                if (!downloading)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Để sau"),
                  ),
                ElevatedButton(
                  onPressed: downloading
                      ? null
                      : () async {
                          await _startDownload(
                            ctx,
                            remote["url"],
                            (p) => setState(() => progress = p),
                            () => setState(() => downloading = true),
                            () => setState(() => downloading = false),
                            (e) => setState(() => error = e),
                          );
                        },
                  child: Text(downloading ? "Đang tải..." : "Cập nhật"),
                )
              ],
            );
          },
        );
      },
    );
  }

  /// ================== DOWNLOAD + INSTALL ==================
  Future<void> _startDownload(
    BuildContext context,
    String url,
    Function(double) onProgress,
    Function() onStart,
    Function() onDone,
    Function(String) onError,
  ) async {
    try {
      var status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        onError("Chưa cấp quyền cài đặt");
        return;
      }

      onStart();

      final dir = await getExternalStorageDirectory();
      final path = "${dir!.path}/update.apk";

      final file = File(path);

      // Nếu file đã tồn tại -> mở luôn (resume install)
      if (await file.exists()) {
        await OpenFile.open(path);
        onDone();
        return;
      }

      final dio = Dio();

      await dio.download(
        url,
        path,
        onReceiveProgress: (r, t) {
          if (t != -1) onProgress(r / t);
        },
      );

      onDone();

      // mở installer
      await OpenFile.open(path);
    } catch (e) {
      onDone();
      onError("Lỗi: $e");
    }
  }
}
