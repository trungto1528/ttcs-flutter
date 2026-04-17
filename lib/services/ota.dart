import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:ota_update/ota_update.dart';
import 'package:permission_handler/permission_handler.dart';

class OtaService {
  final String api =
      "https://api.github.com/repos/trungto1528/ttcs-flutter/releases/latest";

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
      if (assets.isEmpty) return null;

      final apk = assets.firstWhere(
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
      debugPrint("Check update error: $e");
      return null;
    }
  }

  bool _isNewer(Map remote, Map local) {
    try {
      final remoteV = Version.parse(remote["versionName"]);
      final localV = Version.parse(local["versionName"]);
      if (remoteV > localV) return true;
      if (remoteV == localV) return remote["buildNumber"] > local["buildNumber"];
      return false;
    } catch (_) {
      return remote["buildNumber"] > local["buildNumber"];
    }
  }

  // Luồng chính xử lý UI
  Future<void> checkAndUpdate(BuildContext context) async {
    // Hiện loading trong khi check (tùy chọn)
    // showLoading(context);

    final remote = await checkUpdate();
    final local = await getLocalVersion();

    if (!context.mounted) return;

    if (remote == null || !_isNewer(remote, local)) {
      // HIỂN THỊ KHI ĐÃ LÀ BẢN MỚI NHẤT
      _showNoUpdateDialog(context, local);
      return;
    }

    // HIỂN THỊ KHI CÓ BẢN CẬP NHẬT MỚI
    _showUpdateAvailableDialog(context, remote, local);
  }

  // Dialog thông báo khi app đã là bản mới nhất
  void _showNoUpdateDialog(BuildContext context, Map local) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Tuyệt vời!"),
          ],
        ),
        content: Text(
          "Ứng dụng của bạn đã ở phiên bản mới nhất: ${local["versionName"]} (${local["buildNumber"]})",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  // Dialog thông báo khi có bản cập nhật mới (có tiến trình tải)
  void _showUpdateAvailableDialog(BuildContext context, Map remote, Map local) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        double progress = 0;
        bool isDownloading = false;
        String error = "";

        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("Có bản cập nhật mới!"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Phiên bản hiện tại: ${local["versionName"]} (${local["buildNumber"]})"),
                  Text(
                    "Phiên bản mới: ${remote["versionName"]} (${remote["buildNumber"]})",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  if (isDownloading) ...[
                    const SizedBox(height: 20),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 10),
                    Center(child: Text("${(progress * 100).toStringAsFixed(0)}%")),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ]
                ],
              ),
              actions: [
                if (!isDownloading)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Để sau"),
                  ),
                ElevatedButton(
                  onPressed: isDownloading
                      ? null
                      : () async {
                    var status = await Permission.requestInstallPackages.request();
                    if (status.isGranted) {
                      setState(() {
                        isDownloading = true;
                        error = "";
                      });

                      OtaUpdate().execute(remote["url"], destinationFilename: 'update.apk').listen(
                            (event) {
                          if (event.status == OtaStatus.DOWNLOADING) {
                            double p = double.tryParse(event.value ?? "0") ?? 0;
                            setState(() => progress = p / 100);
                          } else if (event.status.index > 3) {
                            setState(() {
                              isDownloading = false;
                              error = "Lỗi: ${event.status.name}";
                            });
                          }
                        },
                        onError: (e) => setState(() {
                          isDownloading = false;
                          error = "Lỗi tải xuống";
                        }),
                      );
                    } else {
                      setState(() => error = "Vui lòng cấp quyền để cài đặt.");
                    }
                  },
                  child: Text(isDownloading ? "Đang tải..." : "Cập nhật ngay"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}