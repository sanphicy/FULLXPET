import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';

class TimerModePage extends StatefulWidget {
  const TimerModePage({super.key});

  @override
  State<TimerModePage> createState() => _TimerModePageState();
}

class _TimerModePageState extends State<TimerModePage> {
  static const Color _primaryColor = Color(0xFF917CEE);

  late List<String> _draftTimers;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _draftTimers = List<String>.from(context.read<LitterBoxViewModel>().timerList);
  }

  Future<void> _showSingleTimePicker(S s) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: s.selectExecutionTime,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (time == null || !mounted) return;

    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    if (_draftTimers.contains(timeStr)) {
      context.showAppToast(message: '该定时时间已存在', type: AppToastType.info);
      return;
    }

    setState(() {
      _draftTimers
        ..add(timeStr)
        ..sort();
    });
  }

  void _removeDraftTimer(int index) {
    if (index < 0 || index >= _draftTimers.length) return;
    setState(() {
      _draftTimers.removeAt(index);
    });
  }

  Future<void> _handleSave(S s) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final vm = context.read<LitterBoxViewModel>();
    final ok = await vm.submitTimers(_draftTimers);
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (ok) {
      context.showAppToast(message: s.saveTimersSuccess, type: AppToastType.success);
      context.pop();
    } else {
      final msg = vm.errorMsg.isNotEmpty ? vm.errorMsg : s.saveTimersFailed;
      context.showAppToast(message: msg, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

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
            onPressed: _isSubmitting ? null : () => _handleSave(s),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                  )
                : Text(
                    s.save,
                    style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: _draftTimers.isEmpty
              ? Center(
                  child: Text(s.noTimerRecord, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _draftTimers.length,
                  itemBuilder: (context, index) {
                    final String timerStr = _draftTimers[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Slidable(
                        key: ValueKey(timerStr),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (_) => _removeDraftTimer(index),
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
                              const Icon(Icons.timer_outlined, color: _primaryColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : () => _showSingleTimePicker(s),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          s.addTimer,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
      ),
    );
  }
}
