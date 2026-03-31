import 'package:http/http.dart' as http;
import 'package:novel_app/services/auth.dart';

class LastRead {
  Future<void> updateLastRead(int userId, int storyId, int chapterId) async {
    final url = Uri.parse("http://140.245.45.167:7777/api/users/$userId/last-read"
        "?storyId=$storyId&chapterId=$chapterId");
    final res = await http.post(url);
    if (res.statusCode != 200) {
      throw Exception("Cập nhật đọc tiếp thất bại");
    }
  }
}