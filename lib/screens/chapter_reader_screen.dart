import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChapterReaderScreen extends StatefulWidget {
  final List chapters;
  final int currentIndex;
  final String storyTitle;

  const ChapterReaderScreen({
    super.key,
    required this.chapters,
    required this.currentIndex,
    required this.storyTitle
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  late int index;
  Map<String, dynamic>? chapter;
  List blocks = [];
  bool loading = true;

  final baseUrl = "http://140.245.45.167:7777/api";

  @override
  void initState() {
    super.initState();
    index = widget.currentIndex;
    fetchChapter(widget.chapters[index]["id"]);
  }

  Future<void> fetchChapter(int id) async {
    setState(() => loading = true);

    try {
      final res = await http.get(Uri.parse("$baseUrl/chapters/$id"));
      final data = jsonDecode(res.body);

      setState(() {
        chapter = data;
        blocks = data["blocks"];
        loading = false;
      });

      saveLastRead(widget.storyTitle,widget.chapters[index]["chapterNumber"], index);
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> saveLastRead(String storyTitle,int chapterNumber, int chapterIndex) async {
    final prefs = await SharedPreferences.getInstance();
    String chapterString = jsonEncode(widget.chapters);
    await prefs.setString('storyList', chapterString);
    await prefs.setString('lastStoryTitle', storyTitle);
    await prefs.setInt('lastChapterNumber', chapterNumber);
    await prefs.setInt('lastChapterIndex', chapterIndex);
  }

  void goNext() {
    if (index < widget.chapters.length - 1) {
      setState(() => index++);
      fetchChapter(widget.chapters[index]["id"]);
    }
  }

  void goPrev() {
    if (index > 0) {
      setState(() => index--);
      fetchChapter(widget.chapters[index]["id"]);
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
        child: Image.network(
          block["data"],
          errorBuilder: (_, __, ___) =>
          const Text("Image failed to load"),
        ),
      );
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(chapter?["title"] ?? ""),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      //  CONTENT
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          ...blocks.map((b) => buildBlock(b)).toList(),
        ],
      ),

      //  NAVIGATION BAR
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
              onPressed: goNext,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}