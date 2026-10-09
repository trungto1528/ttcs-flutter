import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:novel_app/screens/story_detail_screen.dart';
import 'package:novel_app/services/last_read.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
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

  @override
  void initState() {
    super.initState();
    currentChapterId = widget.chapterId;
    _initData();
  }

  Future<void> _initData() async {
    try {
      final storyData = await StoryFetcher().fetchStory(widget.storyId);
      final raw = storyData["chapters"] as List;

      final filtered = raw.where((c) {
        return c["createdById"] == widget.createdById;
      }).toList();

      filtered.sort(
            (a, b) => (a["chapterNumber"] as int)
            .compareTo(b["chapterNumber"] as int),
      );

      if (!mounted) return;

      setState(() {
        chapters = filtered;
        lastStoryTitle = storyData['title'];
        coverUrl = storyData['coverUrl'];
      });

      await _fetchChapter(currentChapterId);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _fetchChapter(int id) async {
    setState(() => loading = true);

    try {
      final data = await ChapterFetcher().fetchChapter(id);

      currentChapterId = id;
      _updateNextPrev();

      if (!mounted) return;

      setState(() {
        chapter = data;
        blocks = data["blocks"];
        lastChapterNumber = data['chapterNumber'];
        loading = false;
      });

      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString("user");

      if (userString != null) {
        final user = User.fromJson(jsonDecode(userString));

        await LastRead().updateLastRead(
          user.id,
          widget.storyId,
          currentChapterId,
          widget.createdById,
        );
      } else {
        await _saveLastRead(id);
      }
    } catch (e) {
      if (!mounted) return;
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
    await prefs.setInt("lastReadCreatedById", widget.createdById);
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

  Widget buildBlock(dynamic block) {
    if (block["type"] == "text") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          block["data"] ?? "",
          style: const TextStyle(
            fontSize: 18,
            height: 1.5,
          ),
        ),
      );
    }

    if (block["type"] == "image") {
      final imageUrl = '${ApiConfig.chapterImage}/${block['data']}';

      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        fit: BoxFit.fitWidth,

        // Hiển thị loading riêng trong lúc ảnh được tải.
        placeholder: (context, url) {
          return const SizedBox(
            width: double.infinity,
            height: 220,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },

        // Hiển thị lỗi nếu không tải được ảnh.
        errorWidget: (context, url, error) {
          return const SizedBox(
            width: double.infinity,
            height: 120,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 36,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (loading || chapter == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
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
                      imageUrl: "${ApiConfig.coverImage}/$coverUrl",
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
                            builder: (_) => StoryDetailScreen(
                              storyId: widget.storyId,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastStoryTitle,
                            style: const TextStyle(
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final c = chapters[index];
                  final isCurrent = c["id"] == currentChapterId;

                  return Material(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.pop(context);
                        _fetchChapter(c["id"]);
                      },
                      child: Center(
                        child: Text(
                          "Ch. ${c["chapterNumber"]}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("${chapter!["title"]}"),
      ),

      // Không đặt padding cho ListView để các ảnh nối liền nhau.
      body: ListView(
        padding: EdgeInsets.zero,
        children: blocks.map((b) => buildBlock(b)).toList(),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        color: Colors.black87,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _goPrev,
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(
                Icons.home,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: _goNext,
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}