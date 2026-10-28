import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../factory_debug_provider.dart';

class FactoryDebugJsonView extends StatefulWidget {
  const FactoryDebugJsonView({super.key});

  @override
  State<FactoryDebugJsonView> createState() => _FactoryDebugJsonViewState();
}

class _FactoryDebugJsonViewState extends State<FactoryDebugJsonView> {
  final TextEditingController _cmdCtrl = TextEditingController();
  bool _use0x86Format = true;
  static const Color _primaryPurple = Color(0xFF917CEE);

  @override
  void dispose() {
    _cmdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FactoryDebugProvider>();

    return Column(
      children: [
        // 日志明细列表
        Expanded(
          child: provider.logs.isEmpty
              ? Center(
                  child: Text(
                    "等待数据报文中...",
                    style: TextStyle(color: const Color(0xFF868E96), fontSize: 13.sp),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(14.w),
                  reverse: true,
                  itemCount: provider.logs.length,
                  itemBuilder: (context, index) {
                    return _buildLogCard(context, provider.logs[index]);
                  },
                ),
        ),

        // 底部发送指令卡片
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "发送 JSON 指令",
                    style: TextStyle(color: const Color(0xFF212529), fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        "透传",
                        style: TextStyle(
                          color: !_use0x86Format ? const Color(0xFF212529) : const Color(0xFF868E96),
                          fontSize: 12.sp,
                        ),
                      ),
                      Switch(
                        value: _use0x86Format,
                        activeColor: _primaryPurple,
                        onChanged: (val) => setState(() => _use0x86Format = val),
                      ),
                      Text(
                        "分包(0x86)",
                        style: TextStyle(
                          color: _use0x86Format ? const Color(0xFF212529) : const Color(0xFF868E96),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _cmdCtrl,
                maxLines: 2,
                style: TextStyle(color: const Color(0xFF212529), fontFamily: 'monospace', fontSize: 12.sp),
                decoration: InputDecoration(
                  hintText: '输入 JSON 指令...',
                  hintStyle: TextStyle(color: const Color(0xFFADB5BD), fontSize: 12.sp),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: _primaryPurple),
                  ),
                  contentPadding: EdgeInsets.all(10.w),
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                height: 42.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                  label: Text(
                    "发送指令 (${_use0x86Format ? '0x86协议' : '透传'})",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                  ),
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (_cmdCtrl.text.trim().isEmpty) return;
                    await provider.sendJsonCommand(_cmdCtrl.text.trim(), use0x86: _use0x86Format);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, FactoryDebugLog log) {
    final timeStr =
        "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}.${log.timestamp.millisecond}";
    final String formattedJson = log.parsedJson != null
        ? const JsonEncoder.withIndent('  ').convert(log.parsedJson)
        : log.rawText;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: log.isTx ? const Color(0xFFFFD8A8) : const Color(0xFFD0EBFF)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                log.isTx ? "[TX -> Write]" : "[RX <- Notify]",
                style: TextStyle(
                  color: log.isTx ? const Color(0xFFE8590C) : const Color(0xFF1971C2),
                  fontWeight: FontWeight.bold,
                  fontSize: 11.sp,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: TextStyle(color: const Color(0xFF868E96), fontSize: 10.sp),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: formattedJson));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("JSON 已复制到剪贴板"), duration: Duration(seconds: 1)));
                },
                child: const Icon(Icons.copy_rounded, color: Color(0xFF868E96), size: 14),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          SelectableText(
            formattedJson,
            style: TextStyle(color: const Color(0xFF343A40), fontFamily: 'monospace', fontSize: 11.sp, height: 1.3),
          ),
        ],
      ),
    );
  }
}
