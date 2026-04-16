import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ChapterFetcher {
  final String baseUrl = 'http://140.245.45.167:7777/api';

  // ================= FETCH CHAPTER =================
  Future<Map<String, dynamic>> fetchChapter(int chapterId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/chapters/$chapterId"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Failed to fetch chapter");
  }

  // ================= CREATE =================
  Future<bool> createChapter({
    required int storyId,
    required String title,
    required List<Map<String, String>> content,
    required int chapterNumber,
    required int userId,
  }) async {
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
  }

  // ================= APPROVE =================
  Future<void> approveChapter(int adminId, int chapterId) async {
    final res = await http.put(
      Uri.parse("$baseUrl/chapters/$chapterId/approve"),
      headers: {"userId": adminId.toString()},
    );

    if (res.statusCode != 200) {
      throw Exception("Approve chapter failed");
    }
  }

  // ================= REJECT =================
  Future<void> rejectChapter(int adminId, int chapterId) async {
    final res = await http.put(
      Uri.parse("$baseUrl/chapters/$chapterId/reject"),
      headers: {"userId": adminId.toString()},
    );

    if (res.statusCode != 200) {
      throw Exception("Reject chapter failed");
    }
  }

  // ================= DELETE =================
  Future<void> deleteChapter(int chapterId, int userId) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/chapters/$chapterId"), // ✅ FIX baseUrl
      headers: {"userId": userId.toString()},
    );

    if (res.statusCode != 200) {
      throw Exception("Delete chapter failed");
    }
  }

  // ================= UPLOAD ILLUSTRATION =================
  Future<String?> uploadIllustration(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/illus/upload"),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      var response = await request.send();
      var resStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return resStr;
      }
    } catch (e) {
      print("Upload illustration error: $e");
    }
    return null;
  }

  // ================= GET PENDING =================
  Future<List<dynamic>> getPendingChapters() async {
    final res = await http.get(
      Uri.parse("$baseUrl/chapters/pending"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Failed to load pending chapters");
  }

  // ================= GET MY CHAPTER =================
  Future<List<dynamic>> getMyChapter(int userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/chapters/my-chapters?userId=$userId"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Failed to load my chapters");
  }
}