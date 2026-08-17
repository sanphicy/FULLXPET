import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../factory_debug_provider.dart';
import '../models/discovered_device.dart';
import 'factory_debug_ui_view.dart';
import 'factory_debug_json_view.dart';

class FactoryDebugPage extends StatelessWidget {
  final DiscoveredDevice targetDevice;
  const FactoryDebugPage({super.key, required this.targetDevice});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FactoryDebugProvider()..connectAndInitGatt(targetDevice),
      child: const _FactoryDebugView(),
    );
  }
}

class _FactoryDebugView extends StatefulWidget {
  const _FactoryDebugView();

  @override
  State<_FactoryDebugView> createState() => _FactoryDebugViewState();
}

enum DebugViewMode { uiMode, jsonMode }

class _FactoryDebugViewState extends State<_FactoryDebugView> {
  DebugViewMode _currentMode = DebugViewMode.uiMode;
  static const Color _primaryPurple = Color(0xFF917CEE);
  static const Color _bgColor = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FactoryDebugProvider>();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF212529), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          provider.connectedDevice != null ? provider.connectedDevice!.platformName : "设备连接中...",
          style: TextStyle(fontSize: 16.sp, color: const Color(0xFF212529), fontWeight: FontWeight.bold),
        ),
        actions: [
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: _primaryPurple, strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryPurple))
          : Column(
              children: [
                // 1. 白色简约控制顶栏
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
                  ),
                  child: Row(
                    children: [
                      // 模式切换（分段选择器）
                      SegmentedButton<DebugViewMode>(
                        segments: const [
                          ButtonSegment(
                            value: DebugViewMode.uiMode,
                            label: Text("UI 可视化"),
                            icon: Icon(Icons.grid_view_rounded, size: 14),
                          ),
                          ButtonSegment(
                            value: DebugViewMode.jsonMode,
                            label: Text("JSON 报文"),
                            icon: Icon(Icons.code_rounded, size: 14),
                          ),
                        ],
                        selected: {_currentMode},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _currentMode = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return _primaryPurple.withValues(alpha: 0.12);
                            }
                            return Colors.white;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return _primaryPurple;
                            }
                            return const Color(0xFF495057);
                          }),
                        ),
                      ),
                      const Spacer(),

                      // 状态点 & 控制按钮组（解决容器溢出）
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: provider.isPaused ? Colors.amber : const Color(0xFF2B8A3E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          InkWell(
                            onTap: () => provider.togglePause(),
                            borderRadius: BorderRadius.circular(6.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                              child: Text(
                                provider.isPaused ? "继续" : "暂停",
                                style: TextStyle(color: _primaryPurple, fontSize: 12.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          InkWell(
                            onTap: () => provider.clearLogs(),
                            borderRadius: BorderRadius.circular(6.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                              child: Text(
                                "清屏",
                                style: TextStyle(
                                  color: const Color(0xFF868E96),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. 视图组件体
                Expanded(
                  child: IndexedStack(
                    index: _currentMode == DebugViewMode.uiMode ? 0 : 1,
                    children: const [FactoryDebugUiView(), FactoryDebugJsonView()],
                  ),
                ),
              ],
            ),
    );
  }
}
