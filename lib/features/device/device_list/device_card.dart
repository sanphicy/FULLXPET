import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class DeviceCard extends StatelessWidget {
  final String deviceName;
  final String deviceId;
  final bool isOnline;
  final String imageUrl;
  final VoidCallback? onTap;

  // 新增回调函数用于左右滑动的操作
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const DeviceCard({
    super.key,
    required this.deviceName,
    required this.deviceId,
    required this.isOnline,
    required this.imageUrl,
    this.onTap,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 状态颜色配置
    final Color onlineColor = const Color(0xFF8CC152); // 在线绿色
    final Color offlineColor = const Color(0xFFF39191); // 离线粉红

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(deviceId),
        // 右侧滑出的操作面板 (向左滑动时显示)
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.38, // 缩小侧滑总宽度，防止块体过宽
          children: [
            const SizedBox(width: 8),
            // 重命名按钮（紧凑卡片，防止文字换行）
            Expanded(
              child: GestureDetector(
                onTap: () => onRename?.call(),
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFEFF5E8), borderRadius: BorderRadius.circular(15)),
                  alignment: Alignment.center,
                  child: const Text(
                    '重命名',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 删除按钮
            Expanded(
              child: GestureDetector(
                onTap: () => onDelete?.call(),
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFEFF5E8), borderRadius: BorderRadius.circular(15)),
                  alignment: Alignment.center,
                  child: const Text(
                    '删除',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
        // 卡片主体
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF), // 卡片浅灰色背景
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧：设备名称、ID 与状态
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deviceId,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF888888)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 25),
                      Text(
                        isOnline ? '在线' : '离线',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isOnline ? onlineColor : offlineColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),
                // 右侧：设备图片
                Image.asset(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.devices, size: 80, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
