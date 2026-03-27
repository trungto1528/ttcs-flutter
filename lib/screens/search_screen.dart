import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:novel_app/screens/story_detail_screen.dart';

import 'package:novel_app/models/Story.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();

  Timer? _debounce;

  List<Story> stories = [];
  bool isLoading = false;
  String keyword = "";

  // ================= API =================
  Future<void> search(String keyword) async {
    if (keyword.isEmpty) {
      setState(() => stories = []);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.get(
        Uri.parse("http://140.245.45.167:7777/api/stories/search?keyword=$keyword"),
      );

      final data = jsonDecode(res.body);

      setState(() {
        stories = data.map<Story>((e) => Story.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => isLoading = false);
  }

  // ================= DEBOUNCE =================
  void onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      keyword = value;
      search(keyword);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Tìm truyện...",
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                setState(() {
                  stories = [];
                  keyword = "";
                });
              },
            ),
          ),
          onChanged: onChanged,
        ),
      ),

      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (keyword.isEmpty) {
      return const Center(child: Text("Nhập từ khóa để tìm truyện"));
    }

    if (stories.isEmpty) {
      return const Center(child: Text("Không tìm thấy kết quả"));
    }

    return ListView.builder(
      itemCount: stories.length,
      itemBuilder: (_, i) {
        final s = stories[i];

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              s.coverUrl ?? "https://placehold.co/400x400/png",
              fit: BoxFit.cover,
            ),
          ),
          title: Text(s.title),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoryDetailScreen(storyId: s.id),
              ),
            );
          },
        );
      },
    );
  }
}