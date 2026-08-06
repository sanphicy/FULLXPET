import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/common/constants/dimens.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/password_text_field.dart';
import 'package:fullxpet/features/device/device_add/device_add_provider.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:fullxpet/features/device/device_add/models/discovered_device.dart';

class DeviceAddWifiPage extends StatefulWidget {
  final DiscoveredDevice targetDevice;
  const DeviceAddWifiPage({super.key, required this.targetDevice});

  @override
  State<DeviceAddWifiPage> createState() => _DeviceAddWifiPageState();
}

class _DeviceAddWifiPageState extends State<DeviceAddWifiPage> {
  late DeviceAddProvider _provider;
  final TextEditingController _ssidCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = context.read<DeviceAddProvider>();
    _provider.addListener(_onProviderStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _provider.prepareAndFetchWifi(widget.targetDevice);
      try {
        final info = NetworkInfo();
        String? wifiName = await info.getWifiName();
        if (wifiName != null && wifiName.isNotEmpty && wifiName != '<unknown ssid>') {
          _ssidCtrl.text = wifiName.replaceAll('"', '');
        }
      } catch (_) {}

      if (_ssidCtrl.text.isEmpty && _provider.deviceWifiList.isNotEmpty) {
        _ssidCtrl.text = _provider.deviceWifiList.first['ssid'] ?? '';
      }
    });
  }

  // 监听 Provider，如果配网走完且存下了设备 ID，则执行跳转
  void _onProviderStateChanged() {
    if (_provider.configStep == 4 && _provider.boundDeviceId != null) {
      _provider.removeListener(_onProviderStateChanged);
      // 跳转到外部独立的成功页面
      context.pushReplacement('/device-add-success/${_provider.boundDeviceId}');
    }
  }

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _pwdCtrl.dispose();
    _provider.removeListener(_onProviderStateChanged);
    if (_provider.configStep != 4) {
      _provider.resetStateForRescan();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;
    final provider = context.watch<DeviceAddProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("网络配置"), elevation: 0),
      body: _buildMainView(theme, s, provider),
    );
  }

  Widget _buildMainView(ThemeData theme, S s, DeviceAddProvider provider) {
    final stepTexts = ["正在准备设备通道", s.configStep1, s.configStep2, s.configStep3];
    String currentText = provider.configStep <= 3 ? stepTexts[provider.configStep] : s.configProgress;

    if (provider.hasError) {
      currentText = provider.errorMsg.isNotEmpty ? provider.errorMsg : "配置发生异常";
    }

    return Column(
      children: [
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.phone_iphone, size: 40.w, color: theme.colorScheme.primary),
                  _AnimatedDots(isWorking: !provider.hasError && provider.configStep < 4, theme: theme),
                  Icon(Icons.router, size: 40.w, color: theme.colorScheme.primary),
                ],
              ),
              SizedBox(height: Dimens.spacingLarge),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: provider.progress,
                  minHeight: 6.h,
                  backgroundColor: const Color(0xFFEEEEEE),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    provider.hasError ? Colors.redAccent : theme.colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: Dimens.spacingSmall),
              Text(
                currentText,
                style: TextStyle(
                  fontSize: Dimens.fontMedium,
                  fontWeight: FontWeight.bold,
                  color: provider.hasError ? Colors.redAccent : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          child: (provider.configStep == 0 && provider.isReadyForWifi)
              ? Padding(
                  padding: EdgeInsets.fromLTRB(Dimens.pagePadding, 30.h, Dimens.pagePadding, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.wifiConfigDesc,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: Dimens.fontSmall),
                      ),
                      SizedBox(height: Dimens.spacingNormal),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(Dimens.radiusLarge),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _ssidCtrl,
                                decoration: const InputDecoration(
                                  hintText: "Wi-Fi 名称 (SSID)",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (provider.deviceWifiList.isNotEmpty)
                              PopupMenuButton<String>(
                                icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                                onSelected: (String value) {
                                  setState(() {
                                    _ssidCtrl.text = value;
                                  });
                                },
                                itemBuilder: (BuildContext context) {
                                  return provider.deviceWifiList.map((wifi) {
                                    return PopupMenuItem<String>(
                                      value: wifi['ssid'],
                                      child: Text(wifi['ssid'] ?? 'Unknown'),
                                    );
                                  }).toList();
                                },
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: Dimens.spacingNormal),
                      PasswordTextField(
                        controller: _pwdCtrl,
                        themeColor: theme.colorScheme.primary,
                        hintText: s.wifiPasswordHint,
                      ),
                      SizedBox(height: Dimens.spacingLarge),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, Dimens.buttonLarge),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          final targetSsid = _ssidCtrl.text.trim();
                          final pwd = _pwdCtrl.text.trim();
                          if (targetSsid.isEmpty || pwd.isEmpty) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('请填写完整的 Wi-Fi 信息')));
                            return;
                          }
                          FocusManager.instance.primaryFocus?.unfocus();
                          provider.startWifiProvisioning(targetSsid, pwd, widget.targetDevice);
                        },
                        child: Text(
                          provider.hasError ? "重新配置" : s.startConfig,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        Expanded(
          child: Container(
            margin: EdgeInsets.all(Dimens.pagePadding),
            padding: EdgeInsets.all(Dimens.spacingNormal),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: provider.provisionLogs.length,
              itemBuilder: (context, index) {
                final log = provider.provisionLogs[index];
                final isHighlight = log.contains('🟢');
                final isError = log.contains('❌');

                Color textColor = Colors.grey.shade400;
                if (isHighlight) textColor = theme.colorScheme.primary;
                if (isError) textColor = Colors.redAccent;

                return Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Text(
                    log.replaceAll('🟢 ', '').replaceAll('❌ ', ''),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: textColor,
                      fontWeight: (isHighlight || isError) ? FontWeight.bold : FontWeight.normal,
                    ),
                    softWrap: true,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  final bool isWorking;
  final ThemeData theme;
  const _AnimatedDots({required this.isWorking, required this.theme});

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> {
  Timer? _timer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(_AnimatedDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWorking && !oldWidget.isWorking) {
      _startAnimation();
    } else if (!widget.isWorking && oldWidget.isWorking) {
      _timer?.cancel();
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    if (!widget.isWorking) return;
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _activeIndex = (_activeIndex + 1) % 3;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = widget.isWorking && index == _activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: 8.w,
          height: 8.w,
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()..scale(isActive ? 1.4 : 1.0),
          decoration: BoxDecoration(
            color: isActive ? widget.theme.colorScheme.primary : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
