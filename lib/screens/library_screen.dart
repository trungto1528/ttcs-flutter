import 'package:flutter/material.dart';
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thư viện")),
      body: const Center(child: Text("Danh sách truyện đã lưu")),
    );
  }
}