import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:novel_app/screens/chapter_reader_screen.dart';
import 'package:novel_app/screens/search_screen.dart';
import 'package:novel_app/services/chapter_fetcher.dart';
import 'package:novel_app/services/story_fetcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/User.dart';
import '../route_observer.dart';
import '../services/auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  String? lastStoryTitle;
  int? lastChapterNumber;
  late List storyList;
  bool isSearching = false;
  String keyword = "";
  Timer? _debounce;
  final baseCoverUrl = 'http://140.245.45.167:7778/cover';
  String? coverUrl;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadLastRead();
  }

  int? userId;
  int? lastStoryId;
  int? lastChapterId;
  int? lastReadCreatedById;

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();

    var storedUser = prefs.getString('user');
    int? storedStoryId = prefs.getInt("lastStoryId");
    int? storedChapterId = prefs.getInt("lastChapterId");
    int? storedCreatedById = prefs.getInt('lastReadCreatedById');

    String? storyTitle;
    String? cover;
    int? chapterNumber;

    int? uid;

    if (storedUser != null) {
      var user = User.fromJson(jsonDecode(storedUser));
      uid = user.id;
      storedUser =await Auth().fetchUser(uid);
      user = User.fromJson(jsonDecode(storedUser));
      if (user.lastReadStoryId != -1 && user.lastReadChapterId != -1&& user.lastReadCreatedById != -1) {
        storedStoryId = user.lastReadStoryId;
        storedChapterId = user.lastReadChapterId;
        storedCreatedById = user.lastReadCreatedById;
      }
    }
    if (storedStoryId != null && storedChapterId != null && storedCreatedById != null) {
      final storyData = await StoryFetcher().fetchStory(storedStoryId);
      storyTitle = storyData['title'];
      cover = storyData['coverUrl'];

      final chapterData = await ChapterFetcher().fetchChapter(storedChapterId);
      chapterNumber = chapterData['chapterNumber'];
    }

    setState(() {
      userId = uid;
      lastStoryId = storedStoryId;
      lastChapterId = storedChapterId;
      lastReadCreatedById = storedCreatedById;
      lastStoryTitle = storyTitle;
      coverUrl = cover;
      lastChapterNumber = chapterNumber;
    });
  }

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        keyword = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TTCS"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: buildHome(),
    );
  }

  Widget buildHome() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (lastStoryId != null && lastChapterId != null && lastReadCreatedById!=null) ...[
          const SizedBox(width: 8),
          Text(
            "Đọc tiếp",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),
          Row(
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
                        builder: (_) => ChapterReaderScreen(
                          storyId: lastStoryId!,
                          chapterId: lastChapterId!,
                          createdById: lastReadCreatedById!,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lastStoryTitle ?? "",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text("Chương $lastChapterNumber"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
