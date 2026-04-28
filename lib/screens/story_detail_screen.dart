import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:novel_app/screens/chapter_reader_screen.dart';
import 'package:novel_app/services/bookmark.dart';
import 'package:novel_app/services/story_fetcher.dart';
import 'package:novel_app/widget/expand_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/User.dart';
import 'login_screen.dart';

class StoryDetailScreen extends StatefulWidget {
  final int storyId;

  const StoryDetailScreen({super.key, required this.storyId});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  late Map<String, dynamic> story;

  User? user;

  bool storyLoading = true;
  bool bookmarkLoading = false;
  bool isSaved = false;

  List chapters = [];

  final baseCoverUrl = 'http://140.245.45.167:7778/cover/';

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await _loadUser();
    await _loadStory();
    await _loadSaved();
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Yêu cầu đăng nhập"),
        content: const Text("Bạn cần đăng nhập để lưu truyện"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final loginResult = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
              if (loginResult == true) {
                await _loadUser();
                await _loadSaved();
              }
            },
            child: const Text("Đăng nhập"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString("user");

    if (userStr == null) {
      setState(() => user = null);
      return;
    }

    try {
      final json = jsonDecode(userStr);
      setState(() {
        user = User.fromJson(json);
      });
    } catch (_) {
      setState(() => user = null);
    }
  }

  Future<void> _loadSaved() async {
    if (user == null) {
      setState(() => isSaved = false);
      return;
    }

    final result = await Bookmark().isSavedApi(user!.id, widget.storyId);

    setState(() {
      isSaved = result;
      bookmarkLoading = false;
    });
  }

  Future<void> _loadStory() async {
    try {
      final data = await StoryFetcher().fetchStory(widget.storyId);

      setState(() {
        story = data;
        chapters = data["chapters"] ?? [];
        storyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lỗi tải truyện")));
    }
  }

  /// ================= GROUP CHAPTER =================
  Map<int, List<dynamic>> get groupedChapters {
    final Map<int, List<dynamic>> map = {};

    for (var c in chapters) {
      final key = c["chapterNumber"] ?? 0;
      map.putIfAbsent(key, () => []);
      map[key]!.add(c);
    }

    final sortedKeys = map.keys.toList()..sort();
    return {for (var k in sortedKeys) k: map[k]!};
  }

  @override
  Widget build(BuildContext context) {
    if (storyLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(story["title"] ?? ""),
        actions: [
          IconButton(
            icon: bookmarkLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: isSaved ? Colors.red : null,
                  ),
            onPressed: bookmarkLoading
                ? null
                : () async {
                    if (user == null) {
                      _showLoginRequiredDialog();
                      return;
                    }

                    setState(() => bookmarkLoading = true);

                    if (isSaved) {
                      await Bookmark().unsaveStory(user!.id, widget.storyId);
                    } else {
                      await Bookmark().saveStory(user!.id, widget.storyId);
                    }

                    setState(() {
                      isSaved = !isSaved;
                      bookmarkLoading = false;
                    });
                  },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: init,
        child: ListView(
          children: [
            const Divider(),

            // ================= STORY HEADER =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: baseCoverUrl + (story['coverUrl'] ?? ""),
                      height: 180,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story['title'] ?? "",
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 6),
                        Text("Tác giả: ${story['author'] ?? ""}"),
                        Text("Tạo bởi: ${story['createdByName'] ?? ""}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================= DESCRIPTION =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: ExpandableText(text: story['description'] ?? ""),
            ),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Danh sách chương",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // ================= GROUPED CHAPTER LIST =================
            ...groupedChapters.entries.map((entry) {
              final chapterNumber = entry.key;
              final list = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      "Ch. $chapterNumber",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // Danh sách các bản dịch/nguồn của chương đó
                  ...list.map((c) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12), // Bo góc
                        border: Border.all(color: Colors.grey.shade200), // Viền nhạt
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: const Icon(Icons.menu_book_rounded, color: Colors.blue), // Icon đại diện
                        title: Text(
                          c["title"] ?? "Không có tiêu đề",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "Người đăng: ${c["createdByName"]} ",
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChapterReaderScreen(
                                chapterId: c["id"],
                                storyId: widget.storyId,
                                createdById: c["createdById"],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
