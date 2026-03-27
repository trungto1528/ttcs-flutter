import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:novel_app/screens/chapter_reader_screen.dart';

class StoryDetailScreen extends StatefulWidget {
  final int storyId;

  const StoryDetailScreen({super.key, required this.storyId});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  Map? story;
  bool loading = true;

  final baseUrl = "http://140.245.45.167:7777/api";

  @override
  void initState() {
    super.initState();
    fetchStory();
  }

  Future<void> fetchStory() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/stories/${widget.storyId}"));

      setState(() {
        story = jsonDecode(res.body);
        loading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final chapters = story!["chapters"] as List;

    return Scaffold(
      appBar: AppBar(
        title: Text(story!["title"]),
      ),
      body: ListView(
        children: [
          Image.network(
            story!["coverUrl"] ?? "https://placehold.co/800/png",
            height: 200,
            fit: BoxFit.cover,
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story!["title"],
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Tác giả: ${story!["author"] ?? "Unknown"}"),
                const SizedBox(height: 8),
                Text(story!["description"] ?? ""),
              ],
            ),
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Danh sách chương",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: chapters.length,
        itemBuilder: (context, i) {
          final c = chapters[i];

          final prevId = (i > 0) ? chapters[i - 1]["id"] : -1;
          final nextId =
          (i < chapters.length - 1) ? chapters[i + 1]["id"] : -1;

          return ListTile(
            title: Text("Chương ${c["chapterNumber"]}: ${c["title"]}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChapterReaderScreen(
                    chapters: chapters,
                    currentIndex: i,
                    storyTitle:story!["title"]
                  ),
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