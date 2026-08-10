import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../factory_debug_provider.dart';
import '../models/discovered_device.dart';

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

class _FactoryDebugViewState extends State<_FactoryDebugView> {
  final TextEditingController _cmdCtrl = TextEditingController(text: '{"cmd": "fac_ctrl", "action": "zero"}');

  static const Color _purple = Color(0xFF917CEE);

  @override
  void dispose() {
    _cmdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FactoryDebugProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252526),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(), // Pop 时 Provider 会自动 dispose 并释放 BLE
        ),
        title: Text(
          provider.connectedDevice != null ? provider.connectedDevice!.platformName : "正在连接设备...",
          style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: _purple, strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: Text("正在建立 GATT 连接并协商权限...", style: TextStyle(color: Colors.grey)),
            )
          : _buildConsoleBody(provider),
    );
  }

  Widget _buildConsoleBody(FactoryDebugProvider provider) {
    return Column(
      children: [
        // 顶栏控制按钮
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          color: const Color(0xFF252526),
          child: Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: provider.isPaused ? Colors.amber : Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                provider.isPaused ? "已暂停监听" : "持续监听 Notify 中...",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12.sp),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => provider.togglePause(),
                child: Text(provider.isPaused ? "继续" : "暂停", style: const TextStyle(color: _purple)),
              ),
              TextButton(
                onPressed: () => provider.clearLogs(),
                child: const Text("清空", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),

        // 实时 JSON 日志列表
        Expanded(
          child: provider.logs.isEmpty
              ? Center(
                  child: Text("等待设备推送数据...", style: TextStyle(color: Colors.grey.shade600)),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(12.w),
                  itemCount: provider.logs.length,
                  itemBuilder: (context, index) {
                    return _buildLogCard(provider.logs[index]);
                  },
                ),
        ),

        // 0xFA02 写入下发控制区
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: const BoxDecoration(
            color: Color(0xFF252526),
            border: Border(top: BorderSide(color: Color(0xFF333333))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "下发 JSON 控制指令 (Write):",
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _cmdCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.all(10.w),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                height: 40.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _purple),
                  icon: const Icon(Icons.send, size: 16, color: Colors.white),
                  label: const Text(
                    "发送指令 (Write)",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    await provider.sendJsonCommand(_cmdCtrl.text.trim());
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(FactoryDebugLog log) {
    final timeStr =
        "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}.${log.timestamp.millisecond}";
    final String formattedJson = log.parsedJson != null
        ? const JsonEncoder.withIndent('  ').convert(log.parsedJson)
        : log.rawText;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: log.isTx ? Colors.orangeAccent.withOpacity(0.5) : _purple.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                log.isTx ? "[TX -> Write]" : "[RX <- Notify]",
                style: TextStyle(
                  color: log.isTx ? Colors.orangeAccent : _purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.sp,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: TextStyle(color: Colors.grey, fontSize: 10.sp),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: formattedJson));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("JSON 已复制到剪贴板"), duration: Duration(seconds: 1)));
                },
                child: const Icon(Icons.copy, color: Colors.grey, size: 14),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          SelectableText(
            formattedJson,
            style: const TextStyle(color: Color(0xFF4EC9B0), fontFamily: 'monospace', fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }
}
