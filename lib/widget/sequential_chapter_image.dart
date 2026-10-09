import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SequentialChapterImage extends StatefulWidget {
  final String imageUrl;
  final bool shouldLoad;
  final VoidCallback? onLoadFinished;

  const SequentialChapterImage({
    super.key,
    required this.imageUrl,
    this.shouldLoad = true,
    this.onLoadFinished,
  });

  @override
  State<SequentialChapterImage> createState() =>
      _SequentialChapterImageState();
}

class _SequentialChapterImageState extends State<SequentialChapterImage> {
  bool _notifiedFinished = false;

  void _notifyFinished() {
    if (_notifiedFinished) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _notifiedFinished) return;

      _notifiedFinished = true;
      widget.onLoadFinished?.call();
    });
  }

  Widget _placeholder() {
    return const SizedBox(
      width: double.infinity,
      height: 220,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _errorWidget() {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 36,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            const Text(
              'Không thể tải ảnh',
              style: TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _notifiedFinished = false;
                });
              },
              child: const Text('Thử tải lại'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Chưa đến giai đoạn tải ảnh này.
    if (!widget.shouldLoad) {
      return _placeholder();
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: double.infinity,
      fit: BoxFit.fitWidth,
      placeholder: (context, url) => _placeholder(),
      imageBuilder: (context, imageProvider) {
        _notifyFinished();

        return Image(
          image: imageProvider,
          width: double.infinity,
          fit: BoxFit.fitWidth,
        );
      },
      errorWidget: (context, url, error) {
        // Ảnh lỗi cũng được xem là đã hoàn tất,
        // tránh việc 3 ảnh đầu bị kẹt ở giai đoạn chờ.
        _notifyFinished();
        return _errorWidget();
      },
    );
  }
}