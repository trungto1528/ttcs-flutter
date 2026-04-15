import 'package:flutter/material.dart';
import 'package:novel_app/screens/story_detail_screen.dart';
import 'package:novel_app/services/chapter_fetcher.dart';

class MyStoriesScreen extends StatefulWidget {
  final int userId;

  const MyStoriesScreen({super.key, required this.userId});

  @override
  State<MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<MyStoriesScreen> {
  List stories = [];
  bool isLoading = true;

  final baseCoverUrl = "http://140.245.45.167:7778/cover/";

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case "APPROVED":
        return Colors.green;
      case "PENDING":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Map<int, List<dynamic>> groupByStory(List data) {
    final Map<int, List<dynamic>> grouped = {};

    for (var item in data) {
      final storyId = item['storyId'];

      if (!grouped.containsKey(storyId)) {
        grouped[storyId] = [];
      }

      grouped[storyId]!.add(item);
    }

    return grouped;
  }

  Future<void> _loadStories() async {
    try {
      final data = await ChapterFetcher().getMyChapter(widget.userId);
      setState(() {
        stories = data;
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (stories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Truyện của tôi"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(child: Text("Chưa có truyện nào")),
      );
    }

    final grouped = groupByStory(stories);
    final storyIds = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Truyện của tôi"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: storyIds.length,
        itemBuilder: (context, index) {
          final storyId = storyIds[index];
          final chapters = grouped[storyId]!;

          final storyTitle = chapters.first['storyTitle'];
          final coverUrl = chapters.first['storyCoverUrl'];

          // sort chapter
          chapters.sort(
            (a, b) => a['chapterNumber'].compareTo(b['chapterNumber']),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER STORY
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryDetailScreen(storyId: storyId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          baseCoverUrl + (coverUrl ?? ""),
                          width: 70,
                          height: 105,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.book, size: 70),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storyTitle ?? "Không có tên",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      chapters.first['storyStatus'] ??
                                          chapters.first['status'],
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (chapters.first['storyStatus'] ??
                                            chapters.first['status'] ??
                                            "UNKNOWN")
                                        .toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _getStatusColor(
                                        chapters.first['storyStatus'] ??
                                            chapters.first['status'],
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              //  LIST CHAPTER
              ...chapters.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(left: 90, bottom: 4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StoryDetailScreen(storyId: c['storyId']),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Chap ${c['chapterNumber']}: ${c['title']}",
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              c['status'],
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (c['status'] ?? "UNKNOWN").toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getStatusColor(c['status']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}
