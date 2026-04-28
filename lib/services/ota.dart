import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
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

  /// Lấy version hiện tại của ứng dụng
  Future<Map<String, dynamic>> getLocalVersion() async {
    final info = await PackageInfo.fromPlatform();
    return {
      "versionName": info.version,
      "buildNumber": int.tryParse(info.buildNumber) ?? 0,
    };
  }

  /// Parse tag từ GitHub (Ví dụ: v1.0.0+1 -> versionName: 1.0.0, buildNumber: 1)
  Map<String, dynamic> _parseTag(String tag) {
    final clean = tag.replaceFirst('v', '');
    final parts = clean.split('+');
    return {
      "versionName": parts[0],
      "buildNumber": parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    };
  }

  /// Xóa file APK cũ nếu tồn tại để tránh xung đột
  Future<void> cleanUpOldApk() async {
    try {
      final dir = await getExternalStorageDirectory();
      final file = File("${dir!.path}/update.apk");
      if (await file.exists()) {
        await file.delete();
        debugPrint("Đã dọn dẹp APK cũ thành công");
      }
    } catch (e) {
      debugPrint("Lỗi dọn dẹp: $e");
    }
  }

  /// Kiểm tra update và tự động lọc đúng bản Split APK theo CPU
  Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      final res = await http.get(Uri.parse(api));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final assets = data["assets"] as List;

      // 1. Lấy danh sách CPU máy hỗ trợ (Ví dụ: [arm64-v8a, armeabi-v7a])
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final supportedAbis = androidInfo.supportedAbis;

      // 2. Tìm APK phù hợp nhất dựa trên kiến trúc CPU
      dynamic selectedApk;
      for (var abi in supportedAbis) {
        selectedApk = assets.firstWhere(
              (e) => e["name"].toString().contains(abi) && e["name"].toString().endsWith(".apk"),
          orElse: () => null,
        );
        if (selectedApk != null) break;
      }

      // 3. Fallback: Nếu không tìm thấy bản split, lấy đại file APK đầu tiên (Fat APK)
      selectedApk ??= assets.firstWhere(
            (e) => e["name"].toString().endsWith(".apk"),
        orElse: () => null,
      );

      if (selectedApk == null) return null;

      final parsed = _parseTag(data["tag_name"]);

      return {
        "versionName": parsed["versionName"],
        "buildNumber": parsed["buildNumber"],
        "url": selectedApk["browser_download_url"],
        "fileName": selectedApk["name"], // Để log xem tải bản nào
      };
    } catch (e) {
      debugPrint("Check update error: $e");
      return null;
    }
  }

  /// So sánh version
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

  /// Hàm chính để gọi từ UI
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

  void _showNoUpdateDialog(BuildContext context, Map local) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thông báo"),
        content: Text("Ứng dụng đã ở phiên bản mới nhất (${local["versionName"]})"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
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
              title: const Text("Cập nhật phần mềm"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bản mới: ${remote["versionName"]}+${remote["buildNumber"]}"),
                  Text("Tệp: ${remote["fileName"]}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (downloading) ...[
                    const SizedBox(height: 15),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 5),
                    Text("${(progress * 100).toStringAsFixed(0)}%"),
                  ],
                  if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
                ],
              ),
              actions: [
                if (!downloading)
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Để sau")),
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
                  child: Text(downloading ? "Đang tải..." : "Cập nhật ngay"),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _startDownload(
      BuildContext context,
      String url,
      Function(double) onProgress,
      Function() onStart,
      Function() onDone,
      Function(String) onError,
      ) async {
    try {
      // Yêu cầu quyền cài đặt trước khi tải
      var status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        onError("Bạn cần cấp quyền cài đặt ứng dụng");
        return;
      }

      onStart();
      final dir = await getExternalStorageDirectory();
      final path = "${dir!.path}/update.apk";

      final file = File(path);
      if (await file.exists()) await file.delete();

      final dio = Dio();
      await dio.download(
        url,
        path,
        onReceiveProgress: (r, t) {
          if (t != -1) onProgress(r / t);
        },
      );

      onDone();
      await OpenFile.open(path);
    } catch (e) {
      onDone();
      onError("Lỗi: $e");
    }
  }
}