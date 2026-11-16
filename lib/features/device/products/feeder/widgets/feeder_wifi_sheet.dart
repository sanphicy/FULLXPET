import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/feeder_viewmodel.dart';

class FeederWifiSheet {
  static const Color _textColor = Color(0xFF333333);
  static const Color _subTextColor = Color(0xFF888888);

  static void show(BuildContext context, FeederViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return ChangeNotifierProvider.value(
          value: vm,
          child: Consumer<FeederViewModel>(
            builder: (context, model, _) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '网络参数与重置',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Wi-Fi 名称', model.wifiSsid.isNotEmpty ? model.wifiSsid : '-'),
                      _buildInfoRow('信号强度', model.wifiRssi),
                      _buildInfoRow('网络信道', model.wifiChannel),
                      _buildInfoRow('硬件地址', model.hardwareAddress),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 18),
                          label: const Text(
                            '重置设备网络 (DP 1)',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final ok = await model.resetWifi();
                            if (context.mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(ok ? '已发送重置网络指令' : '重置网络指令发送失败')));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _subTextColor)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textColor),
          ),
        ],
      ),
    );
  }
}
