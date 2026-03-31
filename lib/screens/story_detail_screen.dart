import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:novel_app/screens/chapter_reader_screen.dart';
import 'package:novel_app/widget/expand_text.dart';
import 'package:novel_app/services/story_fetcher.dart';

class StoryDetailScreen extends StatefulWidget {
  final int storyId;

  const StoryDetailScreen({super.key, required this.storyId});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  late Map<String,dynamic> story;
  bool loading = true;

  final baseUrl = "http://140.245.45.167:7777/api";
  final baseCoverUrl = 'http://140.245.45.167:7778/cover/';

  @override
  void initState() {
    super.initState();
    loadStory();
  }

  Future<void> loadStory() async {
    try {
      final data = await StoryFetcher().fetchStory(widget.storyId);

      setState(() {
        story = data;
        loading = false;
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
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chapters = story["chapters"] as List;

    return Scaffold(
      appBar: AppBar(title: Text(story!["title"])),
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
                    imageUrl: baseCoverUrl + story!['coverUrl'],
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
                        story!['title'],
                        style: TextStyle(fontSize: 24),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tác giả: ${story!['author']}',
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
            child: ExpandableText(text: story!['description']),
          ),

          // CachedNetworkImage(
          //   fit: BoxFit.cover,
          //   imageUrl: story!["coverUrl"] ?? "https://placehold.co/800/png",
          // ),
          //
          // Padding(
          //   padding: const EdgeInsets.all(16),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         story!["title"],
          //         style: const TextStyle(
          //           fontSize: 22,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //       const SizedBox(height: 8),
          //       Text("Tác giả: ${story!["author"] ?? "Unknown"}"),
          //       const SizedBox(height: 8),
          //       Text(story!["description"] ?? ""),
          //     ],
          //   ),
          // ),
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

              final prevId = (i > 0) ? chapters[i - 1]["id"] : -1;
              final nextId = (i < chapters.length - 1)
                  ? chapters[i + 1]["id"]
                  : -1;

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
