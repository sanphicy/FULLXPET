import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final IconData defaultIcon;

  const AppAvatar({super.key, required this.avatarUrl, this.radius = 20, this.defaultIcon = Icons.person});

  @override
  Widget build(BuildContext context) {
    final bool hasValidUrl = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      child: hasValidUrl
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultIcon();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildDefaultIcon();
                },
              ),
            )
          : _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(defaultIcon, size: radius * 1.2, color: Colors.grey.shade500);
  }
}
