import 'package:flutter/material.dart';
import '../viewmodels/feeder_viewmodel.dart';

class FeederTimerSheet {
  static const Color _primaryPurple = Color(0xFF917CEE);
  static const Color _textColor = Color(0xFF333333);
  static const Color _subTextColor = Color(0xFF888888);

  /// 单次定时出粮时间段排期弹窗
  static void show(BuildContext context, FeederViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final range = vm.singleTimerRange;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '定时出粮时间段',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor),
                        ),
                        if (range == null)
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: _primaryPurple, size: 26),
                            onPressed: () async {
                              await _pickAndSaveTime(context, vm, setSheetState);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (range == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Text('暂无定时计划，点击右上角图标添加', style: TextStyle(fontSize: 13, color: _subTextColor)),
                      )
                    else
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryPurple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.schedule_rounded, color: _primaryPurple, size: 20),
                        ),
                        title: Text(
                          '${range.start}  至  ${range.end}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('到达时间推出推杆，结束时自动收回', style: TextStyle(fontSize: 12, color: _subTextColor)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 22),
                              onPressed: () async {
                                await _pickAndSaveTime(context, vm, setSheetState);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                              onPressed: () async {
                                await vm.removeTimerRange();
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _pickAndSaveTime(BuildContext context, FeederViewModel vm, StateSetter setSheetState) async {
    final startPicked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: '选择出粮开始时间',
    );
    if (startPicked == null || !context.mounted) return;

    final endPicked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      helpText: '选择出粮闭合时间',
    );
    if (endPicked == null) return;

    final startStr = "${startPicked.hour.toString().padLeft(2, '0')}:${startPicked.minute.toString().padLeft(2, '0')}";
    final endStr = "${endPicked.hour.toString().padLeft(2, '0')}:${endPicked.minute.toString().padLeft(2, '0')}";

    await vm.setSingleTimerRange(startStr, endStr);
    setSheetState(() {});
  }
}
