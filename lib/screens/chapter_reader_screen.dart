import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:novel_app/screens/story_detail_screen.dart';
import 'package:novel_app/services/last_read.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/User.dart';
import '../services/chapter_fetcher.dart';
import '../services/story_fetcher.dart';

class ChapterReaderScreen extends StatefulWidget {
  final int chapterId;
  final int storyId;
  final int createdById;

  const ChapterReaderScreen({
    super.key,
    required this.chapterId,
    required this.storyId,
    required this.createdById,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  Map<String, dynamic>? chapter;
  List blocks = [];
  List chapters = [];
  late int currentChapterId;
  late int lastChapterNumber;
  int? nextId;
  int? prevId;
  late String lastStoryTitle;
  late final String coverUrl;
  late int index;
  List chaptersByUser = [];
  bool loading = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final baseUrl = "http://140.245.45.167:7777/api";
  final illusUrl = "http://140.245.45.167:7778/chapter/";
  final baseCoverUrl = 'http://140.245.45.167:7778/cover/';

  @override
  void initState() {
    super.initState();
    currentChapterId = widget.chapterId;
    _initData();
  }

  Future<void> _initData() async {
    final storyData = await StoryFetcher().fetchStory(widget.storyId);

    final raw = storyData["chapters"] as List;

    final filtered = raw.where((c) {
      return c["createdById"] == widget.createdById;
    }).toList();

    filtered.sort((a, b) =>
        (a["chapterNumber"] as int).compareTo(b["chapterNumber"] as int));

    setState(() {
      chapters = filtered;
      lastStoryTitle = storyData['title'];
      coverUrl = storyData['coverUrl'];
    });

    await _fetchChapter(currentChapterId);
  }

  Future<void> _fetchChapter(int id) async {
    setState(() => loading = true);

    try {
      final data = await ChapterFetcher().fetchChapter(id);

      currentChapterId = id;

      _updateNextPrev();

      setState(() {
        chapter = data;
        blocks = data["blocks"];
        lastChapterNumber = data['chapterNumber'];
        loading = false;
      });
      final prefs = await SharedPreferences.getInstance();
      String? userString = prefs.getString("user");
      if (userString != null) {
        final user =User.fromJson(jsonDecode(userString));
        await LastRead().updateLastRead(
          user.id,
          widget.storyId,
          currentChapterId,
          widget.createdById
        );
      } else {
        _saveLastRead(id);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void _updateNextPrev() {
    index = chapters.indexWhere((c) => c["id"] == currentChapterId);

    if (index == -1) {
      nextId = null;
      prevId = null;
      return;
    }

    prevId = index > 0 ? chapters[index - 1]["id"] : null;
    nextId = index < chapters.length - 1 ? chapters[index + 1]["id"] : null;
  }

  Future<void> _saveLastRead(int chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastStoryId", widget.storyId);
    await prefs.setInt("lastChapterId", chapterId);
    await prefs.setInt('lastReadCreatedById',widget.createdById);
  }

  void _goNext() {
    if (nextId != null) {
      _fetchChapter(nextId!);
    } else {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Thông báo"),
          content: Text("Đây là chương cuối rồi"),
        ),
      );
    }
  }

  void _goPrev() {
    if (prevId != null) {
      _fetchChapter(prevId!);
    }
  }

  Widget buildBlock(block) {
    if (block["type"] == "text") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          block["data"],
          style: const TextStyle(fontSize: 18, height: 1.5),
        ),
      );
    }

    if (block["type"] == "image") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: CachedNetworkImage(imageUrl: illusUrl + block['data']),
      );
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    if (loading || chapter == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: "$baseCoverUrl/$coverUrl",
                      width: 80,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryDetailScreen(storyId: widget.storyId),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastStoryTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text("Ch. $lastChapterNumber"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ...chapters.map((c) {
              final isCurrent = c["id"] == currentChapterId;

              return ListTile(
                title: Text("Ch. ${c["chapterNumber"]}:\n ${c['title']}"),
                selected: isCurrent,
                onTap: () {
                  Navigator.pop(context);
                  _fetchChapter(c["id"]);
                },
              );
            }),
          ],
        ),
      ),
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${chapter!["title"]}",
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [...blocks.map((b) => buildBlock(b))],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.black87,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _goPrev,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            IconButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home, color: Colors.white),
            ),
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu, color: Colors.white),
            ),
            IconButton(
              onPressed: _goNext,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
