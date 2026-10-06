import 'package:http/http.dart' as http;

class LastRead {
  Future<void> updateLastRead(int userId, int storyId, int chapterId,int createdById) async {
    final url = Uri.parse("http://v2.trungto.qd.je:7777/api/users/$userId/last-read"
        "?storyId=$storyId&chapterId=$chapterId&createdById=$createdById");
    final res = await http.post(url);
    if (res.statusCode != 200) {
      throw Exception("Cập nhật đọc tiếp thất bại");
    }
  }
}