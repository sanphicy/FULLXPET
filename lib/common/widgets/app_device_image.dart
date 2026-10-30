import 'package:flutter/material.dart';

class AppDeviceImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const AppDeviceImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _DeviceImageSkeleton(width: width, height: height, borderRadius: borderRadius);
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      ),
    );
  }

  // 通用中性硬件占位图（不绑定任何具体产品形态）
  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(borderRadius)),
      alignment: Alignment.center,
      child: Icon(
        Icons.devices_other_rounded,
        size: (width < height ? width : height) * 0.45,
        color: const Color(0xFFB0B0C0),
      ),
    );
  }
}

// 轻量级呼吸骨架屏组件
class _DeviceImageSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _DeviceImageSkeleton({required this.width, required this.height, required this.borderRadius});

  @override
  State<_DeviceImageSkeleton> createState() => _DeviceImageSkeletonState();
}

class _DeviceImageSkeletonState extends State<_DeviceImageSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
