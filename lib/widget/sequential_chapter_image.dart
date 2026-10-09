import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SequentialChapterImage extends StatefulWidget {
  final String imageUrl;

  const SequentialChapterImage({
    super.key,
    required this.imageUrl,
  });

  @override
  State<SequentialChapterImage> createState() =>
      _SequentialChapterImageState();
}

class _SequentialChapterImageState extends State<SequentialChapterImage> {
  bool _shouldLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Chỉ bắt đầu tải khi widget gần vùng nhìn thấy.
    if (!_shouldLoad) {
      final renderObject = context.findRenderObject();

      if (renderObject is RenderBox && renderObject.hasSize) {
        _shouldLoad = true;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_shouldLoad) {
          setState(() => _shouldLoad = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldLoad) {
      return const SizedBox(
        width: double.infinity,
        height: 220,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: double.infinity,
      fit: BoxFit.fitWidth,
      placeholder: (context, url) => const SizedBox(
        width: double.infinity,
        height: 220,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => const SizedBox(
        width: double.infinity,
        height: 120,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 36,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}