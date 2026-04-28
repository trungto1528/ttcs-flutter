import 'dart:async';
import 'package:flutter/material.dart';
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
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  // ==========================================
  // LOGIC XỬ LÝ
  // ==========================================

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
        // Mặc định chọn tất cả chương khi vừa crawl xong
        selectAll(true);
      });
    } catch (e) {
      _showSnackBar("Lỗi crawl: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void selectAll(bool value) {
    if (data == null) return;
    setState(() {
      for (final vol in data!['volumes']) {
        for (final chap in vol['chapters']) {
          chap['choosen'] = value;
        }
      }
    });
  }

  void toggle(Map chap, bool value) {
    setState(() => chap['choosen'] = value);
  }

  List<Map<String, dynamic>> get selectedChapters {
    if (data == null) return [];
    final result = <Map<String, dynamic>>[];
    for (final vol in data!['volumes']) {
      for (final chap in vol['chapters']) {
        if (chap['choosen'] == true) result.add(chap);
      }
    }
    return result;
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  void _showAllTasksSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Timer? localTimer;
            localTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
              if (context.mounted) setModalState(() {});
            });

            return FutureBuilder(
              future: crawlService.getAllTasks(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final tasks = snapshot.data as Map<String, dynamic>;
                if (tasks.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Không có tiến trình nào đang chạy"),
                  ));
                }

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Danh sách tiến độ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          String taskId = tasks.keys.elementAt(index);
                          var t = tasks[taskId];
                          double prog = t['total'] > 0 ? t['processed'] / t['total'] : 0;
                          bool isDone = t['message'].toString().contains("thành") || t['message'].toString().contains("hủy");

                          return ListTile(
                            title: Text(t['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(value: prog),
                                Text("${t['processed']}/${t['total']} - ${t['message']}"),
                              ],
                            ),
                            trailing: isDone
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : IconButton(
                              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                              onPressed: () async {
                                await crawlService.cancelTask(taskId);
                                setModalState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        localTimer?.cancel();
                        Navigator.pop(context);
                      },
                      child: const Text("Đóng"),
                    )
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ==========================================
  // THEO DÕI TIẾN ĐỘ (PROGRESS UI)
  // ==========================================

  void _showProgressSheet(String taskId) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Thiết lập Timer để refresh dữ liệu mỗi 2 giây
            _progressTimer?.cancel();
            _progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
              if (!mounted) return;
              setModalState(() {}); // Force update UI của BottomSheet
            });

            return FutureBuilder(
              future: crawlService.getAllTasks(),
              builder: (context, snapshot) {
                final allTasks = snapshot.data;
                final task = allTasks?[taskId];

                if (task == null) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                int processed = task['processed'] ?? 0;
                int total = task['total'] ?? 0;
                double progress = total > 0 ? processed / total : 0;
                String msg = task['message'] ?? "";
                bool isDone = msg == "Hoàn thành!" || msg.contains("Lỗi") || msg.contains("hủy");

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task['title'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 15),
                      Text("Tiến độ: $processed / $total chương"),
                      Text(
                        "Trạng thái: $msg",
                        style: TextStyle(
                          color: isDone ? (msg == "Hoàn thành!" ? Colors.green : Colors.red) : Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          if (!isDone)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await crawlService.cancelTask(taskId);
                                  _progressTimer?.cancel();
                                  if (context.mounted) Navigator.pop(context);
                                  _showSnackBar("Đã gửi yêu cầu dừng.");
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text("Hủy cào"),
                              ),
                            ),
                          if (!isDone) const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _progressTimer?.cancel();
                                Navigator.pop(context);
                              },
                              child: Text(isDone ? "Xong" : "Chạy ngầm"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void submit() async {
    if (data == null || selectedChapters.isEmpty) {
      _showSnackBar("Vui lòng chọn ít nhất 1 chương");
      return;
    }
    try {
      final res = await crawlService.importStory(data!, widget.userId);
      final taskId = res['taskId'].toString();
      _showProgressSheet(taskId);
    } catch (e) {
      _showSnackBar("Lỗi Import: $e");
    }
  }

  // ==========================================
  // BUILD UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final volumes = data?['volumes'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("1 cào là pay truyện"),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            onPressed: _showAllTasksSheet,
            tooltip: "Tiến độ cào",
          ),
          if (data != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: crawl,
            )
        ],
      ),
      floatingActionButton: data == null
          ? null
          : FloatingActionButton.extended(
        onPressed: submit,
        icon: const Icon(Icons.cloud_download),
        label: Text("Import (${selectedChapters.length})"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "docln.net/docln.sbs/ln.hako.vn",
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: loading ? null : crawl,
                ),
              ),
              onSubmitted: (_) => crawl(),
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          if (data == null && !loading)
            const Expanded(
              child: Center(child: Text("Hãy nhập URL truyện để bắt đầu")),
            ),
          if (data != null)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  _buildStoryHeader(),
                  _buildActionButtons(),
                  _buildVolumeList(volumes),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: data!['cover'] != null
                    ? Image.network(data!['cover'], width: 100, height: 140, fit: BoxFit.cover)
                    : Container(width: 100, height: 140, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data!['title'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Tác giả: ${data!['author'] ?? "Ẩn danh"}"),
                    const SizedBox(height: 4),
                    Text("Tổng chương: ${data!['volumes'].fold(0, (p, v) => p + (v['chapters'] as List).length)}"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            title: const Text("Mô tả truyện", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            children: [Padding(padding: const EdgeInsets.all(8.0), child: Text(data!['description'] ?? ""))],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          TextButton.icon(onPressed: () => selectAll(true), icon: const Icon(Icons.check_box), label: const Text("Tất cả")),
          TextButton.icon(onPressed: () => selectAll(false), icon: const Icon(Icons.check_box_outline_blank), label: const Text("Bỏ chọn")),
        ],
      ),
    );
  }

  Widget _buildVolumeList(List volumes) {
    return Column(
      children: volumes.map<Widget>((vol) {
        final chaps = vol['chapters'] as List;
        return ExpansionTile(
          initiallyExpanded: true,
          title: Text(vol['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
          children: chaps.map<Widget>((c) {
            return CheckboxListTile(
              value: c['choosen'] ?? false,
              onChanged: (v) => toggle(c, v ?? false),
              title: Text(c['title'] ?? ""),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
