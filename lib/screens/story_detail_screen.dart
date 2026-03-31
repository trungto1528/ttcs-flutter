import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:novel_app/screens/chapter_reader_screen.dart';
import 'package:novel_app/widget/expand_text.dart';
import 'package:novel_app/services/story_fetcher.dart';
import 'package:novel_app/services/bookmark.dart';
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
  late Map<String,dynamic> story;
  User? user;
  bool storyLoading = true;
  bool bookmarkLoading = false;
  bool isSaved = false;

  final baseUrl = "http://140.245.45.167:7777/api";
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
        title: Text("Yêu cầu đăng nhập"),
        content: Text("Bạn cần đăng nhập để lưu truyện"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Đóng"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final loginResult = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(),
                ),
              );
              if (loginResult == true) {
                await _loadUser();
                await _loadSaved();
              }
            },
            child: Text("Đăng nhập"),
          ),
        ],
      ),
    );
  }
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString("user");

    if (userStr == null) {
      setState(() {
        user = null;
      });
      return;
    }

    try {
      final json = jsonDecode(userStr);

      setState(() {
        user = User.fromJson(json);
      });
    } catch (e) {
      setState(() {
        user = null;
      });
    }
  }
  Future<void> _loadSaved() async {
    if (user == null) {
      setState(() {
        isSaved = false;
      });
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
        storyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải truyện")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (storyLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chapters = story["chapters"] as List;

    return Scaffold(
      appBar: AppBar(
          actions: [
            IconButton(
              icon: bookmarkLoading
                  ? SizedBox(
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
            )
          ],
          title: Text(story["title"])),
      body: ListView(
        children: [
          const Divider(),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CachedNetworkImage(
                    imageUrl: baseCoverUrl + story['coverUrl'],
                    height: 150,
                    width: 100,
                    fit: BoxFit.fill,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'],
                        style: TextStyle(fontSize: 24),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tác giả: ${story['author']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ExpandableText(text: story['description']),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Danh sách chương",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chapters.length,
            itemBuilder: (context, i) {
              final c = chapters[i];
              return ListTile(
                title: Text("Chương ${c["chapterNumber"]}: ${c["title"]}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChapterReaderScreen(
                        chapterId: c["id"],
                        storyId: widget.storyId,
                      )
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
