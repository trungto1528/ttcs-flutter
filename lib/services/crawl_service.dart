import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class CrawlService {
  String get baseUrl =>
      ApiConfig.crawlerUrl;

  Future<Map<String, dynamic>> crawlStory(
      String url) async {
    final res = await http.post(
      Uri.parse("$baseUrl/story-info"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "url": url,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception(
      "Crawl failed: ${res.body}",
    );
  }

  Future<List<Map<String, dynamic>>> searchStories(
      String keyword) async {
    final uri =
    Uri.parse("$baseUrl/search").replace(
      queryParameters: {
        "keyword": keyword.trim(),
      },
    );

    final res =
    await http.get(uri);

    if (res.statusCode == 200) {
      final decoded =
      jsonDecode(res.body);

      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>(
              (item) =>
          Map<String, dynamic>.from(
            item,
          ),
        )
            .toList();
      }

      throw Exception(
        "Dữ liệu tìm kiếm không hợp lệ",
      );
    }

    throw Exception(
      "Search failed: ${res.body}",
    );
  }

  Future<Map<String, dynamic>> importStory(
      Map<String, dynamic> data,
      int userId,
      ) async {
    final res = await http.post(
      Uri.parse(
        "$baseUrl/import-selected",
      ),
      headers: {
        "Content-Type":
        "application/json",
        "userId":
        userId.toString(),
      },
      body: jsonEncode(data),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception(
      "Import failed: ${res.body}",
    );
  }

  Future<Map<String, dynamic>>
  getAllTasks() async {
    final res = await http.get(
      Uri.parse("$baseUrl/tasks"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception(
      "Failed to get tasks",
    );
  }

  Future<void> cancelTask(
      String taskId) async {
    final res = await http.post(
      Uri.parse(
        "$baseUrl/cancel/$taskId",
      ),
    );

    if (res.statusCode != 200) {
      throw Exception(
        "Cancel failed",
      );
    }
  }
}