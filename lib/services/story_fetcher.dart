import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class StoryFetcher {
  final baseUrl = 'http://140.245.45.167:7777/api';

  Future<Map<String, dynamic>> fetchStory(int storyId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/stories/fetch/$storyId"));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Failed to fetch story");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> searchLittle(int storyId) async {
    try {
      final res = await http.get(
        Uri.parse("http://140.245.45.167:7777/api/stories/little?storyId=$storyId"),
      );
      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) {
        return data[0];
      } else {
        throw Exception("No story found");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List> search(String keyword) async {
    try {
      final res = await http.get(
        Uri.parse(
          "http://140.245.45.167:7777/api/stories/search?keyword=$keyword",
        ),
      );
      return jsonDecode(res.body);
    } catch (e) {
      rethrow;
    }
  }
  Future approveStory(int adminId, int storyId) async {
    await http.put(
      Uri.parse("$baseUrl/stories/$storyId/approve"),
      headers: {"userId": adminId.toString()},
    );
  }

  Future<String?> uploadCover(File file, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/stories/upload-cover"),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
      ));

      var response = await request.send();

      print("STATUS: ${response.statusCode}");
      var resStr = await response.stream.bytesToString();
      print("BODY: $resStr");

      if (response.statusCode == 200) {
        return resStr;
      }
    } catch (e) {
      print("Upload cover error: $e");
    }
    return null;
  }
  Future<List> getAllStories(int adminId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/stories/all"),
      headers: {"userId": adminId.toString()},
    );

    return jsonDecode(res.body);
  }


  Future<Map<String, dynamic>?> createStory({
    required String title,
    required String description,
    required String author,
    required String coverUrl,
    required int userId,
  }) async {
    try {
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
    } catch (e) {
      return null;
    }
  }
}
