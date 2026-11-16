import 'package:flutter/material.dart';
import 'package:fullxpet/features/device/device_add/widgets/device_add_filter_sheet.dart';
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
  static const Color _primaryPurple = Color(0xFF917CEE);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceAddProvider>().startSearchDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final provider = context.watch<DeviceAddProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF666666)),
            onPressed: () => DeviceAddFilterSheet.show(context, provider),
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
              style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w900, color: const Color(0xFF333333)),
            ),
            SizedBox(height: Dimens.spacingMini),
            Text(
              s.autoSearching,
              style: TextStyle(fontSize: Dimens.fontMedium, color: _primaryPurple, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 60.h),
            Center(
              child: Icon(Icons.bluetooth_searching, size: 140.w, color: _primaryPurple.withValues(alpha: 0.15)),
            ),
            SizedBox(height: 40.h),
            Center(
              child: Text(
                s.noDeviceFoundDesc,
                textAlign: TextAlign.center,
                style: TextStyle(color: _primaryPurple.withValues(alpha: 0.5), fontSize: Dimens.fontSmall, height: 1.5),
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
                    child: const CircularProgressIndicator(strokeWidth: 2, color: _primaryPurple),
                  )
                else
                  GestureDetector(
                    onTap: () => provider.startSearchDevices(),
                    child: Icon(Icons.refresh, size: 18.w, color: _primaryPurple),
                  ),
              ],
            ),
            SizedBox(height: Dimens.spacingNormal),
            Expanded(
              child: provider.discoveredDevices.isEmpty && !provider.isScanning
                  ? Center(
                      child: TextButton(
                        onPressed: () => provider.startSearchDevices(),
                        child: const Text("重新搜索", style: TextStyle(color: _primaryPurple)),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: provider.discoveredDevices.length,
                      separatorBuilder: (_, __) => SizedBox(height: Dimens.spacingNormal),
                      itemBuilder: (context, index) {
                        return _buildDeviceCard(context, s, provider, provider.discoveredDevices[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 三级设备图标构建：1.产品列表网络图片 -> 2.本地写死映射内置图 -> 3.默认内置图标
  Widget _buildDeviceIcon(DiscoveredDevice device) {
    Widget buildFallback() {
      if (device.fallbackAsset.isNotEmpty) {
        return Image.asset(
          device.fallbackAsset,
          width: 28.w,
          height: 28.w,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.devices_other, color: _primaryPurple, size: Dimens.iconNormal),
        );
      }
      return Icon(Icons.devices_other, color: _primaryPurple, size: Dimens.iconNormal);
    }

    final netUrl = device.iconUrl;
    return Container(
      width: 44.w,
      height: 44.w,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(color: _primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: (netUrl != null && netUrl.isNotEmpty)
          ? Image.network(netUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => buildFallback())
          : buildFallback(),
    );
  }

  Widget _buildDeviceCard(BuildContext context, S s, DeviceAddProvider provider, DiscoveredDevice device) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Dimens.spacingNormal, vertical: Dimens.spacingSmall),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimens.radiusNormal),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _buildDeviceIcon(device),
          SizedBox(width: Dimens.spacingNormal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Dimens.fontSmall,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (device.rssi != 0) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.network_cell, size: 12.w, color: _primaryPurple),
                      SizedBox(width: 4.w),
                      Text(
                        "${device.rssi} dBm",
                        style: TextStyle(fontSize: 11.sp, color: const Color(0xFF888888)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9F9FC),
              foregroundColor: _primaryPurple,
              elevation: 0,
              minimumSize: Size(80.w, 36.h),
              padding: EdgeInsets.symmetric(horizontal: Dimens.spacingNormal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusMax)),
            ),
            onPressed: () {
              context.push(AppRoutes.deviceAddWifi, extra: {'device': device, 'provider': provider});
            },
            child: const Text("连接"),
          ),
        ],
      ),
    );
  }
}
