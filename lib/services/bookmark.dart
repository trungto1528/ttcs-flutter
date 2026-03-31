import 'dart:convert';
import 'package:http/http.dart' as http;

class Bookmark {
  final baseUrl='http://140.245.45.167:7777/api/bookmarks';
  Future<void> saveStory(int userId, int storyId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/save'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "storyId": storyId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Lưu truyện thất bại");
    }
  }
  Future<void> unsaveStory(int userId, int storyId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/unsave'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "storyId": storyId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Bỏ lưu thất bại");
    }
  }
  Future<bool> isSavedApi(int userId, int storyId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/check?userId=$userId&storyId=$storyId'),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Check bookmark thất bại");
    }
  }
  Future<List> getBookmark(int userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/user/$userId'),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Lấy danh sách bookmark thất bại");
    }
  }
}