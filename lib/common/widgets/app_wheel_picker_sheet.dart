import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  /// 快捷呼出静态方法
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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // 自动滚动到当前选中的位置
    _scrollController = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 330.0, // 稍微调低整体高度
        child: Column(
          children: [
            // 1. 顶部标题区域
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // 2. 中间选择区域 (Expanded 自动占满剩余空间)
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

            // 3. 底部按钮区域
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 30.0, bottom: 20.0, top: 10.0), // 增加左右边距，让按钮看起来更紧凑
              child: Row(
                children: [
                  // 取消按钮 - 纯文字，无边框
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12), // 调小内边距
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 15)), // 调小字体
                    ),
                  ),
                  const SizedBox(width: 15),
                  // 确认按钮 - 填充色，无边框
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12), // 调小内边距
                        backgroundColor: const Color(0xFFDBAB3F),
                        elevation: 0, // 去除阴影，更扁平
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        widget.onConfirm(_selectedIndex);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), // 调小字体
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
