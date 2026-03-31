import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/chapter_fetcher.dart';
import '../services/story_fetcher.dart';

class ChapterReaderScreen extends StatefulWidget {
  final int chapterId;
  final int storyId;

  const ChapterReaderScreen({
    super.key,
    required this.chapterId,
    required this.storyId,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  Map<String, dynamic>? chapter;
  List blocks = [];
  List chapters = [];
  int? currentChapterId;
  late int lastChapterNumber;
  int? nextId;
  int? prevId;
  late String lastStoryTitle;
  late final coverUrl;
  late int index;

  bool loading = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final baseUrl = "http://140.245.45.167:7777/api";
  final illusUrl = "http://140.245.45.167:7778/";
  final baseCoverUrl = 'http://140.245.45.167:7778/cover/';

  @override
  void initState() {
    super.initState();
    currentChapterId = widget.chapterId;
    initData();
  }
  Future<void> initData() async {
    final storyData = await StoryFetcher().fetchStory(widget.storyId);

    chapters = storyData["chapters"];
    lastStoryTitle = storyData['title'];
    coverUrl = storyData['coverUrl'];

    await fetchChapter(currentChapterId!);
  }

  Future<void> fetchChapter(int id) async {
    setState(() => loading = true);

    try {
      final data = await ChapterFetcher().fetchChapter(id);

      currentChapterId = id;

      updateNextPrev();

      setState(() {
        chapter = data;
        blocks = data["blocks"];
        lastChapterNumber = data['chapterNumber'];
        loading = false;
      });

      saveLastRead(id);
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void updateNextPrev() {
    index = chapters.indexWhere((c) => c["id"] == currentChapterId);

    if (index == -1) {
      nextId = null;
      prevId = null;
      return;
    }

    prevId = index > 0 ? chapters[index - 1]["id"] : null;
    nextId = index < chapters.length - 1 ? chapters[index + 1]["id"] : null;

    print('prevId: $prevId current: $currentChapterId next: $nextId');
  }

  Future<void> saveLastRead(int chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastStoryId", widget.storyId);
    await prefs.setInt("lastChapterId", chapterId);
    await prefs.setString('lastStoryTitle', lastStoryTitle);
    await prefs.setInt('lastChapterNumber', lastChapterNumber);
  }

  void goNext() {
    if (nextId != null) {
      fetchChapter(nextId!);
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

  void goPrev() {
    if (prevId != null) {
      fetchChapter(prevId!);
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
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                    borderRadius: BorderRadius.circular(5),
                    child: CachedNetworkImage(
                      imageUrl: '$baseCoverUrl$coverUrl',
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
                          lastStoryTitle,
                          style: TextStyle(fontSize: 16),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            ...chapters.map((c) {
              final isCurrent = c["id"] == currentChapterId;

              return ListTile(
                title: Text("Chương ${c["chapterNumber"]}:\n ${c['title']}"),
                selected: isCurrent,
                onTap: () {
                  Navigator.pop(context);
                  fetchChapter(c["id"]);
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
          "Chương ${chapter!['chapterNumber']}: ${chapter!["title"]}",
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...blocks.map((b) => buildBlock(b)),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.black87,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: goPrev,
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
              onPressed: goNext,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
