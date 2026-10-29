class ProductDto {
  final String productId;
  final String productShortId;
  final String name;
  final String brand;
  final String modelCode;
  final String connectivity;
  final String transportProtocol;
  final String thumbnailUrl;
  final String categoryCode;
  final String? pairingGuideUrl;

  const ProductDto({
    required this.productId,
    this.productShortId = '',
    required this.name,
    this.brand = '',
    this.modelCode = '',
    this.connectivity = '',
    this.transportProtocol = '',
    this.thumbnailUrl = '',
    this.categoryCode = '',
    this.pairingGuideUrl,
  });

  static String _str(Map<String, dynamic> json, String key) {
    return json[key]?.toString().trim() ?? '';
  }

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final rawGuide = _str(json, 'pairingGuideUrl');
    return ProductDto(
      productId: _str(json, 'productId'),
      productShortId: _str(json, 'productShortId'),
      name: _str(json, 'name'),
      brand: _str(json, 'brand'),
      modelCode: _str(json, 'modelCode'),
      connectivity: _str(json, 'connectivity'),
      transportProtocol: _str(json, 'transportProtocol'),
      thumbnailUrl: _str(json, 'thumbnailUrl'),
      categoryCode: _str(json, 'categoryCode'),
      pairingGuideUrl: rawGuide.isNotEmpty ? rawGuide : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productShortId': productShortId,
      'name': name,
      'brand': brand,
      'modelCode': modelCode,
      'connectivity': connectivity,
      'transportProtocol': transportProtocol,
      'thumbnailUrl': thumbnailUrl,
      'categoryCode': categoryCode,
      'pairingGuideUrl': pairingGuideUrl,
    };
  }
}
