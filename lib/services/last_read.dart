import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class LastRead {
  Future<void> updateLastRead(int userId, int storyId, int chapterId,int createdById) async {
    final url = Uri.parse("http://${ApiConfig.api}/users/$userId/last-read"
        "?storyId=$storyId&chapterId=$chapterId&createdById=$createdById");
    final res = await http.post(url);
    if (res.statusCode != 200) {
      throw Exception("Cập nhật đọc tiếp thất bại");
    }
  }
}