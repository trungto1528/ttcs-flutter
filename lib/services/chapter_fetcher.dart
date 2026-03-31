import 'dart:convert';
import 'package:http/http.dart' as http;

class ChapterFetcher {
  final String baseUrl = 'http://140.245.45.167:7777/api';

  Future<Map<String,dynamic>> fetchChapter(int chapterId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/chapters/$chapterId"),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Failed to fetch");
      }
    } catch (e) {
      throw Exception("Failed to fetch");
    }
  }
}