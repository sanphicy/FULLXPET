import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/common/constants/dimens.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/features/device/device_add/device_add_provider.dart';
import '../models/discovered_device.dart';

class DeviceAddSearchPage extends StatefulWidget {
  const DeviceAddSearchPage({super.key});

  @override
  State<DeviceAddSearchPage> createState() => _DeviceAddSearchPageState();
}

class _DeviceAddSearchPageState extends State<DeviceAddSearchPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceAddProvider>().startSearchDevices();
    });
  }

  // 呼出配置面板的方法
  void _showSettingsBottomSheet(BuildContext context, DeviceAddProvider provider) {
    bool filterUnknown = provider.filterUnknown;
    bool autoFetchWifi = provider.autoFetchWifi;
    TextEditingController nameCtrl = TextEditingController(text: provider.filterName);

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
                    activeColor: Theme.of(context).colorScheme.primary,
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
                    activeColor: Theme.of(context).colorScheme.primary,
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
                      hintText: "输入要包含的设备名称 (留空则不过滤)",
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;
    final provider = context.watch<DeviceAddProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            // 将原有的 Help 图标替换为 Settings 设置图标
            icon: Icon(Icons.settings, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () => _showSettingsBottomSheet(context, provider),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimens.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.searchingLabel,
              style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
            ),
            SizedBox(height: Dimens.spacingMini),
            Text(
              s.autoSearching,
              style: TextStyle(
                fontSize: Dimens.fontMedium,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 60.h),
            Center(
              child: Icon(
                Icons.bluetooth_searching,
                size: 140.w,
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            SizedBox(height: 40.h),
            Center(
              child: Text(
                s.noDeviceFoundDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  fontSize: Dimens.fontSmall,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 60.h),
            Row(
              children: [
                Text(
                  s.searchingAvailable,
                  style: TextStyle(fontSize: Dimens.fontMedium, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: Dimens.spacingSmall),
                if (provider.isScanning)
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                  )
                else
                  GestureDetector(
                    onTap: () => provider.startSearchDevices(),
                    child: Icon(Icons.refresh, size: 18.w, color: theme.colorScheme.primary),
                  ),
              ],
            ),
            SizedBox(height: Dimens.spacingNormal),
            Expanded(
              child: provider.discoveredDevices.isEmpty && !provider.isScanning
                  ? Center(
                      child: TextButton(
                        onPressed: () => provider.startSearchDevices(),
                        child: Text("重新搜索", style: TextStyle(color: theme.colorScheme.primary)),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: provider.discoveredDevices.length,
                      separatorBuilder: (_, __) => SizedBox(height: Dimens.spacingNormal),
                      itemBuilder: (context, index) {
                        return _buildDeviceCard(context, theme, s, provider, provider.discoveredDevices[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    ThemeData theme,
    S s,
    DeviceAddProvider provider,
    DiscoveredDevice device,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Dimens.spacingNormal, vertical: Dimens.spacingSmall),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusNormal),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Dimens.spacingSmall),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.devices_other, color: theme.colorScheme.primary, size: Dimens.iconNormal),
          ),
          SizedBox(width: Dimens.spacingNormal),
          Expanded(
            child: Text(
              device.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: Dimens.fontMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
              minimumSize: Size(80.w, 36.h),
              padding: EdgeInsets.symmetric(horizontal: Dimens.spacingNormal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusMax)),
            ),
            onPressed: () {
              context.push(AppRoutes.deviceAddWifi, extra: {'device': device, 'provider': provider});
            },
            child: Text(s.connectBtn),
          ),
        ],
      ),
    );
  }
}
