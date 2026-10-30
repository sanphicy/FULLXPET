import 'package:fullxpet/core/utils/json_parse_ext.dart';

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

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final rawGuide = json.getStr('pairingGuideUrl');
    return ProductDto(
      productId: json.getStr('productId'),
      productShortId: json.getStr('productShortId'),
      name: json.getStr('name'),
      brand: json.getStr('brand'),
      modelCode: json.getStr('modelCode'),
      connectivity: json.getStr('connectivity'),
      transportProtocol: json.getStr('transportProtocol'),
      thumbnailUrl: json.getStr('thumbnailUrl'),
      categoryCode: json.getStr('categoryCode'),
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
