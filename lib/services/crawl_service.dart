import 'dart:convert';
import 'package:http/http.dart' as http;

class CrawlService {
  static const String baseUrl =
      "http://140.245.45.167:7777/api/crawler/story-info";

  Future<Map<String, dynamic>> crawlStory(String url) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({"url": url}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Crawl failed: ${res.statusCode} ${res.body}");
    }
  }
  Future<void> importStory(
      Map<String, dynamic> data,
      int userId,
      ) async {
    final res = await http.post(
      Uri.parse("http://140.245.45.167:7777/api/crawler/import-selected"),
      headers: {
        "Content-Type": "application/json",
        "userId": userId.toString(),
      },
      body: jsonEncode(data),
    );
    print(res.statusCode);

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }
}