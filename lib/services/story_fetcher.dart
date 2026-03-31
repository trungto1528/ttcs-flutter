import 'dart:convert';

import 'package:flutter/cupertino.dart';
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
}
