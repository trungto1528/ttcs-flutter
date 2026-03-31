import 'dart:convert';

import 'package:http/http.dart' as http;

class StoryFetcher {
  final baseUrl = 'http://140.245.45.167:7777/api';

  Future<Map<String, dynamic>> fetchStory(int storyId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/stories/$storyId"));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Failed to fetch story");
      }
    } catch (e) {
      rethrow;
    }
  }
}
