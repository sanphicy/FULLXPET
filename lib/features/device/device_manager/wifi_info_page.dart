import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';

class WifiInfoPage extends StatelessWidget {
  const WifiInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveDeviceProvider>();
    final device = provider.currentDevice;

    if (device == null) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: const Color(0xFFF6F6F6)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          'Wi-Fi Info',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.wifi, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text(
                provider.isNetworkGood ? 'The device network is good' : 'Network unstable',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),
              _buildInfoRow('WLAN Name', device.wifiSsid),
              _buildInfoRow('WLAN Strength', device.wifiRssi),
              _buildInfoRow('IP Address', device.wifiIp),
              _buildInfoRow('MAC Address', device.wifiMac),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFFDBAB3F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: provider.isLoading ? null : () => provider.resetWifi(),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Reset Wi-Fi',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          Text(value, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}
