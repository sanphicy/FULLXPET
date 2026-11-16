import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/device/products/litter_box/viewmodels/litter_box_viewmodel.dart';

class PlasmaScheduleSheet {
  static void show(BuildContext context, LitterBoxViewModel vm, S s) {
    final currentSched = vm.plasmaSchedule;
    bool isAlwaysOn = vm.isPlasmaAlwaysOn;
    bool isFineGrained = false;

    int initialRunTotal = isAlwaysOn ? 3600 : (currentSched['runTime'] ?? 3600);
    int initialOutTotal = isAlwaysOn ? 1800 : (currentSched['outTime'] ?? 1800);

    int runMinutes = initialRunTotal ~/ 60;
    int runSeconds = initialRunTotal % 60;
    int outMinutes = initialOutTotal ~/ 60;
    int outSeconds = initialOutTotal % 60;

    if (runSeconds > 0 ||
        outSeconds > 0 ||
        (runMinutes == 0 && initialRunTotal > 0) ||
        (outMinutes == 0 && initialOutTotal > 0)) {
      isFineGrained = true;
    }
    if (runSeconds == 0) runSeconds = 30;
    if (outSeconds == 0) outSeconds = 30;

    final normalRunMinList = List.generate(120, (i) => i + 1);
    final normalOutMinList = List.generate(360, (i) => i + 1);
    final fineRunMinList = List.generate(121, (i) => i);
    final fineOutMinList = List.generate(361, (i) => i);
    final secList = List.generate(59, (i) => i + 1);

    late FixedExtentScrollController runMinCtrl;
    late FixedExtentScrollController runSecCtrl;
    late FixedExtentScrollController outMinCtrl;
    late FixedExtentScrollController outSecCtrl;

    void initControllers(bool fine) {
      if (fine) {
        runMinCtrl = FixedExtentScrollController(initialItem: runMinutes.clamp(0, 120));
        outMinCtrl = FixedExtentScrollController(initialItem: outMinutes.clamp(0, 360));
      } else {
        runMinCtrl = FixedExtentScrollController(initialItem: (runMinutes - 1).clamp(0, 119));
        outMinCtrl = FixedExtentScrollController(initialItem: (outMinutes - 1).clamp(0, 359));
      }
      runSecCtrl = FixedExtentScrollController(initialItem: (runSeconds - 1).clamp(0, 58));
      outSecCtrl = FixedExtentScrollController(initialItem: (outSeconds - 1).clamp(0, 58));
    }

    initControllers(isFineGrained);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentRunMinList = isFineGrained ? fineRunMinList : normalRunMinList;
            final currentOutMinList = isFineGrained ? fineOutMinList : normalOutMinList;

            final currentRunTotalSec = isFineGrained ? (runMinutes * 60 + runSeconds) : (runMinutes * 60);
            final currentOutTotalSec = isFineGrained ? (outMinutes * 60 + outSeconds) : (outMinutes * 60);
            final bool isTooShort = !isAlwaysOn && (currentRunTotalSec < 30 || currentOutTotalSec < 30);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(s.cancel, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                        ),
                        const Text(
                          '等离子工作模式',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (isAlwaysOn) {
                              vm.setPlasmaSchedule(runSeconds: 0, outSeconds: 0);
                            } else {
                              vm.setPlasmaSchedule(runSeconds: currentRunTotalSec, outSeconds: currentOutTotalSec);
                            }
                          },
                          child: const Text(
                            '确定',
                            style: TextStyle(color: Color(0xFF917CEE), fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            value: true,
                            groupValue: isAlwaysOn,
                            activeColor: const Color(0xFF917CEE),
                            title: const Text('常开模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: const Text('开启后持续工作，直到手动关闭', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            onChanged: (_) => setSheetState(() => isAlwaysOn = true),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEFEFEF)),
                          RadioListTile<bool>(
                            value: false,
                            groupValue: isAlwaysOn,
                            activeColor: const Color(0xFF917CEE),
                            title: const Text('循环模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: const Text(
                              '运行指定时间后自动休眠，循环往复',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            onChanged: (_) => setSheetState(() => isAlwaysOn = false),
                          ),
                        ],
                      ),
                    ),
                    if (!isAlwaysOn) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '精细调节 (精确到秒)',
                            style: TextStyle(fontSize: 13, color: Color(0xFF666666), fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: isFineGrained,
                            activeColor: const Color(0xFF917CEE),
                            onChanged: (val) {
                              setSheetState(() {
                                isFineGrained = val;
                                if (!isFineGrained) {
                                  if (runMinutes == 0) runMinutes = 1;
                                  if (outMinutes == 0) outMinutes = 1;
                                }
                                initControllers(isFineGrained);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimePickerColumn(
                              title: '运行工作',
                              minuteCtrl: runMinCtrl,
                              secondCtrl: runSecCtrl,
                              minList: currentRunMinList,
                              secList: secList,
                              showSeconds: isFineGrained,
                              onMinChanged: (idx) => setSheetState(() => runMinutes = currentRunMinList[idx]),
                              onSecChanged: (idx) => setSheetState(() => runSeconds = secList[idx]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimePickerColumn(
                              title: '停歇休眠',
                              minuteCtrl: outMinCtrl,
                              secondCtrl: outSecCtrl,
                              minList: currentOutMinList,
                              secList: secList,
                              showSeconds: isFineGrained,
                              onMinChanged: (idx) => setSheetState(() => outMinutes = currentOutMinList[idx]),
                              onSecChanged: (idx) => setSheetState(() => outSeconds = secList[idx]),
                            ),
                          ),
                        ],
                      ),
                      if (isTooShort) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9DB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFE066)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE67700)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '单次启闭低于30秒可能会加速除臭模块损耗',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFD9480F), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildTimePickerColumn({
    required String title,
    required FixedExtentScrollController minuteCtrl,
    required FixedExtentScrollController secondCtrl,
    required List<int> minList,
    required List<int> secList,
    required bool showSeconds,
    required ValueChanged<int> onMinChanged,
    required ValueChanged<int> onSecChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF917CEE).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF917CEE).withValues(alpha: 0.25), width: 1),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: minuteCtrl,
                        itemExtent: 34,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: onMinChanged,
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: minList.length,
                          builder: (context, index) => Center(
                            child: Text(
                              '${minList[index]} 分',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (showSeconds)
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: secondCtrl,
                          itemExtent: 34,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: onSecChanged,
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: secList.length,
                            builder: (context, index) => Center(
                              child: Text(
                                '${secList[index]} 秒',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF917CEE),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
