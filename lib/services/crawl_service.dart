import 'dart:convert';
import 'package:http/http.dart' as http;

class CrawlService {
  static const String baseUrl = "http://140.245.45.167:7777/api/crawler";

  Future<Map<String, dynamic>> crawlStory(String url) async {
    final res = await http.post(
      Uri.parse("$baseUrl/story-info"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"url": url}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Crawl failed: ${res.body}");
  }

  // Gửi lệnh cào và nhận về taskId
  Future<Map<String, dynamic>> importStory(Map<String, dynamic> data, int userId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/import-selected"),
      headers: {
        "Content-Type": "application/json",
        "userId": userId.toString(),
      },
      body: jsonEncode(data),
    );

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Import failed: ${res.body}");
  }

  // Lấy danh sách tất cả tiến độ
  Future<Map<String, dynamic>> getAllTasks() async {
    final res = await http.get(Uri.parse("$baseUrl/tasks"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to get tasks");
  }

  // Hủy một task theo taskId
  Future<void> cancelTask(String taskId) async {
    final res = await http.post(Uri.parse("$baseUrl/cancel/$taskId"));
    if (res.statusCode != 200) throw Exception("Cancel failed");
  }
}