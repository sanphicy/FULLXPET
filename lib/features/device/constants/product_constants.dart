enum DeviceCategory { litterBox, feeder, unknown }

class ProductConstants {
  static const String pidLitterBoxV3 = 'f7k2m9xplq8n3v6w';
  static const String pidLitterBoxV4 = '1a731d3e68cca08b';
  static const String pidFeeder = '9c2608de680bf9b6';
  static const String junvineFeeder = '2a2aeb52999d2a16';

  /// 产品品类注册表
  static const Map<String, DeviceCategory> _categoryRegistry = {
    pidLitterBoxV3: DeviceCategory.litterBox,
    pidLitterBoxV4: DeviceCategory.litterBox,
    pidFeeder: DeviceCategory.feeder,
    junvineFeeder: DeviceCategory.feeder,
  };

  static DeviceCategory resolveCategory(String? productId) {
    if (productId == null || productId.isEmpty) return DeviceCategory.unknown;
    return _categoryRegistry[productId] ?? DeviceCategory.unknown;
  }

  static bool isLitterBox(String? productId) => resolveCategory(productId) == DeviceCategory.litterBox;

  static bool isFeeder(String? productId) => resolveCategory(productId) == DeviceCategory.feeder;
}
