import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/story_fetcher.dart';
import '../services/chapter_fetcher.dart';

class AdminStoryManagerScreen extends StatefulWidget {
  final int adminId;

  const AdminStoryManagerScreen({super.key, required this.adminId});

  @override
  State<AdminStoryManagerScreen> createState() =>
      _AdminStoryManagerScreenState();
}

class _AdminStoryManagerScreenState
    extends State<AdminStoryManagerScreen> {
  List stories = [];
  Map<int, List> storyChapters = {};
  bool isLoading = true;

  final baseCoverUrl = "http://140.245.45.167:7778/cover/";

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  // ================= LOAD =================

  Future<void> _loadStories() async {
    try {
      final data =
      await StoryFetcher().getAllStories(widget.adminId);

      setState(() {
        stories = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadChapters(int storyId) async {
    try {
      final data = await StoryFetcher()
          .fetchStoryAdmin(storyId, widget.adminId);

      setState(() {
        storyChapters[storyId] = data?['chapters'] ?? [];
      });
    } catch (e) {
      print(e);
    }
  }

  // ================= ACTION =================

  Future<void> _approveStory(int id) async {
    await StoryFetcher().approveStory(widget.adminId, id);
    _loadStories();
  }

  Future<void> _rejectStory(int id) async {
    await StoryFetcher().rejectStory(widget.adminId, id);
    _loadStories();
  }

  Future<void> _deleteStory(int id) async {
    await StoryFetcher().deleteStory(id, widget.adminId);
    _loadStories();
  }

  Future<void> _approveChapter(int storyId, int chapterId) async {
    await ChapterFetcher()
        .approveChapter(widget.adminId, chapterId);
    _loadChapters(storyId);
  }

  Future<void> _rejectChapter(int storyId, int chapterId) async {
    await ChapterFetcher()
        .rejectChapter(widget.adminId, chapterId);
    _loadChapters(storyId);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý truyện")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadStories,
        child: ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            final id = story['id'];

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.all(10),

                // ================= HEADER =================
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        imageUrl:
                        "$baseCoverUrl${story['coverUrl']}",
                        placeholder: (_, __) => const SizedBox(
                          width: 60,
                          height: 90,
                          child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) =>
                        const Icon(Icons.image, size: 60),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            story['title'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),

                          Text(
                            "Tác giả: ${story['author'] ?? "Unknown"}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 6),

                          buildStatusChip(story['status']),
                        ],
                      ),
                    ),
                  ],
                ),

                onExpansionChanged: (expanded) {
                  if (expanded &&
                      !storyChapters.containsKey(id)) {
                    _loadChapters(id);
                  }
                },

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (story['status'] == "PENDING") ...[
                      IconButton(
                        icon: const Icon(Icons.check,
                            color: Colors.green),
                        onPressed: () =>
                            _approveStory(id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.orange),
                        onPressed: () =>
                            _confirmRejectStory(id),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      onPressed: () =>
                          _confirmDeleteStory(id),
                    ),
                  ],
                ),

                children: _buildChapters(id),
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= CHAPTER =================

  List<Widget> _buildChapters(int storyId) {
    final chapters = storyChapters[storyId];

    if (chapters == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(),
        )
      ];
    }

    if (chapters.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(10),
          child: Text("Chưa có chương nào"),
        )
      ];
    }

    return chapters.map<Widget>((c) {
      final status = c['status'];

      return Container(
        margin:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.withValues(alpha: 0.05),
        ),
        child: ListTile(
          title: Text(
            "Chương ${c['chapterNumber']}: ${c['title']}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(c['createdByName'] ?? ""),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildStatusChip(status),
              if (status == "PENDING") ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.check,
                      color: Colors.green),
                  onPressed: () =>
                      _approveChapter(storyId, c['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.red),
                  onPressed: () =>
                      _rejectChapter(storyId, c['id']),
                ),
              ]
            ],
          ),
        ),
      );
    }).toList();
  }

  // ================= STATUS CHIP =================

  Widget buildStatusChip(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // ================= DIALOG =================

  void _confirmDeleteStory(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xoá truyện"),
        content:
        const Text("Bạn có chắc muốn xoá truyện này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStory(id);
            },
            child: const Text("Xoá",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmRejectStory(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Từ chối truyện"),
        content:
        const Text("Bạn có chắc muốn từ chối truyện này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectStory(id);
            },
            child: const Text("Từ chối",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ================= UTIL =================

  Color _getStatusColor(String status) {
    switch (status) {
      case "APPROVED":
        return Colors.green;
      case "PENDING":
        return Colors.orange;
      case "REJECTED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}