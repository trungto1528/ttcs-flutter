import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:novel_app/models/Story.dart';
import 'package:novel_app/screens/story_detail_screen.dart';

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

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) {
      setState(() => stories = []);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.get(
        Uri.parse(
          "http://140.245.45.167:7777/api/stories/search?keyword=$keyword",
        ),
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

  void onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 100), () {
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
        return  InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoryDetailScreen(storyId: s.id),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    width: 70,
                    height: 105,
                    fit: BoxFit.cover,
                    imageUrl: "http://140.245.45.167:7778/cover/${s.coverUrl}",
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
