import 'package:flutter/material.dart';
import 'package:novel_app/screens/story_detail_screen.dart';
import '../services/chapter_fetcher.dart';

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

  Future<void> _loadStories() async {
    try {
      final data = await ChapterFetcher().getMyChapter(widget.userId);

      setState(() {
        stories = data ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Truyện của tôi"),
          automaticallyImplyLeading: true,
          leading: Navigator.canPop(context)
              ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          )
              : null,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (stories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Truyện của tôi"),
          automaticallyImplyLeading: true,
          leading: Navigator.canPop(context)
              ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          )
              : null,
        ),
        body: const Center(child: Text("Chưa có truyện nào")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Truyện của tôi"),
        automaticallyImplyLeading: true,
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
      ),
      body: ListView.builder(
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];

          final List chapters =
              (story['chapters'] as List?)?.toList() ?? [];

          // SORT chapter theo chapterNumber
          chapters.sort((a, b) =>
              (a['chapterNumber'] ?? 0).compareTo(b['chapterNumber'] ?? 0));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= STORY HEADER =================
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StoryDetailScreen(storyId: story['storyId']),
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
                          baseCoverUrl + (story['coverUrl'] ?? ""),
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
                              story['title'] ?? "Không có tên",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(story['status'])
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (story['status'] ?? "UNKNOWN").toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _getStatusColor(story['status']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= CHAPTER LIST =================
              ...chapters.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(left: 90, bottom: 4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoryDetailScreen(
                            storyId: story['storyId'],
                          ),
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
                            color: _getStatusColor(c['status'])
                                .withOpacity(0.15),
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