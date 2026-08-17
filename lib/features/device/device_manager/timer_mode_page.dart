import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';

class TimerModePage extends StatelessWidget {
  const TimerModePage({super.key});

  Future<void> _showSingleTimePicker(BuildContext context, ActiveDeviceProvider provider, S s) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: s.selectExecutionTime,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (time == null || !context.mounted) return;
    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    provider.addTimer(timeStr);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final provider = context.read<ActiveDeviceProvider>();
    const Color primaryColor = Color(0xFF917CEE);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: AppBar(
        title: Text(
          s.timerSchedule,
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF9F9FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await provider.submitTimers();
              if (context.mounted) {
                if (provider.hasError) {
                  context.showAppToast(message: s.saveTimersFailed, type: AppToastType.error);
                } else {
                  context.showAppToast(message: s.saveTimersSuccess, type: AppToastType.success);
                  context.pop();
                }
              }
            },
            child: Text(
              s.save,
              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: Selector<ActiveDeviceProvider, List<String>>(
            selector: (_, vm) => vm.timerList,
            builder: (context, timerList, _) {
              if (timerList.isEmpty) {
                return Center(
                  child: Text(s.noTimerRecord, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: timerList.length,
                itemBuilder: (context, index) {
                  final String timerStr = timerList[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Slidable(
                      key: ValueKey(timerStr),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (_) => provider.removeTimer(index),
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            icon: Icons.delete_outline,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timerStr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const Icon(Icons.timer_outlined, color: primaryColor),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSingleTimePicker(context, provider, s),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          s.addTimer,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
      ),
    );
  }
}
