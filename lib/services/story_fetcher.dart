import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class StoryFetcher {
  final String baseUrl = 'http://140.245.45.167:7777/api';

  // ================= FETCH USER =================
  Future<Map<String, dynamic>> fetchStory(int storyId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/stories/fetch/$storyId"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Failed to fetch story");
  }

  // ================= FETCH ADMIN (có chapters) =================
  Future<Map<String, dynamic>?> fetchStoryAdmin(
      int storyId, int adminId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/stories/$storyId/admin"),
      headers: {"userId": adminId.toString()},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // ================= GET ALL (ADMIN) =================
  Future<List> getAllStories(int adminId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/stories/all"),
      headers: {"userId": adminId.toString()},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Failed to load stories");
  }

  // ================= SEARCH =================
  Future<List> search(String keyword) async {
    final res = await http.get(
      Uri.parse("$baseUrl/stories/search?keyword=$keyword"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Search failed");
  }

  // ================= SEARCH LITTLE =================
  Future<Map<String, dynamic>> searchLittle(int storyId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/stories/little?storyId=$storyId"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) {
        return data[0];
      }
    }
    throw Exception("No story found");
  }

  // ================= CREATE =================
  Future<Map<String, dynamic>?> createStory({
    required String title,
    required String description,
    required String author,
    required String coverUrl,
    required int userId,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/stories"),
      headers: {
        "Content-Type": "application/json",
        "userId": userId.toString(),
      },
      body: jsonEncode({
        "title": title,
        "description": description,
        "author": author,
        "coverUrl": coverUrl,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // ================= APPROVE =================
  Future<void> approveStory(int adminId, int storyId) async {
    final res = await http.put(
      Uri.parse("$baseUrl/stories/$storyId/approve"),
      headers: {"userId": adminId.toString()},
    );

    if (res.statusCode != 200) {
      throw Exception("Approve failed");
    }
  }

  // ================= REJECT =================
  Future<void> rejectStory(int adminId, int storyId) async {
    final res = await http.put(
      Uri.parse("$baseUrl/stories/$storyId/reject"),
      headers: {"userId": adminId.toString()},
    );

    if (res.statusCode != 200) {
      throw Exception("Reject failed");
    }
  }

  // ================= DELETE =================
  Future<void> deleteStory(int storyId, int userId) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/stories/$storyId"),
      headers: {"userId": userId.toString()},
    );

    if (res.statusCode != 200) {
      throw Exception("Delete failed");
    }
  }

  // ================= UPLOAD COVER =================
  Future<String?> uploadCover(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/stories/upload-cover"),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
      ));

      var response = await request.send();
      var resStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return resStr;
      }
    } catch (e) {
      print("Upload cover error: $e");
    }
    return null;
  }
}