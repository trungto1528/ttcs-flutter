import 'dart:async';

import 'package:flutter/material.dart';

import '../services/crawl_service.dart';

class CrawlScreen extends StatefulWidget {
  final int userId;

  const CrawlScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CrawlScreen> createState() => _CrawlScreenState();
}

class _CrawlScreenState extends State<CrawlScreen> {
  final TextEditingController controller =
  TextEditingController();

  final CrawlService crawlService =
  CrawlService();

  Map<String, dynamic>? data;

  bool loading = false;

  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  // =========================================================
  // CRAWL
  // =========================================================

  Future<void> crawl() async {
    final url = controller.text.trim();

    if (url.isEmpty) {
      _showSnackBar(
        "Vui lòng nhập URL truyện",
      );
      return;
    }

    setState(() {
      loading = true;
      data = null;
    });

    try {
      final result =
      await crawlService.crawlStory(url);

      if (!mounted) {
        return;
      }

      setState(() {
        data = result;
      });

      selectAll(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        "Lỗi crawl: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // =========================================================
  // CHAPTER SELECTION
  // =========================================================

  void selectAll(bool value) {
    if (data == null) {
      return;
    }

    setState(() {
      final volumes =
          data!['volumes'] as List? ?? [];

      for (final volume in volumes) {
        final chapters =
            volume['chapters'] as List? ?? [];

        for (final chapter in chapters) {
          chapter['choosen'] = value;
        }
      }
    });
  }

  void toggle(
      Map chapter,
      bool value,
      ) {
    setState(() {
      chapter['choosen'] = value;
    });
  }

  List<Map<String, dynamic>>
  get selectedChapters {

    if (data == null) {
      return [];
    }

    final result =
    <Map<String, dynamic>>[];

    final volumes =
        data!['volumes'] as List? ?? [];

    for (final volume in volumes) {
      final chapters =
          volume['chapters'] as List? ?? [];

      for (final chapter in chapters) {
        if (chapter['choosen'] == true) {
          result.add(
            Map<String, dynamic>.from(
              chapter,
            ),
          );
        }
      }
    }

    return result;
  }

  // =========================================================
  // IMPORT
  // =========================================================

  Future<void> submit() async {
    if (data == null ||
        selectedChapters.isEmpty) {

      _showSnackBar(
        "Vui lòng chọn ít nhất 1 chương",
      );

      return;
    }

    try {
      final res =
      await crawlService.importStory(
        data!,
        widget.userId,
      );

      final taskId =
      res['taskId'].toString();

      _showProgressSheet(taskId);
    } catch (e) {
      _showSnackBar(
        "Lỗi Import: $e",
      );
    }
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void _showSnackBar(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // TASK LIST
  // =========================================================

  void _showAllTasksSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SizedBox(
          height:
          MediaQuery.of(context)
              .size
              .height *
              0.75,
          child: FutureBuilder<
              Map<String, dynamic>>(
            future:
            crawlService.getAllTasks(),
            builder:
                (context, snapshot) {

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child:
                  CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Lỗi: ${snapshot.error}",
                  ),
                );
              }

              final tasks =
                  snapshot.data ?? {};

              if (tasks.isEmpty) {
                return const Center(
                  child: Text(
                    "Không có tiến trình nào",
                  ),
                );
              }

              return Column(
                children: [
                  const Padding(
                    padding:
                    EdgeInsets.all(16),
                    child: Text(
                      "Danh sách tiến độ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                    ListView.builder(
                      itemCount:
                      tasks.length,
                      itemBuilder:
                          (context, index) {

                        final taskId =
                        tasks.keys
                            .elementAt(
                          index,
                        );

                        final task =
                        tasks[taskId];

                        final int processed =
                            task['processed'] ??
                                0;

                        final int total =
                            task['total'] ?? 0;

                        final double progress =
                        total > 0
                            ? processed /
                            total
                            : 0;

                        final String message =
                            task['message']
                                ?.toString() ??
                                "";

                        final bool isDone =
                            message.contains(
                              "Hoàn thành",
                            ) ||
                                message.contains(
                                  "hủy",
                                ) ||
                                message.contains(
                                  "Lỗi",
                                );

                        return ListTile(
                          title: Text(
                            task['title']
                                ?.toString() ??
                                "",
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                          subtitle:
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              const SizedBox(
                                height: 6,
                              ),
                              LinearProgressIndicator(
                                value:
                                progress,
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                "$processed/$total - $message",
                              ),
                            ],
                          ),
                          trailing: isDone
                              ? const Icon(
                            Icons
                                .check_circle,
                            color:
                            Colors.green,
                          )
                              : IconButton(
                            icon:
                            const Icon(
                              Icons
                                  .stop_circle_outlined,
                              color:
                              Colors.red,
                            ),
                            onPressed:
                                () async {
                              await crawlService
                                  .cancelTask(
                                taskId,
                              );

                              if (context
                                  .mounted) {
                                Navigator.pop(
                                  context,
                                );
                              }

                              _showAllTasksSheet();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding:
                    const EdgeInsets
                        .only(
                      bottom: 16,
                    ),
                    child:
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(
                            context,
                          ),
                      child:
                      const Text(
                        "Đóng",
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // PROGRESS
  // =========================================================

  void _showProgressSheet(
      String taskId,
      ) {
    _progressTimer?.cancel();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setModalState) {

            _progressTimer =
                Timer.periodic(
                  const Duration(
                    seconds: 2,
                  ),
                      (_) {
                    if (context.mounted) {
                      setModalState(() {});
                    }
                  },
                );

            return FutureBuilder<
                Map<String, dynamic>>(
              future:
              crawlService
                  .getAllTasks(),
              builder:
                  (context, snapshot) {

                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 220,
                    child: Center(
                      child:
                      CircularProgressIndicator(),
                    ),
                  );
                }

                final allTasks =
                snapshot.data!;

                final task =
                allTasks[taskId];

                if (task == null) {
                  return const SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        "Không tìm thấy task",
                      ),
                    ),
                  );
                }

                final int processed =
                    task['processed'] ??
                        0;

                final int total =
                    task['total'] ??
                        0;

                final double progress =
                total > 0
                    ? processed / total
                    : 0;

                final String message =
                    task['message']
                        ?.toString() ??
                        "";

                final bool isDone =
                    message.contains(
                      "Hoàn thành",
                    ) ||
                        message.contains(
                          "Lỗi",
                        ) ||
                        message.contains(
                          "hủy",
                        );

                return Padding(
                  padding:
                  const EdgeInsets.all(
                    24,
                  ),
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Text(
                        task['title']
                            ?.toString() ??
                            "",
                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                        textAlign:
                        TextAlign.center,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        borderRadius:
                        BorderRadius
                            .circular(
                          5,
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Text(
                        "Tiến độ: $processed / $total chương",
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        "Trạng thái: $message",
                        style: TextStyle(
                          color: isDone
                              ? message.contains(
                              "Hoàn thành")
                              ? Colors.green
                              : Colors.red
                              : Colors.blue,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      Row(
                        children: [
                          if (!isDone)
                            Expanded(
                              child:
                              OutlinedButton(
                                onPressed:
                                    () async {
                                  await crawlService
                                      .cancelTask(
                                    taskId,
                                  );

                                  _progressTimer
                                      ?.cancel();

                                  if (context
                                      .mounted) {
                                    Navigator.pop(
                                      context,
                                    );
                                  }

                                  _showSnackBar(
                                    "Đã gửi yêu cầu dừng.",
                                  );
                                },
                                style:
                                OutlinedButton
                                    .styleFrom(
                                  foregroundColor:
                                  Colors.red,
                                ),
                                child:
                                const Text(
                                  "Hủy cào",
                                ),
                              ),
                            ),
                          if (!isDone)
                            const SizedBox(
                              width: 12,
                            ),
                          Expanded(
                            child:
                            ElevatedButton(
                              onPressed: () {
                                _progressTimer
                                    ?.cancel();

                                Navigator.pop(
                                  context,
                                );
                              },
                              child: Text(
                                isDone
                                    ? "Xong"
                                    : "Chạy ngầm",
                              ),
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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final volumes =
        data?['volumes'] as List? ??
            [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Cào truyện",
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.assignment_outlined,
            ),
            tooltip:
            "Tiến độ cào",
            onPressed:
            _showAllTasksSheet,
          ),
          if (data != null)
            IconButton(
              icon: const Icon(
                Icons.refresh,
              ),
              tooltip:
              "Cào lại",
              onPressed:
              loading ? null : crawl,
            ),
        ],
      ),

      floatingActionButton:
      data == null
          ? null
          : FloatingActionButton
          .extended(
        onPressed:
        submit,
        icon: const Icon(
          Icons.cloud_download,
        ),
        label: Text(
          "Import (${selectedChapters.length})",
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.all(
              12,
            ),
            child: TextField(
              controller:
              controller,
              decoration:
              InputDecoration(
                hintText:
                "Nhập URL MangaRead",
                prefixIcon:
                const Icon(
                  Icons.link,
                ),
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),
                suffixIcon:
                IconButton(
                  icon:
                  const Icon(
                    Icons.search,
                  ),
                  onPressed:
                  loading
                      ? null
                      : crawl,
                ),
              ),
              onSubmitted:
                  (_) => crawl(),
            ),
          ),

          if (loading)
            const LinearProgressIndicator(),

          if (data == null &&
              !loading)
            const Expanded(
              child: Center(
                child: Text(
                  "Hãy nhập URL MangaRead để bắt đầu",
                ),
              ),
            ),

          if (data != null)
            Expanded(
              child:
              ListView(
                padding:
                const EdgeInsets
                    .only(
                  bottom: 80,
                ),
                children: [
                  _buildStoryHeader(),
                  _buildInformation(),
                  _buildActionButtons(),
                  _buildVolumeList(
                    volumes,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // STORY HEADER
  // =========================================================

  Widget _buildStoryHeader() {
    final volumes =
        data!['volumes'] as List? ??
            [];

    int totalChapters = 0;

    for (final volume in volumes) {
      final chapters =
          volume['chapters']
          as List? ??
              [];

      totalChapters +=
          chapters.length;
    }

    return Padding(
      padding:
      const EdgeInsets.all(
        16,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius
                    .circular(
                  8,
                ),
                child:
                data!['cover'] !=
                    null &&
                    data!['cover']
                        .toString()
                        .isNotEmpty
                    ? Image.network(
                  data!['cover'],
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return _coverPlaceholder();
                  },
                )
                    : _coverPlaceholder(),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      data!['title']
                          ?.toString() ??
                          "",
                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      "Tác giả: ${data!['author']?.toString().isNotEmpty == true ? data!['author'] : "Ẩn danh"}",
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      "Tổng chương: $totalChapters",
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          _buildDescription(),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 100,
      height: 140,
      color: Colors.grey[300],
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
      ),
    );
  }

  // =========================================================
  // DESCRIPTION
  // =========================================================

  Widget _buildDescription() {
    final description =
        data!['description']
            ?.toString() ??
            "";

    if (description.isEmpty) {
      return const SizedBox();
    }

    return ExpansionTile(
      tilePadding:
      EdgeInsets.zero,
      title: const Text(
        "Mô tả truyện",
        style: TextStyle(
          fontSize: 14,
          fontWeight:
          FontWeight.bold,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(
            12,
          ),
          decoration:
          BoxDecoration(
            color:
            Colors.grey[100],
            borderRadius:
            BorderRadius
                .circular(
              8,
            ),
          ),
          child: Text(
            description,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INFORMATION
  // =========================================================

  Widget _buildInformation() {
    final information =
        data!['information']
        as List? ??
            [];

    if (information.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Card(
        elevation: 0,
        child: ExpansionTile(
          initiallyExpanded: true,
          title: const Text(
            "Thông tin truyện",
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
          children: [
            Padding(
              padding:
              const EdgeInsets
                  .fromLTRB(
                16,
                0,
                16,
                12,
              ),
              child: Column(
                children: information
                    .map<Widget>(
                      (item) {
                    final label =
                        item['label']
                            ?.toString() ??
                            "";

                    final value =
                        item['value']
                            ?.toString() ??
                            "";

                    if (label.isEmpty &&
                        value.isEmpty) {
                      return const SizedBox();
                    }

                    return _buildInfoRow(
                      label,
                      value,
                    );
                  },
                )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              value,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHAPTER ACTIONS
  // =========================================================

  Widget _buildActionButtons() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () =>
                selectAll(true),
            icon: const Icon(
              Icons.check_box,
            ),
            label:
            const Text(
              "Tất cả",
            ),
          ),
          TextButton.icon(
            onPressed: () =>
                selectAll(false),
            icon: const Icon(
              Icons
                  .check_box_outline_blank,
            ),
            label:
            const Text(
              "Bỏ chọn",
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHAPTER LIST
  // =========================================================

  Widget _buildVolumeList(
      List volumes,
      ) {
    return Column(
      children: volumes
          .map<Widget>(
            (volume) {

          final chapters =
              volume['chapters']
              as List? ??
                  [];

          return ExpansionTile(
            initiallyExpanded:
            true,
            title: Text(
              volume['title']
                  ?.toString() ??
                  "",
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            children:
            chapters
                .map<Widget>(
                  (chapter) {
                return CheckboxListTile(
                  value:
                  chapter['choosen'] ??
                      false,
                  onChanged:
                      (value) {
                    toggle(
                      chapter,
                      value ??
                          false,
                    );
                  },
                  title: Text(
                    chapter['title']
                        ?.toString() ??
                        "",
                  ),
                  dense: true,
                );
              },
            )
                .toList(),
          );
        },
      )
          .toList(),
    );
  }
}