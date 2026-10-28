import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';

class WifiInfoPage extends StatelessWidget {
  const WifiInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final provider = context.read<ActiveDeviceProvider>();
    const Color primaryPurple = Color(0xFF917CEE);
    const Color textColor = Color(0xFF333333);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: AppBar(
        title: Text(
          s.wifiInfoTitle,
          style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF9F9FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 540,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.wifi_rounded, size: 72, color: primaryPurple),
                const SizedBox(height: 16),
                Selector<ActiveDeviceProvider, bool>(
                  selector: (_, vm) => vm.isNetworkGood,
                  builder: (context, isGood, _) {
                    return Text(
                      isGood ? s.networkGood : s.networkUnstable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    );
                  },
                ),
                const SizedBox(height: 36),

                // Wi-Fi 详细参数卡片（局部监听）
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Selector<ActiveDeviceProvider, (String, String, String, String)>(
                    selector: (_, vm) => (
                      vm.currentDevice?.wifiSsid ?? '',
                      vm.currentDevice?.wifiRssi ?? '',
                      vm.currentDevice?.wifiIp ?? '',
                      vm.currentDevice?.wifiMac ?? '',
                    ),
                    builder: (context, info, _) {
                      return Column(
                        children: [
                          _buildInfoRow(s.wlanName, info.$1.isNotEmpty ? info.$1 : '-'),
                          _buildInfoRow(s.wlanStrength, info.$2.isNotEmpty ? info.$2 : '-'),
                          _buildInfoRow(s.ipAddress, info.$3.isNotEmpty ? info.$3 : '-'),
                          _buildInfoRow(s.macAddress, info.$4.isNotEmpty ? info.$4 : '-', isLast: true),
                        ],
                      );
                    },
                  ),
                ),

                const Spacer(),

                // 重置 Wi-Fi 按钮（局部监听 Loading）
                Selector<ActiveDeviceProvider, bool>(
                  selector: (_, vm) => vm.isLoading,
                  builder: (context, isLoading, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                await provider.resetWifi();
                                if (context.mounted) {
                                  context.showAppToast(message: s.resetWifiSuccess, type: AppToastType.info);
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(s.resetWifi, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
