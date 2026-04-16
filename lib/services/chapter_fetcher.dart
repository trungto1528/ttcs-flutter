import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ChapterFetcher {
  final String baseUrl = 'http://140.245.45.167:7777/api';

  Future<Map<String, dynamic>> fetchChapter(int chapterId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/chapters/$chapterId"));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Failed to fetch");
      }
    } catch (e) {
      throw Exception("Failed to fetch");
    }
  }

  Future approveChapter(int adminId, int chapterId) async {
    await http.put(
      Uri.parse("$baseUrl/chapters/$chapterId/approve"),
      headers: {"userId": adminId.toString()},
    );
  }

  Future<bool> createChapter({
    required int storyId,
    required String title,
    required List<Map<String, String>> content,
    required int chapterNumber,
    required int userId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/chapters"),
        headers: {
          "Content-Type": "application/json",
          "userId": userId.toString(),
        },
        body: jsonEncode({
          "storyId": storyId,
          "title": title,
          "blocks": content,
          "chapterNumber": chapterNumber,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadIllustration(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/illus/upload"),
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        return await response.stream.bytesToString();
      }
    } catch (e) {
      print("Upload error: $e");
    }
    return null;
  }

  Future<List> getPendingChapters() async {
    final res = await http.get(Uri.parse("$baseUrl/chapters/pending"));

    return jsonDecode(res.body);
  }
  Future<List<dynamic>> getMyChapter(int userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/chapters/my-chapters?userId=$userId"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load chapters");
    }
  }

}
