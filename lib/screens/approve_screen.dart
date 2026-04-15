import 'package:flutter/material.dart';
import '../services/story_fetcher.dart';
import '../services/chapter_fetcher.dart';

class AdminApproveScreen extends StatefulWidget {
  final int adminId;
  const AdminApproveScreen({super.key, required this.adminId});

  @override
  State<AdminApproveScreen> createState() => _AdminApproveScreenState();
}

class _AdminApproveScreenState extends State<AdminApproveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List stories = [];
  List chapters = [];

  bool loadingStories = true;
  bool loadingChapters = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadStories(),
      _loadChapters(),
    ]);
  }

  Future<void> _loadStories() async {
    setState(() => loadingStories = true);

    final data = await StoryFetcher().getAllStories(widget.adminId);

    setState(() {
      stories = data;
      loadingStories = false;
    });
  }

  Future<void> _loadChapters() async {
    setState(() => loadingChapters = true);

    final data = await ChapterFetcher().getMyChapter(widget.adminId);

    setState(() {
      chapters = data;
      loadingChapters = false;
    });
  }

  Future<void> _approveStory(int id) async {
    await StoryFetcher().approveStory(widget.adminId, id);
    _loadStories();
  }

  Future<void> _approveChapter(int id) async {
    await ChapterFetcher().approveChapter(widget.adminId, id);
    _loadChapters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Approve"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Stories"),
            Tab(text: "Chapters"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ================= STORIES =================
          loadingStories
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: stories.length,
            itemBuilder: (context, i) {
              final s = stories[i];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(s["title"] ?? ""),
                  subtitle: Text("Status: ${s["status"]}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _approveStory(s["id"]),
                  ),
                ),
              );
            },
          ),

          // ================= CHAPTERS =================
          loadingChapters
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, i) {
              final c = chapters[i];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("Chap ${c["chapterNumber"]}: ${c["title"]}"),
                  subtitle: Text("Status: ${c["status"]}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _approveChapter(c["id"]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}