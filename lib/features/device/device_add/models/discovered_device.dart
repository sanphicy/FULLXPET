import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fullxpet/features/device/models/product_dto.dart';
import 'package:fullxpet/features/device/constants/product_constants.dart';

/// 由扫描列表决定的配网方式枚举
enum ProvisionMode {
  junvine, // 有短ID：骏云配网方式 ([总包,包序]分包 + stage 0 触发绑定)
  hooget, // 无短ID：原版配网方式 (0x86分包 + stage 2 回调提取 mac/pid 绑定)
}

/// Hooget 原版三款产品：固定蓝牙名称 -> 产品ID 与 本地保底图标映射
class HoogetProductCatalog {
  /// 写死的三款自研产品名称与产品ID映射表（无保底）
  static const Map<String, String> nameToProductId = {
    'FULLXPet-V3': ProductConstants.pidLitterBoxV3,
    'FULLXPet-V4': ProductConstants.pidLitterBoxV4,
    'FULLXPetFeed': ProductConstants.pidFeeder,
  };

  /// 无短ID时，根据广播设备名称从写死的字典拿 productId（未命中返回空字符串，不做保底）
  static String matchProductIdByName(String deviceName) {
    final upper = deviceName.trim().toUpperCase();
    for (final entry in nameToProductId.entries) {
      if (upper.contains(entry.key.toUpperCase())) {
        return entry.value;
      }
    }
    return '';
  }

  /// 本地内置保底图标（仅用于列表 UI 在查不到网络图或网卡时兜底显示）
  static String resolveFallbackAsset(String deviceName, String pid) {
    final upper = deviceName.trim().toUpperCase();
    if (pid == ProductConstants.pidFeeder || upper.contains('FULLXPETFEED') || upper.contains('FEED')) {
      return 'assets/images/product-feeder.png';
    }
    if (pid == ProductConstants.pidLitterBoxV4 || upper.contains('FULLXPET-V4') || upper.contains('V4')) {
      return 'assets/images/product-v4.png';
    }
    if (upper.contains('FULLXPET-V3') ||
        upper.contains('V3') ||
        upper.contains('PETLUX') ||
        upper.contains('FULLXPET')) {
      return 'assets/images/product-pic.png';
    }
    return '';
  }
}

/// 蓝牙设备模型
class DiscoveredDevice {
  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice? device;
  final String mac; // 广播解析出的 MAC 地址
  final String shortPid; // 广播解析出的 2字节短ID (如 2c1d)
  final String pid; // 匹配到的完整 productId（无保底）
  final String? iconUrl; // 从产品列表 API 查到的 thumbnailUrl
  final String fallbackAsset; // 本地保底内置图标
  final ProvisionMode provisionMode; // 列表决定的配网方式 (junvine / hooget)

  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.device,
    this.mac = '',
    this.shortPid = '',
    this.pid = '',
    this.iconUrl,
    this.fallbackAsset = '',
    this.provisionMode = ProvisionMode.junvine,
  });

  bool get hasShortPid => shortPid.isNotEmpty;

  /// 当产品列表 API 返回后，回填完整 PID 与网络图片地址
  DiscoveredDevice applyProductInfo(ProductDto? product) {
    if (product == null) return this;
    final resolvedPid = product.productId.isNotEmpty ? product.productId : pid;
    return DiscoveredDevice(
      id: id,
      name: name,
      rssi: rssi,
      device: device,
      mac: mac,
      shortPid: shortPid,
      pid: resolvedPid,
      iconUrl: product.thumbnailUrl.isNotEmpty ? product.thumbnailUrl : iconUrl,
      fallbackAsset: fallbackAsset.isNotEmpty
          ? fallbackAsset
          : HoogetProductCatalog.resolveFallbackAsset(name, resolvedPid),
      provisionMode: provisionMode,
    );
  }
}
