import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../device_add_provider.dart';

class DeviceAddFilterSheet {
  static const Color _primaryPurple = Color(0xFF917CEE);

  static void show(BuildContext context, DeviceAddProvider provider) {
    bool filterUnknown = provider.filterUnknown;
    bool autoFetchWifi = provider.autoFetchWifi;
    final TextEditingController nameCtrl = TextEditingController(text: provider.filterName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20.w, right: 20.w, top: 20.h),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.r)),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "搜索与配网设置",
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15.h),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("过滤未知设备", style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text("隐藏没有名称的蓝牙设备", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: filterUnknown,
                    onChanged: (val) => setState(() => filterUnknown = val),
                    activeThumbColor: _primaryPurple,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("自动获取周围 Wi-Fi", style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text(
                      "关闭后不向设备下发扫描指令，配网时将自动读取手机当前连接的 Wi-Fi",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: autoFetchWifi,
                    onChanged: (val) => setState(() => autoFetchWifi = val),
                    activeThumbColor: _primaryPurple,
                  ),
                  SizedBox(height: 15.h),
                  Text(
                    "精确过滤",
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: "多个名称用逗号隔开，如: FULLXPET, junvine",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50.h),
                      backgroundColor: _primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: () {
                      provider.saveSettings(
                        filterUnknown: filterUnknown,
                        filterName: nameCtrl.text.trim(),
                        autoFetchWifi: autoFetchWifi,
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      "保存并重新搜索",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
