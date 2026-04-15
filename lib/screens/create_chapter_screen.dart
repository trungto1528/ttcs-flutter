import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/User.dart';
import '../services/chapter_fetcher.dart';
import '../services/story_fetcher.dart';

class ContentBlock {
  String type; // 'text' hoặc 'image'
  TextEditingController? controller;
  File? imageFile;
  String? fileName;
  String? existingUrl;

  ContentBlock.text({String content = ""})
    : type = 'text',
      controller = TextEditingController(text: content);

  ContentBlock.image(this.imageFile, this.fileName) : type = 'image';
}

class CreateChapterScreen extends StatefulWidget {
  final int? storyId;
  final String? storyTitle;
  final int? nextChapterNumber;

  const CreateChapterScreen({
    super.key,
    this.storyId,
    this.storyTitle,
    this.nextChapterNumber,
  });

  @override
  State<CreateChapterScreen> createState() => _CreateChapterScreenState();
}

class _CreateChapterScreenState extends State<CreateChapterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Story fields
  final _storyTitleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _coverImage;
  String? _existingCoverUrl;
  int? _selectedStoryId;
  bool _isNewStory = false;

  // Chapter fields
  final _chapterTitleController = TextEditingController();
  late TextEditingController _numberController;

  // Danh sách các khối nội dung
  List<ContentBlock> _blocks = [ContentBlock.text()];

  bool _isLoading = false;
  final baseCoverUrl = 'http://140.245.45.167:7778/cover/';

  @override
  void initState() {
    super.initState();
    _selectedStoryId = widget.storyId;
    _storyTitleController.text = widget.storyTitle ?? "";
    _numberController = TextEditingController(
      text: widget.nextChapterNumber?.toString() ?? "1",
    );
    if (_selectedStoryId == null) {
      _isNewStory = true;
    } else {
      _loadExistingStoryData(_selectedStoryId!);
    }
  }
  void _resetStorySelection() {
    setState(() {
      _selectedStoryId = null;
      _isNewStory = true;

      _storyTitleController.clear();
      _authorController.clear();
      _descriptionController.clear();

      _existingCoverUrl = null;
      _coverImage = null;
    });
  }

  Future<void> _loadExistingStoryData(int storyId) async {
    try {
      final storyData = await StoryFetcher().fetchStory(storyId);
      setState(() {
        _authorController.text = storyData['author'] ?? "";
        _descriptionController.text = storyData['description'] ?? "";
        _existingCoverUrl = storyData['coverUrl'];
      });
    } catch (e) {
      debugPrint("Error loading story data: $e");
    }
  }

  String _generateUuid() {
    return const Uuid().v4();
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _coverImage = File(image.path);
        _existingCoverUrl = null;
      });
    }
  }

  Future<void> _addAndPickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final String name = "${_generateUuid()}${p.extension(image.path)}";
    setState(() {
      _blocks.add(ContentBlock.image(File(image.path), name));
      _blocks.add(ContentBlock.text()); // Thêm ô nhập text mới sau ảnh
    });
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
      if (_blocks.isEmpty) _blocks.add(ContentBlock.text());
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // 1. FORM VALIDATE
    if (!_formKey.currentState!.validate()) return;

    // 2. CHECK CHAPTER TITLE
    if (_chapterTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nhập tiêu đề chương")));
      return;
    }

    // 3. CHECK CHAPTER NUMBER
    final chapterNumberText = _numberController.text.trim();
    if (chapterNumberText.isEmpty || int.tryParse(chapterNumberText) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Số chương không hợp lệ")));
      return;
    }

    // 4. CHECK CONTENT BLOCK (QUAN TRỌNG NHẤT)
    final hasContent = _blocks.any((block) {
      if (block.type == 'text') {
        return block.controller != null &&
            block.controller!.text.trim().isNotEmpty;
      }
      if (block.type == 'image') {
        return block.imageFile != null;
      }
      return false;
    });

    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nội dung chương không được rỗng")),
      );
      return;
    }

    // ======================
    // GIỮ NGUYÊN CODE CŨ BÊN DƯỚI
    // ======================

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString("user");
      if (userStr == null) throw Exception("Vui lòng đăng nhập");

      final user = User.fromJson(jsonDecode(userStr));

      int? targetStoryId = _selectedStoryId;
      if (_isNewStory && _selectedStoryId == null) {
        final storyTitle = _storyTitleController.text.trim();
        final author = _authorController.text.trim();
        final description = _descriptionController.text.trim();

        if (storyTitle.isEmpty || author.isEmpty || description.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Vui lòng nhập đầy đủ thông tin truyện"),
            ),
          );
          return;
        }
      }
      if (_isNewStory && targetStoryId == null) {
        String coverUrl = "";

        if (_coverImage != null) {
          final uploaded = await ChapterFetcher().uploadIllustration(
            _coverImage!,
          );
          if (uploaded != null) coverUrl = uploaded;
        }

        final newStory = await StoryFetcher().createStory(
          title: _storyTitleController.text.trim(),
          author: _authorController.text.trim(),
          description: _descriptionController.text.trim(),
          coverUrl: coverUrl,
          userId: user.id,
        );

        if (newStory == null) {
          throw Exception("Không thể tạo truyện mới");
        }

        targetStoryId = newStory['id'];
      }

      List<Map<String, String>> structuredContent = [];

      for (var block in _blocks) {
        if (block.type == 'text') {
          final text = block.controller!.text.trim();
          if (text.isNotEmpty) {
            structuredContent.add({"type": "text", "data": text});
          }
        } else if (block.type == 'image') {
          if (block.imageFile != null) {
            final uploaded = await ChapterFetcher().uploadIllustration(
              block.imageFile!,
            );

            if (uploaded == null) {
              throw Exception("Upload ảnh thất bại");
            }

            structuredContent.add({"type": "image", "data": uploaded});
          }
        }
      }

      final success = await ChapterFetcher().createChapter(
        storyId: targetStoryId!,
        title: _chapterTitleController.text.trim(),
        content: structuredContent,
        chapterNumber: int.parse(_numberController.text),
        userId: user.id,
      );

      if (!success) {
        throw Exception("Đăng chương thất bại");
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đăng chương thành công!")));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng chương mới")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "THÔNG TIN TRUYỆN",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Autocomplete<Map<String, dynamic>>(
                      initialValue: TextEditingValue(
                        text: _storyTitleController.text,
                      ),
                      displayStringForOption: (option) => option['title'],
                      optionsBuilder: (textValue) async {
                        if (textValue.text == '') return const Iterable.empty();
                        final results = await StoryFetcher().search(
                          textValue.text,
                        );
                        return results.map((e) => e as Map<String, dynamic>);
                      },
                      onSelected: (selection) {
                        setState(() {
                          _selectedStoryId = selection['id'];
                          _storyTitleController.text = selection['title'];
                          _isNewStory = false;
                        });
                        _loadExistingStoryData(selection['id']);
                      },
                      fieldViewBuilder: (ctx, ctrl, fNode, onSub) {
                        if (_storyTitleController.text.isNotEmpty &&
                            ctrl.text.isEmpty) {
                          ctrl.text = _storyTitleController.text;
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: ValueKey(_selectedStoryId), // 🔥 FORCE REBUILD
                                controller: ctrl,
                                focusNode: fNode,
                                enabled: _selectedStoryId == null,
                                decoration: const InputDecoration(
                                  labelText: "Tên truyện",
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.search),
                                ),
                                onChanged: (v) {
                                  _storyTitleController.text = v;
                                  if (_selectedStoryId != null) {
                                    setState(() {
                                      _selectedStoryId = null;
                                      _isNewStory = true;
                                      _existingCoverUrl = null;
                                      _coverImage = null;
                                      _authorController.clear();
                                      _descriptionController.clear();
                                    });
                                  }
                                },
                              ),
                            ),

                            // 🔥 NÚT RESET
                            if (_selectedStoryId != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: IconButton(
                                  tooltip: "Chọn lại truyện",
                                  icon: const Icon(Icons.refresh, color: Colors.orange),
                                  onPressed: () {
                                    setState(() {
                                      _selectedStoryId = null;
                                      _isNewStory = true;

                                      _storyTitleController.clear();
                                      _authorController.clear();
                                      _descriptionController.clear();

                                      _existingCoverUrl = null;
                                      _coverImage = null;
                                    });
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _selectedStoryId == null ? _pickCoverImage : null, // 🔒
                          child: Container(
                            width: 80,
                            height: 110,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _coverImage != null
                                ? Image.file(_coverImage!, fit: BoxFit.cover)
                                : (_existingCoverUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl:
                                              baseCoverUrl + _existingCoverUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                                Icons.add_a_photo,
                                                size: 30,
                                                color: Colors.grey,
                                              ),
                                        )
                                      : const Icon(
                                          Icons.add_a_photo,
                                          size: 30,
                                          color: Colors.grey,
                                        )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _authorController,
                                enabled: _selectedStoryId == null, // 🔒
                                decoration: const InputDecoration(
                                  labelText: "Tác giả",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descriptionController,
                                enabled: _selectedStoryId == null, // 🔒
                                decoration: const InputDecoration(
                                  labelText: "Mô tả truyện",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text(
                      "CHI TIẾT CHƯƠNG",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _numberController,
                            decoration: const InputDecoration(
                              labelText: "Số",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _chapterTitleController,
                            decoration: const InputDecoration(
                              labelText: "Tiêu đề chương",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_photo_alternate,
                            color: Colors.blue,
                          ),
                          onPressed: _addAndPickImage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "NỘI DUNG",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _blocks.length,
                        itemBuilder: (context, index) {
                          final block = _blocks[index];
                          if (block.type == 'text') {
                            return TextFormField(
                              controller: block.controller,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: "Nhập nội dung...",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      block.imageFile!,
                                      width: double.infinity,
                                      height: 250,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.red,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => _removeBlock(index),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        block.fileName!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _isNewStory && _selectedStoryId == null
                            ? "TẠO TRUYỆN & ĐĂNG CHƯƠNG"
                            : "ĐĂNG CHƯƠNG",
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
