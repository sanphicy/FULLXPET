import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';

class AppWheelPickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final int initialIndex;
  final ValueChanged<int> onConfirm;

  const AppWheelPickerSheet({
    super.key,
    required this.title,
    required this.items,
    required this.initialIndex,
    required this.onConfirm,
  });

  /// 静态弹出方法：保持原本贴底的 BottomSheet
  static void show(
    BuildContext context, {
    required String title,
    required List<String> items,
    required int initialIndex,
    required ValueChanged<int> onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF6F6F6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.0))),
      builder: (ctx) =>
          AppWheelPickerSheet(title: title, items: items, initialIndex: initialIndex, onConfirm: onConfirm),
    );
  }

  @override
  State<AppWheelPickerSheet> createState() => _AppWheelPickerSheetState();
}

class _AppWheelPickerSheetState extends State<AppWheelPickerSheet> {
  late FixedExtentScrollController _scrollController;
  late int _selectedIndex;

  // 统一的品牌紫色
  static const Color _primaryPurple = Color(0xFF917CEE);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _scrollController = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return SafeArea(
      child: SizedBox(
        height: 330.0,
        child: Column(
          children: [
            // 1. 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // 2. 滚轮区域
            Expanded(
              child: CupertinoPicker(
                scrollController: _scrollController,
                itemExtent: 45.0,
                onSelectedItemChanged: (int index) {
                  _selectedIndex = index;
                },
                children: widget.items.map((item) {
                  return Center(
                    child: Text(item, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  );
                }).toList(),
              ),
            ),

            // 3. 底部操作按钮栏
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 30.0, bottom: 20.0, top: 10.0),
              child: Row(
                children: [
                  // 取消按钮
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.cancel, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // 确认按钮（替换为统一紫色）
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _primaryPurple,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        widget.onConfirm(_selectedIndex);
                        Navigator.pop(context);
                      },
                      child: Text(
                        s.confirm,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
