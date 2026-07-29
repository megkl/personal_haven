import 'package:flutter/material.dart';

/// A circular network image that always falls back to local UI when loading
/// fails, including transient DNS and offline errors.
class NetworkAvatar extends StatelessWidget {
  const NetworkAvatar({
    super.key,
    required this.size,
    required this.fallback,
    this.imageUrl,
    this.backgroundColor = Colors.white,
    this.border,
  });

  final double size;
  final String? imageUrl;
  final Widget fallback;
  final Color backgroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final fallbackWidget = Center(child: fallback);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: border,
      ),
      child: url == null || url.isEmpty
          ? fallbackWidget
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallbackWidget,
            ),
    );
  }
}
