class CountryDto {
  final String countryCode;
  final String name;
  final String phoneCountryCode;
  final String defaultDataRegion;
  final String defaultDataCenter;

  CountryDto({
    required this.countryCode,
    required this.name,
    required this.phoneCountryCode,
    required this.defaultDataRegion,
    required this.defaultDataCenter,
  });

  factory CountryDto.fromJson(Map<String, dynamic> json) {
    return CountryDto(
      countryCode: json['countryCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneCountryCode: json['phoneCountryCode']?.toString() ?? '',
      defaultDataRegion: json['defaultDataRegion']?.toString() ?? '',
      defaultDataCenter: json['defaultDataCenter']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'name': name,
      'phoneCountryCode': phoneCountryCode,
      'defaultDataRegion': defaultDataRegion,
      'defaultDataCenter': defaultDataCenter,
    };
  }
}
