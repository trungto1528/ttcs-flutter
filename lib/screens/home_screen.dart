import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:novel_app/screens/chapter_reader_screen.dart';
import 'package:novel_app/screens/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../route_observer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  String? lastStoryTitle;
  int? lastChapterIndex;
  int? lastChapterNumber;
  late List storyList;
  bool isSearching = false;
  String keyword = "";
  Timer? _debounce;

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

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastStoryTitle = prefs.getString('lastStoryTitle');
      lastChapterIndex = prefs.getInt('lastChapterIndex');
      lastChapterNumber = prefs.getInt('lastChapterNumber');
      storyList = jsonDecode(prefs.getString('storyList')!);
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

      // BODY SWITCH
      body: buildHome(),
    );
  }

  Widget buildHome() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (lastStoryTitle != null && lastChapterIndex != null) ...[
          Row(
            children: const [
              SizedBox(width: 8),
              Text(
                "Đọc tiếp",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 12),
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChapterReaderScreen(
                    chapters: storyList,
                    currentIndex: lastChapterIndex!,
                    storyTitle: lastStoryTitle!,
                  ),
                ),
              );
            },
            title: Text(lastStoryTitle!),
            subtitle: Text("Chương $lastChapterNumber"),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
