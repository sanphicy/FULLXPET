import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';
import 'package:go_router/go_router.dart';

class TimerModePage extends StatelessWidget {
  const TimerModePage({super.key});

  // 改为单次时间选择器
  Future<void> _showSingleTimePicker(BuildContext context, ActiveDeviceProvider provider) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select Execution Time',
    );

    if (time == null || !context.mounted) return;

    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    provider.addTimer(timeStr);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveDeviceProvider>();
    const Color primaryColor = Color(0xFF917CEE); // 替换为紫色

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC), // 替换为白净背景
      appBar: AppBar(
        title: const Text(
          'Timer List',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF9F9FC), // 替换为白净背景
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () async {
              // 调用提供者中的批量提交方法
              await provider.submitTimers();
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF917CEE), fontWeight: FontWeight.bold, fontSize: 16), // 替换为紫色
            ),
          ),
        ],
      ),
      body: provider.timerList.isEmpty
          ? const Center(
              child: Text('No timer record', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.timerList.length,
              itemBuilder: (context, index) {
                final String timerStr = provider.timerList[index];

                return Slidable(
                  key: ValueKey(timerStr),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        onPressed: (_) => provider.removeTimer(index),
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 直接显示单点时间
                        Text(timerStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Icon(Icons.timer_outlined, color: primaryColor),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSingleTimePicker(context, provider),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Timer', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
    );
  }
}
