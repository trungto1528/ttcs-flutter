import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/crawl_service.dart';

class CrawlScreen extends StatefulWidget {
  final int userId;
  const CrawlScreen({super.key, required this.userId});

  @override
  State<CrawlScreen> createState() => _CrawlScreenState();
}

class _CrawlScreenState extends State<CrawlScreen> {
  final TextEditingController controller = TextEditingController();
  final CrawlService crawlService = CrawlService();

  Map<String, dynamic>? data;
  bool loading = false;
  bool showDesc = false;

  Future<void> crawl() async {
    final url = controller.text.trim();
    if (url.isEmpty) return;

    setState(() {
      loading = true;
      data = null;
    });

    try {
      final result = await crawlService.crawlStory(url);

      setState(() {
        data = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() {
      loading = false;
    });
  }

  void toggle(Map chap, bool value) {
    setState(() {
      chap['choosen'] = value;
    });
  }

  void selectAll(bool value) {
    setState(() {
      if (data == null) return;

      for (final vol in data!['volumes']) {
        for (final chap in vol['chapters']) {
          chap['choosen'] = value;
        }
      }
    });
  }

  List<Map<String, dynamic>> get selectedChapters {
    if (data == null) return [];

    final result = <Map<String, dynamic>>[];

    for (final vol in data!['volumes']) {
      for (final chap in vol['chapters']) {
        if (chap['choosen'] == true) {
          result.add(chap);
        }
      }
    }
    return result;
  }

    void submit() async {
      if (data == null) return;
      try {
        await crawlService.importStory(data!, widget.userId);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Import thành công")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Import lỗi: $e")),
        );
      }
    }

  @override
  Widget build(BuildContext context) {
    final volumes = data?['volumes'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Crawl Story")),
      floatingActionButton: data == null
          ? null
          : FloatingActionButton.extended(
        onPressed: submit,
        icon: const Icon(Icons.download),
        label: Text("Import (${selectedChapters.length})"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// INPUT
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Nhập URL truyện",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: loading ? null : crawl,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: loading ? null : crawl,
              child: Text(loading ? "Đang crawl..." : "Crawl"),
            ),

            const SizedBox(height: 10),

            if (loading) const LinearProgressIndicator(),

            if (!loading && data == null)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("Nhập URL để bắt đầu crawl"),
              ),

            /// RESULT
            if (data != null)
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// ===== TOP: COVER + INFO =====
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// COVER (TRÁI)
                              if (data!['cover'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    data!['cover'],
                                    width: 120,
                                    height: 170,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 120,
                                  height: 170,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),

                              const SizedBox(width: 12),

                              /// INFO (PHẢI)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data!['title'] ?? "",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      "Tác giả: ${data!['author'] ?? ""}",
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "Số chương: ${(data!['volumes'] ?? []).fold(0, (p, v) => p + (v['chapters'] as List).length)}",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          /// ===== DESCRIPTION =====
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Mô tả",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    showDesc = !showDesc;
                                  });
                                },
                                child: Text(showDesc ? "Ẩn" : "Xem"),
                              ),
                            ],
                          ),

                          if (showDesc)
                            Text(
                              data!['description'] ?? "",
                              style: const TextStyle(height: 1.4),
                            ),

                          const Divider(),
                        ],
                      ),
                    ),
                    const Divider(),

                    /// ACTION BUTTONS
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => selectAll(true),
                          icon: const Icon(Icons.select_all),
                          label: const Text("Chọn tất cả"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => selectAll(false),
                          icon: const Icon(Icons.clear),
                          label: const Text("Bỏ chọn"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// VOLUMES
                    ...volumes.map<Widget>((vol) {
                      final chapters = (vol['chapters'] as List);

                      return ExpansionTile(
                        title: Text(vol['title'] ?? ""),
                        children: chapters.map<Widget>((chap) {
                          return CheckboxListTile(
                            value: chap['choosen'] ?? false,
                            onChanged: (v) => toggle(chap, v ?? false),
                            title: Text(chap['title'] ?? ""),
                            subtitle: Text(
                              chap['url'] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}